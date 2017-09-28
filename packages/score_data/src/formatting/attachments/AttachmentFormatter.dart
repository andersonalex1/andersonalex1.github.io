part of score_data.formatting;

class AttachmentFormatter {
	Score _score;

	AttachmentFormatter (Score score) {
		_score = score;
	}
	
	/**
	 * formats the measure attachments (and eventually note attachments)
	 * @param system the System to process
	 */
	void formatAttachments(System system) {
		_formatMeasureAttachments(system);

		_formatNoteAttachments(system);
	}

	/**
	 * formats slurs (and eventually hairpins or other lines drawn on the systems
	 */
	void formatLines() {

		//clear the old slur segments
		var systems = _score.getSystems();
		for (var system in systems){
			system.slurSegments = [];
		}
		
		

		//find the start points of slurs and create segments for them

		//int stackIndex = 0;
		int measuresPerStack = systems[0].measureStacks[0].measures.length;
		for (var system in systems){
			//we only need to set the repeat ending height once per system - 
			//new system, so we haven't found any yet.
			bool repeatEndingHeightSet = false;
			
			//distance from top staff line of one staff to top staff line of next staff
			num staffSpacing = (system.staffLineSpacing * 4) + system.staffSpacing; 
			List<num> staffVPosOffsets = system.staffVPosOffsets;

			var stacks = system.measureStacks;
			int numStacks = stacks.length;
			for (int i = 0; i < numStacks; i++){
				var stack = stacks[i];

				num vStaffPos = 0; //current staff's vertical position (top line of staff)

				var measures = stack.measures;
				for (int j = 0; j < measuresPerStack; j++){
					var measure = measures[j];
					var voices = measure.voices;
					for (var voice in voices){
						var noteGroups = voice.noteGroups;
						int numNoteGroups = noteGroups.length;
						for (int k = 0; k < numNoteGroups; k++){
							var ng = noteGroups[k];
							if (ng.slurs != null){
								var slurs = ng.slurs;
								for (int x = slurs.length - 1; x >= 0; x--){
									var slur = slurs[x];
									if (slur.firstNote == ng){
										if (slur.endNote == null || voice.number != slur.endNote.voice.number ||
												ng.voice.measure.staff != slur.endNote.voice.measure.staff ||
												ng.isRest || slur.endNote.isRest || ng == slur.endNote){
											//if this slur spans more than one staff or voice, or is attached to a 
											//rest, or is attached to only one note, delete it. We don't support this.
											//ng.slurs.removeAt(ng.slurs.indexOf(slur));
											ng.slurs.removeAt(x);
											if (slur.endNote != null){
												slur.endNote.slurs.removeAt(slur.endNote.slurs.indexOf(slur));
											}
										}
										else {
											_buildSlurSegments(slur, k, vStaffPos + staffVPosOffsets[j]);
										}
									}
								}
							}
							if (ng.tuplets != null){
								int tupletIndex = 0;
								for (var tuplet in ng.tuplets){
									if (tuplet.firstNote == ng){
										//for nested tuplets, the level param will determine an 
										//additional vertical offset
										_formatTuplet(ng, tuplet, ng.tuplets.length - 1 - tupletIndex);
									}
									tupletIndex++;
								}
							}
						}
					}

					vStaffPos += staffSpacing;
				}
				
				if (!repeatEndingHeightSet && stack.repeatDOs != null){
					for (var rdo in stack.repeatDOs){
						if (rdo.endingType != null){
							_setRepeatEndingHeight(stacks, i);
							repeatEndingHeightSet = true;
						}
					}
				}
			}
		}

	}
	
	void _formatMeasureAttachments(System system) {
		var stacks = system.measureStacks;

		num space = _score.scoreProperties.staffLineSpacing;
		num defaultAbovePos = -1 * space;
		num defaultBelowPos = 5 * space;

		for (var stack in stacks){
			//num vStaffPos = 0; //current staff's vertical position (top line of staff)

			var measures = stack.measures;
			int numMeasures = measures.length;
			for (int i = 0; i < numMeasures; i++){
				//process measure attachments
				if (measures[i].attachments != null){

					var measure = measures[i];
					List<MeasureAttachment> attachments = measure.attachments;

					//get the width of the portion of the measure that notes occupy (markings 
					//are restricted to the same space)
					num stackWidth = (stack.newSystem)
									? stack.width - stack.indentAsSystemLeader 
									: stack.width - stack.indent;

					for (var attachment in attachments){
						//get the relative horizontal and vertical positions of the marking
						num hPos;
						num vPos;
						var voices = measure.voices;
						if (measure.voices.length > 0){
							num attachmentTime = attachment.qNoteTime;
							//find the closest preceding and following notegroups - also 
							//look for any exact matches
							NoteGroup closestPrevNG = null;
							NoteGroup closestNextNG = null;
							NoteGroup matchingNG = null;
							for (var voice in voices){
								var noteGroups = voice.noteGroups;
								int numNoteGroups = noteGroups.length;
								for (int j = 0; j < numNoteGroups; j++){
									num ngTime = noteGroups[j].qNoteTime;
									if (ngTime < attachmentTime){
										if (closestPrevNG == null || closestPrevNG.qNoteTime < ngTime){
											closestPrevNG = noteGroups[j];
										}
									}
									else if (ngTime == attachmentTime){
										matchingNG = noteGroups[j];
										//the only thing that could beat this is another note in 
										//another voice with the same time
										break; 
									}
									else {
										if (closestNextNG == null || closestNextNG.qNoteTime > ngTime){
											closestNextNG = noteGroups[j];
											//once we've found a note that comes after the marking, 
											//we won't find any closer in the same voice
											break; 
										}
									}
								}
							}

							NoteGroup collisionNG = null; //the notegroup to check against for collision avoidance
							if (matchingNG != null){
								hPos = matchingNG.hPos;
								collisionNG = matchingNG;
							}
							else if (closestNextNG != null && closestPrevNG != null){
								num posRatio = (attachmentTime - closestPrevNG.qNoteTime) / 
												(closestNextNG.qNoteTime - closestPrevNG.qNoteTime);
								hPos = (posRatio * (closestNextNG.hPos - closestPrevNG.hPos)) + 
										closestPrevNG.hPos;
								collisionNG = (hPos - closestPrevNG.hPos < closestNextNG.hPos - hPos)
										? closestPrevNG 
										: closestNextNG;
							}
							else if (closestPrevNG != null){
								num posRatio = (attachmentTime - closestPrevNG.qNoteTime) / 
												(stack.endTime - closestPrevNG.qNoteTime);
								hPos = (posRatio * ((stack.startPosition + stack.width) - 
								                    closestPrevNG.hPos)) + closestPrevNG.hPos;
								collisionNG = closestPrevNG;
							}
							else if (closestNextNG != null){
								num posRatio = (attachmentTime - stack.startTime) / 
											(closestNextNG.qNoteTime - stack.startTime);
								hPos = posRatio * (closestNextNG.hPos);
								collisionNG = closestNextNG;
							}
							else { 
								//if the measure had no notes, we have to just use default 
								//positioning - shouldn't usually happen
								hPos = ((attachment.qNoteTime - stack.startTime) / 
										(stack.dpqLength)) * stackWidth;
							}

							if (collisionNG != null && !collisionNG.isRest){
								var notes = collisionNG.visibleNotes;
								if (attachment.isAbove){
									num min = (collisionNG.stemDirection == StemDirection.UP)
											? collisionNG.stemEndPos
											: notes.last.vPos;
											//: collisionNG.notes[collisionNG.notes.length - 1].vPos;
									vPos = (min < defaultAbovePos + attachment.height + 1.5 * space)
											? min - 1.5 * space - attachment.height 
											: defaultAbovePos - attachment.height;
								}
								else {
									num max = (collisionNG.stemDirection == StemDirection.DOWN)
											? collisionNG.stemEndPos
											: notes[0].vPos;
											//: collisionNG.notes[0].vPos;
									vPos = (max > defaultBelowPos - 1.5 * space)
											? max + 1.5 * space 
											: defaultBelowPos;
								}
							}
							else {
								vPos = (attachment.isAbove)
										? defaultAbovePos - attachment.height 
										: defaultBelowPos;
							}

						}
						else { 
							//if the measure had no notes, we have to just use default 
							//positioning - shouldn't usually happen
							hPos = ((attachment.qNoteTime - stack.startTime) / 
									(stack.dpqLength)) * stackWidth;
							vPos = (attachment.isAbove)
									? defaultAbovePos - attachment.height 
									: defaultBelowPos;
						}


						attachment.hPos = hPos;
						attachment.vPos = vPos;
					}
				}

			}
		}
	}
	
	void _formatNoteAttachments(System system) {
		var stacks = system.measureStacks;

		num space = _score.scoreProperties.staffLineSpacing;
		num defaultAbovePos = -1 * space;
		num defaultBelowPos = 5 * space;
		//num noteheadWidth = _score.scoreProperties.noteheadWidth;

		for (var stack in stacks){
			var measures = stack.measures;
			int numMeasures = measures.length;
			for (int i = 0; i < numMeasures; i++){
				var measure = measures[i];
				var voices = measure.voices;
				for (int j = 0; j < voices.length; j++){
					var noteGroups = voices[j].noteGroups;
					int numNoteGroups = noteGroups.length;
					for (int k = 0; k < numNoteGroups; k++){
						var ng = noteGroups[k];
						if (ng.articulations == null){
							continue;
						}
						var notes = ng.visibleNotes;
						for (var artic in ng.articulations){
							int type = artic.type;
							artic.outsideStaff = (type == ArticulationType.ACCENT || ng.isRest);
							bool above;
							if (voices.length > 1){
								//articulations are above for upper voices
								above = (j % 2 == 0);
							}
							else {
								//if only one voice, they go note side, or if no stem, they go above
								above = (ng.stemDirection != StemDirection.UP);
							}
							artic.isAbove = above;
							if (above){
								if (ng.isRest){
									artic.hPos = (space * (1 - artic.width) / 2);
									artic.vPos = defaultAbovePos;
								}
								else {
									//var topNote = ng.notes.last;
									var topNote = notes.last;
									if (ng.stemDirection != StemDirection.UP){
										int highestNoteStaffLine = topNote.stepsFromTopStaffLine;
										int articStaffLine = (highestNoteStaffLine % 2 == 0 && 
																	highestNoteStaffLine >= 2)
																? highestNoteStaffLine - 3 
																: highestNoteStaffLine - 2;
										if (artic.outsideStaff && articStaffLine > -1){
											articStaffLine = -1;
										}
										artic.hPos = topNote.hPos + (space * (1 - artic.width) / 2);
										artic.vPos = articStaffLine * space / 2;
									}
									else {
										artic.hPos = topNote.hPos + (space * (1 - artic.width) / 2);
										artic.vPos = ng.stemEndPos - space;
									}
								}
							}
							else {
								if (ng.isRest){
									artic.hPos = (space * (1 - artic.width) / 2);
									artic.vPos = defaultBelowPos;
								}
								else {
									//var bottomNote = ng.notes[0];
									var bottomNote = notes[0];
									if (ng.stemDirection != StemDirection.DOWN){
										int lowestNoteStaffLine = bottomNote.stepsFromTopStaffLine;
										int articStaffLine = (lowestNoteStaffLine % 2 == 0 && 
																	lowestNoteStaffLine <= 6)
																? lowestNoteStaffLine + 3 
																: lowestNoteStaffLine + 2;
										if (artic.outsideStaff && articStaffLine < 9){
											articStaffLine = 9;
										}
										artic.hPos = bottomNote.hPos + (space * (1 - artic.width) / 2);
										artic.vPos = articStaffLine * space / 2;
									}
									else {
										artic.hPos = bottomNote.hPos + (space * (1 - artic.width) / 2);
										artic.vPos = ng.stemEndPos + space;
									}
								}
							}
						}
					}
				}
			}
		}
	}

	void _formatTuplet(NoteGroup ng, Tuplet tuplet, int level) {
		//3/19/15 - added isRest check initiation (used to be = false)
		bool needBracket = ng.isRest || (tuplet.endNote != null && tuplet.endNote.isRest); 
		var nextNG = ng;
		int stemUpTally = 0;
		int stemDownTally = 0;
		num highPoint = 1000;
		num lowPoint = -1000;
		while(nextNG != null){
			var nextNotes = nextNG.visibleNotes;
			//if (nextNG.beamStates.length == 0){
			if (nextNG.beamStates.length == 0){ 
				needBracket = true;
			}
			if (nextNG.stemDirection == StemDirection.UP){
				stemUpTally++;
				//if (nextNG.notes[0].vPos > lowPoint){
				//	lowPoint = nextNG.notes[0].vPos;
				//}
				if (nextNotes[0].vPos > lowPoint){
					lowPoint = nextNotes[0].vPos;
				}
				if (nextNG.stemEndPos < highPoint){
					highPoint = nextNG.stemEndPos;
				}
			}
			else if (nextNG.stemDirection == StemDirection.DOWN) {
				stemDownTally++;
				//if (nextNG.notes[nextNG.notes.length - 1].vPos < highPoint){
				//	highPoint = nextNG.notes[nextNG.notes.length - 1].vPos;
				//}
				if (nextNotes.last.vPos < highPoint){
					highPoint = nextNotes.last.vPos;
				}
				if (nextNG.stemEndPos > lowPoint){
					lowPoint = nextNG.stemEndPos;
				}
			}
			else if (nextNG.isRest){
				stemUpTally++;
			}
			else {
				stemUpTally++;
				//if (nextNG.notes[0].vPos > lowPoint){
				//	lowPoint = nextNG.notes[0].vPos;
				//}
				//if (nextNG.notes[nextNG.notes.length - 1].vPos < highPoint){
				//	highPoint = nextNG.notes[nextNG.notes.length - 1].vPos;
				//}
				if (nextNotes[0].vPos > lowPoint){
					lowPoint = nextNotes[0].vPos;
				}
				if (nextNotes.last.vPos < highPoint){
					highPoint = nextNotes.last.vPos;
				}
			}

			if (nextNG == tuplet.endNote){
				break;
			}

			nextNG = nextNG.next;
		}
		
		bool isAbove = stemUpTally >= stemDownTally;
		tuplet.above = isAbove;
		
		//make sure bracket appears outside of staff
		if (highPoint > 0){
			highPoint = 0;
		}
		if (lowPoint < _score.scoreProperties.staffLineSpacing * 4){
			lowPoint = _score.scoreProperties.staffLineSpacing * 4;
		}
		
		if (isAbove){
			tuplet.vPos = highPoint - ((level + 1 ) * _score.scoreProperties.staffLineSpacing);
		}
		else {
			tuplet.vPos = lowPoint + ((level + 1) * _score.scoreProperties.staffLineSpacing);
		}
		
		tuplet.showBracket = needBracket;
	}


	void _buildSlurSegments(Slur slur, int ngIndex, num vStaffPos) {
		NoteGroup ng1 = slur.firstNote;
		NoteGroup ng2 = slur.endNote;

		int voiceNumber = ng2.voice.number;

		num offset = _score.scoreProperties.staffLineSpacing / 2;

		Measure measure = ng1.voice.measure;
		System cSystem = measure.stack.systemRef;
		//bool systemsNeedRendering = cSystem.needsRendering;
		bool isAbove = ng1.stemDirection == StemDirection.DOWN;
		bool multipleVoices = measure.voices.length > 1;
		List<SlurSegment> segments = [];
		//List<num> ngCoordinates = [];
		Map<int, num> ngCoordinates = new Map<int, num>();
		int coordPos = 0;
		bool endNoteFound = false;
		
		SlurSegment segment;
		
		ngIndex++;
		bool breakOuterLoop = false;
		while (measure != null){
			num measureHPos = cSystem.indent + measure.stack.startPosition;
			if (measure.stack.systemRef != cSystem){
				//new system - create a segment for the last system
				segment = new SlurSegment();

				segment.systemRef = cSystem;
				segment.slur = slur;
				segment.ngCoordinates = ngCoordinates;
				segments.add(segment);
				cSystem.slurSegments.add(segment);

				cSystem = measure.stack.systemRef;
				if (cSystem.needsRendering){ //if any single system will be re-rendered, we have to re-render all of the systems containing this slur
					//systemsNeedRendering = true;
				}

				ngCoordinates = new Map<int, num>();
				coordPos = 0;
			}
			List<Voice> voices = measure.voices;
			for (var voice in voices){
				if (voice.number == voiceNumber){
					List<NoteGroup> noteGroups = voice.noteGroups;
					int numNoteGroups = noteGroups.length;
					//for (int i = 0; i < numNoteGroups; i++){
					for (int i = ngIndex; i < numNoteGroups; i++){
						NoteGroup cng = noteGroups[i];
						if (cng.isRest){
							continue;
						}

						if (cng.stemDirection == StemDirection.DOWN){
							isAbove = true;
						}

						if (cng != ng2){
							var cngNotes = cng.visibleNotes;
							if (cng.stemDirection == StemDirection.DOWN){

								//log the top position of this noteGroup
								//Note topNote = cng.notes[cng.notes.length - 1];
								var topNote = cngNotes.last;
								ngCoordinates[coordPos] = cng.hPos + measureHPos;
								ngCoordinates[coordPos + 1] = topNote.vPos;
								coordPos += 2;

								//log the low position of this noteGroup
								ngCoordinates[coordPos] = cng.hPos + measureHPos;
								ngCoordinates[coordPos + 1] = cng.stemEndPos;
								coordPos += 2;
							}
							else {
								//log the low position of this noteGroup
								//Note bottomNote = cng.notes[0];
								var bottomNote = cngNotes[0];
								ngCoordinates[coordPos] = cng.hPos + measureHPos;
								ngCoordinates[coordPos + 1] = bottomNote.vPos;
								coordPos += 2;

								//log the high position of this noteGroup - depends on whether it has a stem or not
								ngCoordinates[coordPos] = cng.hPos + measureHPos;
								//ngCoordinates[coordPos + 1] = (cng.stemDirection == StemDirection.UP)
								//								? cng.stemEndPos : cng.notes[cng.notes.length - 1].vPos;
								ngCoordinates[coordPos + 1] = (cng.stemDirection == StemDirection.UP)
																? cng.stemEndPos : cngNotes.last.vPos;
								coordPos += 2;
							}
						}
						else {
							//last note of the slur

							segment = new SlurSegment();
							segment.ngCoordinates = ngCoordinates;
							segment.systemRef = cSystem;
							segment.slur = slur;
							segments.add(segment);
							cSystem.slurSegments.add(segment);

							endNoteFound = true;
							breakOuterLoop = true;
							break;
						}
					}
					if (breakOuterLoop) {
						break;
					}
					ngIndex = 0;
				}
			}
			
			if (breakOuterLoop) {
				break;
			}

			measure = measure.next;
			if (measure.voices.length > 1){
				multipleVoices = true;
			}
		}

		if (!endNoteFound){
			ng1.slurs.removeAt(ng1.slurs.indexOf(slur));
			if (slur.endNote != null){
				slur.endNote.slurs.removeAt(slur.endNote.slurs.indexOf(slur));
			}
			return;
		}

		if (multipleVoices){
			isAbove = (ng1.voice.number == 1);
		}

		slur.segments = segments;

		//calculate the 4 curve points for each segment
		PointXY startPoint;
		PointXY endPoint;
		num slope;
		num angle;
		num cpXOffset;
		PointXY cp1;
		PointXY cp2;
		num yShift;
		num yIntercept;
		num perpSlope;
		num intersectX;
		num intersectY;
		
		for (int i = 0; i < segments.length; i++){
			segment = segments[i];

			num hPos;
			num vPos;
			//set starting point
			if (i == 0){ //first segment attaches to ng1
				if (isAbove){
					if (ng1.stemDirection == StemDirection.UP){
						if (ng1.beamStates.length > 0 && ng1.beamStates[0] != BeamState.END){
							hPos = segment.systemRef.indent + ng1.voice.measure.stack.startPosition + ng1.hPos + ng1.stemHPos;
							vPos = ng1.stemEndPos - offset;
						}
						else {
							hPos = segment.systemRef.indent + ng1.voice.measure.stack.startPosition + ng1.hPos + ng1.stemHPos + offset;
							vPos = ng1.stemEndPos + 2 * offset;
						}						
					}
					else {
						hPos = segment.systemRef.indent + ng1.voice.measure.stack.startPosition + ng1.hPos + offset;
						//vPos = ng1.notes[ng1.notes.length - 1].vPos - 2 * offset;
						vPos = ng1.visibleNotes.last.vPos - 2 * offset;
					}
					
					startPoint = new PointXY(hPos, vPos);
				}
				else {
					if (ng1.stemDirection == StemDirection.DOWN){
						if (ng1.beamStates.length > 0 && ng1.beamStates[0] != BeamState.END){
							hPos = segment.systemRef.indent + ng1.voice.measure.stack.startPosition + ng1.hPos + ng1.stemHPos;
							vPos = ng1.stemEndPos + offset;
						}
						else {
							hPos = segment.systemRef.indent + ng1.voice.measure.stack.startPosition + ng1.hPos + ng1.stemHPos + offset;
							vPos = ng1.stemEndPos - 2 * offset;
						}
					}
					else {
						hPos = segment.systemRef.indent + ng1.voice.measure.stack.startPosition + ng1.hPos + offset;
						//vPos = ng1.notes[0].vPos + 2 * offset;
						vPos = ng1.visibleNotes[0].vPos + 2 * offset;
					}
					startPoint = new PointXY(hPos, vPos);
				}
			}
			else { //subsequent segments start at beginning of system
				MeasureStack firstStack = segment.systemRef.measureStacks[0];
				hPos = firstStack.startPosition + firstStack.indentAsSystemLeader - firstStack.indent + segment.systemRef.indent;
				if (i == segments.length - 1){
					//if this segment ends on ng2, we match ng2's height if it is above/below the staff, or otherwise the top/bottom of the staff
					if (isAbove){
						vPos = -1 * offset;
						if (ng2.stemEndPos - offset < vPos){
							vPos = ng2.stemEndPos - offset;
						}
						else {
							var ng2TopNote = ng2.visibleNotes.last;
							if (ng2TopNote.vPos - offset < vPos){
								vPos = ng2TopNote.vPos - offset;
							}
						}
						//else if (ng2.notes[ng2.notes.length - 1].vPos - offset < vPos){
						//	vPos = ng2.notes[ng2.notes.length - 1].vPos - offset;
						//}
					}
					else {
						vPos = 4 * _score.scoreProperties.staffLineSpacing + offset;
						if (ng2.stemEndPos + offset > vPos){
							vPos = ng2.stemEndPos + offset;
						}
						else {
							var ng2BottomNote = ng2.visibleNotes[0];
							if (ng2BottomNote.vPos + offset > vPos){
								vPos = ng2BottomNote.vPos + offset;
							}
						}
						//else if (ng2.notes[0].vPos + offset > vPos){
						//	vPos = ng2.notes[0].vPos + offset;
						//}
					}
				}
				else {
					vPos = (isAbove)? -1 * offset : 4 * _score.scoreProperties.staffLineSpacing + offset;
				}
				//
				startPoint = new PointXY(hPos, vPos);
			}

			segment.points[0] = startPoint;

			//set ending point
			if (i == segments.length - 1){ //attach to ng2
				if (isAbove){
					if (ng2.stemDirection == StemDirection.UP){
						if (ng2.beamStates.length > 0 && ng2.beamStates[0] != BeamState.BEGIN){
							hPos = segment.systemRef.indent + ng2.voice.measure.stack.startPosition + ng2.hPos + ng2.stemHPos;
							vPos = ng2.stemEndPos - offset;
						}
						else {
							hPos = segment.systemRef.indent + ng2.voice.measure.stack.startPosition + ng2.hPos + ng2.stemHPos - offset;
							vPos = ng2.stemEndPos + 2 * offset;
						}

					}
					else {
						hPos = segment.systemRef.indent + ng2.voice.measure.stack.startPosition + ng2.hPos + offset;
						vPos = ng2.visibleNotes.last.vPos - 2 * offset;
						//vPos = ng2.notes[ng2.notes.length - 1].vPos - 2 * offset;
					}
					endPoint = new PointXY(hPos, vPos);
				}
				else {
					if (ng2.stemDirection == StemDirection.DOWN){
						if (ng2.beamStates.length > 0 && ng2.beamStates[0] != BeamState.BEGIN){
							hPos = segment.systemRef.indent + ng2.voice.measure.stack.startPosition + ng2.hPos + ng2.stemHPos;
							vPos = ng2.stemEndPos + offset;
						}
						else {
							hPos = segment.systemRef.indent + ng2.voice.measure.stack.startPosition + ng2.hPos + ng2.stemHPos - offset;
							vPos = ng2.stemEndPos - 2 * offset;
						}
					}
					else {
						hPos = segment.systemRef.indent + ng2.voice.measure.stack.startPosition + ng2.hPos + offset;
						//vPos = ng2.notes[0].vPos + 2 * offset;
						vPos = ng2.visibleNotes[0].vPos + 2 * offset;
					}
					endPoint = new PointXY(hPos, vPos);
				}
			}
			else { //attach to end of system
				MeasureStack lastStack = segment.systemRef.measureStacks[segment.systemRef.measureStacks.length - 1];
				hPos = lastStack.startPosition + lastStack.width + segment.systemRef.indent;
				//if this segment starts on ng1, we match ng1's height if it is above/below the staff, or otherwise the top/bottom of the staff
				if (i == 0){
					if (isAbove){
						vPos = -1 * offset;
						if (startPoint.y < vPos){
							vPos = startPoint.y;
						}
					}
					else {
						vPos = 4 * _score.scoreProperties.staffLineSpacing + offset;
						if (startPoint.y > vPos){
							vPos = startPoint.y;
						}
					}
				}
				else {
					vPos = (isAbove)? -1 * offset : 4 * _score.scoreProperties.staffLineSpacing + offset;
				}

				endPoint = new PointXY(hPos, vPos);
			}

			segment.points[3] = endPoint;


			/*if (ng1.voice.measure.stack.number == 5 && ng1.numDots == 0){
				trace("measure 5");
			}*/


			//set control points
			num deltaX = startPoint.x * -1;
			num deltaY = startPoint.y * -1;

			//we'll temporarily set the start point to the origin to make the math simpler
			PointXY sp = new PointXY(startPoint.x + deltaX, startPoint.y + deltaY);
			PointXY ep = new PointXY(endPoint.x + deltaX, endPoint.y + deltaY);


			num defaultCPHeight = math.min(2 * offset, offset * ((ep.x - sp.x) / 100));

			if (isAbove){

				//compute the desired slope and angle of the slur, based on the endpoints
				slope = (ep.y - sp.y) / (ep.x - sp.x);
				angle = math.atan2((ep.y - sp.y), (ep.x - sp.x));
				//trace("angle, cosine:", angle, Math.cos(angle));
				//plot initial values for the control points based on a minimum arc height and the angle
				/*Point cp1 = new Point(((ep.x - sp.x) / 20) * Math.cos(angle),
										((ep.y - sp.y) / 20) - ((defaultCPHeight) * Math.cos(angle)));
				Point cp2 = new Point(((ep.x - sp.x) * 19 / 20) * Math.cos(angle),
										((ep.y - sp.y) * 19 / 20) - ((defaultCPHeight) * Math.cos(angle)));*/
				cpXOffset = (ep.x - sp.x > 100)? 10 : (ep.x - sp.x) / 4;
				cp1 = new PointXY((cpXOffset) * math.cos(angle),
										((ep.y - sp.y) * cpXOffset / ep.x) - ((defaultCPHeight) * math.cos(angle)));
				cp2 = new PointXY(ep.x - (cpXOffset * math.cos(angle)),
										((ep.y - sp.y) * ((ep.x - cpXOffset) / ep.x)) - ((defaultCPHeight) * math.cos(angle)));
				/*Point cp2 = new Point((ep.x - cpXOffset) * Math.cos(angle),
										((ep.y - sp.y) * ((ep.x - cpXOffset) / ep.x)) - ((defaultCPHeight) * Math.cos(angle)));*/

				//trace (slope, (cp2.y - cp1.y) / (cp2.x - cp1.x)); //compare slopes

				ngCoordinates = segment.ngCoordinates;
				num numValues = ngCoordinates.length;
				int j = 0;
				while (j < numValues){
					ngCoordinates[j] += deltaX;
					ngCoordinates[j + 1] += deltaY;

					//notes coming at the beginning or end of a slur don't benefit from the slur's arc, so we require a little extra space for these
					//by exaggerating their height a little
					if (ngCoordinates[j] / ep.x < 0.25){
						ngCoordinates[j + 1] -= offset;
					}
					else if (ngCoordinates[j] / ep.x > 0.75){
						ngCoordinates[j + 1] -= offset;
					}

					if (ngCoordinates[j + 1] < ngCoordinates[j] * slope + cp1.y){ //y < mx + b
						//if this point lies above our line, we have to move the y values of our control points up
						yShift = ngCoordinates[j + 1] - (ngCoordinates[j] * slope + (cp1.y)); //y - (mx + b) = distance to shift
						cp1.y += yShift;
						cp2.y += yShift;
						//apply a little extra buffer around beginning and end of slur - the middle will arc and doesn't need it
						/*if (ngCoordinates[j] / ep.x < 0.25){
							cp1.y -= offset;
						}
						else if (ngCoordinates[j] / ep.x > 0.75){
							cp2.y -= offset;
						}*/
					}
					
					j += 2;
				}

				//we have our height in terms of where we want the curve to pass through - now we roughly double the difference between
				//this Y position and the starting point's Y position to get a control point value
				if (slope == 0){
					slope = 0.001;
				}
				yIntercept = cp1.y - (slope * cp1.x);
				perpSlope = -1 / slope;
				intersectX = yIntercept / (perpSlope - slope);
				intersectY = perpSlope * intersectX;

				cp1.x += intersectX + (2 * offset * math.sin(angle));
				cp1.y += intersectY - (2 * offset * math.cos(angle));
				cp2.x += intersectX + (2 * offset * math.sin(angle));
				cp2.y += intersectY - (2 * offset * math.cos(angle));
			}
			else {
				//compute the desired slope and angle of the slur, based on the endpoints
				slope = (ep.y - sp.y) / (ep.x - sp.x);
				angle = math.atan2((ep.y - sp.y), (ep.x - sp.x));

				//plot initial values for the control points based on a minimum arc height and the angle
				/*cp1 = new Point(((ep.x - sp.x) / 4) * Math.cos(angle),
										((ep.y - sp.y) / 4) + ((defaultCPHeight) * Math.cos(angle)) );
				cp2 = new Point(((ep.x - sp.x) * 3 / 4) * Math.cos(angle),
										((ep.y - sp.y) * 3 / 4) + ((defaultCPHeight) * Math.cos(angle)) );*/

				cpXOffset = (ep.x - sp.x > 100)? 10 : (ep.x - sp.x) / 4;
				cp1 = new PointXY((cpXOffset) * math.cos(angle),
										((ep.y - sp.y) * cpXOffset / ep.x) + ((defaultCPHeight) * math.cos(angle)));
				cp2 = new PointXY(ep.x - (cpXOffset * math.cos(angle)),
										((ep.y - sp.y) * ((ep.x - cpXOffset) / ep.x)) + ((defaultCPHeight) * math.cos(angle)));
				/*cp2 = new Point((ep.x - cpXOffset) * Math.cos(angle),
										((ep.y - sp.y) * ((ep.x - cpXOffset) / ep.x)) + ((defaultCPHeight) * Math.cos(angle)));*/

				//trace (slope, (cp2.y - cp1.y) / (cp2.x - cp1.x)); //compare slopes

				ngCoordinates = segment.ngCoordinates;
				int numValues = ngCoordinates.length;
				int j = 0;
				while (j < numValues){
					ngCoordinates[j] += deltaX;
					ngCoordinates[j + 1] += deltaY;

					//notes coming at the beginning or end of a slur don't benefit from the slur's arc, so we require a little extra space for these
					if (ngCoordinates[j] / ep.x < 0.25){
						ngCoordinates[j + 1] += offset;
					}
					else if (ngCoordinates[j] / ep.x > 0.75){
						ngCoordinates[j + 1] += offset;
					}

					if (ngCoordinates[j + 1] > ngCoordinates[j] * slope + cp1.y){ //y > mx + b
						//if this point lies above our line, we have to move the y values of our control points up
						yShift = ngCoordinates[j + 1] - (ngCoordinates[j] * slope + (cp1.y)); //y - (mx + b) = distance to shift
						cp1.y += yShift;
						cp2.y += yShift;
						//apply a little extra buffer around beginning and end of slur - the middle will arc and doesn't need it
						/*if (ngCoordinates[j] / ep.x < 0.25){
							cp1.y += offset;
						}
						else if (ngCoordinates[j] / ep.x > 0.75){
							cp2.y += offset;
						}*/
					}
					
					j += 2;
				}

				//we have our height in terms of where we want the curve to pass through - now we roughly double the difference between
				//this Y position and the starting point's Y position to get a control point value
				if (slope == 0){
					slope = 0.001;
				}
				yIntercept = cp1.y - (slope * cp1.x);
				perpSlope = -1 / slope;
				intersectX = yIntercept / (perpSlope - slope);
				intersectY = perpSlope * intersectX;

				cp1.x += intersectX - (2 * offset * math.sin(angle));
				cp1.y += intersectY + (2 * offset * math.cos(angle));
				cp2.x += intersectX - (2 * offset * math.sin(angle));
				cp2.y += intersectY + (2 * offset * math.cos(angle));
			}

			segment.points[0] = sp;
			segment.points[1] = cp1;
			segment.points[2] = cp2;
			segment.points[3] = ep;

			segment.points[0].x += -deltaX;
			segment.points[0].y += vStaffPos - deltaY;
			segment.points[1].x += -deltaX;
			segment.points[1].y += vStaffPos - deltaY;
			segment.points[2].x += -deltaX;
			segment.points[2].y += vStaffPos - deltaY;
			segment.points[3].x += -deltaX;
			segment.points[3].y += vStaffPos - deltaY;
		}
		
	}
	
	void _setRepeatEndingHeight(List<MeasureStack> stacks, int firstStackIndex){
		//go through the stacks, and for any that appear under an ending, calculate the
		//highest note.
		
		num highestVPos = 0x99999999;
		bool underEndingBracket = true;
		List<RepeatDO> endingRDOs = [];
		for (int i = firstStackIndex; i < stacks.length; i++){
			var stack = stacks[i];
			
			//check to see if we have opened/closed an ending bracket
			bool endingFinished = false;
			if (stack.repeatDOs != null){
				for (var rdo in stack.repeatDOs){
					if (rdo.endingType == EndingType.START){
						underEndingBracket = true;
						endingRDOs.add(rdo);
					}
					else if (rdo.endingType == EndingType.DISCONTINUE || rdo.endingType == EndingType.STOP){
						endingFinished = true;
						endingRDOs.add(rdo);
					}
				
				}		
         	}
			
			//keep track of the highest note/stem position
			if (underEndingBracket){
				var measure = stack.measures[0];
				for (var voice in measure.voices){
					for (var ng in voice.noteGroups){
						if (ng.stemDirection == StemDirection.UP){
							if (ng.stemEndPos < highestVPos){
								highestVPos = ng.stemEndPos;
							}
						}
						else if (ng.isRest){
							if (ng.restVPos < highestVPos){
								highestVPos = ng.restVPos;
							}
						}
						else {
							num noteVPos = ng.visibleNotes.last.vPos;
							if (noteVPos < highestVPos){
								highestVPos = noteVPos;
							}
						}
					}
				}
			}
			
			if (endingFinished){
				underEndingBracket = false;
			}
			
		}
		
		//set the height of the ending(s)
		if (highestVPos > 0){
			highestVPos = 0;
		}
		num endingVPos = highestVPos - _score.scoreProperties.staffLineSpacing * 2;
		for (var rdo in endingRDOs){
			rdo.endingVPos = endingVPos;
		}
	}
	
}