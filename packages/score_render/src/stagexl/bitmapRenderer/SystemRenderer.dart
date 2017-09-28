part of score_render.stagexl.bitmap_renderer;


class SystemRenderer {
	ScoreProperties _scoreProps; //ScoreProperties object for the score

	//when re-rendering the music, we can re-use VisualNoteGroups from the previous render. We store a list of those previously rendered VNG's
	//and an index to keep track of which one we're currently on.
	List<VisualNoteGroup> _legacyVNoteGroups;
	int _legacyVNGIndex;


	static List<int> TC_FLAT_POSITIONS;
	static List<int> BC_FLAT_POSITIONS;
	static List<int> TC_SHARP_POSITIONS;
	static List<int> BC_SHARP_POSITIONS;
	static List<int> TENOR_FLAT_POSITIONS;
	static List<int> TENOR_SHARP_POSITIONS;
	static List<int> ALTO_FLAT_POSITIONS;
	static List<int> ALTO_SHARP_POSITIONS;

	SystemRenderer(ScoreProperties this._scoreProps) {
		
		_legacyVNGIndex = 0;
		
		if (TC_FLAT_POSITIONS == null) {
			TC_FLAT_POSITIONS = [4, 1, 5, 2, 6, 3, 7];
			BC_FLAT_POSITIONS = [6, 3, 7, 4, 8, 5, 9];
			TC_SHARP_POSITIONS = [0, 3, -1, 2, 5, 1, 4];
			BC_SHARP_POSITIONS = [2, 5, 1, 4, 7, 3, 6];
			TENOR_FLAT_POSITIONS = [3, 0, 4, 1, 5, 2, 6];
			TENOR_SHARP_POSITIONS = [6, 2, 5, 1, 4, 0, 3];
			ALTO_FLAT_POSITIONS = [5, 2, 6, 3, 7, 4, 8];
			ALTO_SHARP_POSITIONS = [1, 4, 0, 3, 6, 2, 5];
		}
	}

	VisualSystem renderSystem(System system, List<Part> parts,
			List<DisplayObject> addedObjects, List<DisplayObject> removedObjects) {
		VisualSystem visualSystem = new VisualSystem(system);

		system.visibleParts = parts;

		List<num> staffVPosOffsets = system.staffVPosOffsets; //positions of the top staff lines of each staff
		int numStaves = staffVPosOffsets.length; //number of staves in system
		List<int> staffGroupings = system.staffGroupings; //the number of staves each part contains
		List<MeasureStack> stacks = system.measureStacks;
		int numStacks = stacks.length;
		num systemIndent = system.indent; //indentation for the system
		num systemWidth = system.systemWidth; //the width of the system

		num staffSpacing = (system.staffLineSpacing * 4) + system.staffSpacing; //distance from top staff line of one staff to top staff line of next staff
		num vStaffPos = 0; //current staff's vertical position (top line of staff)

		//go through every measure in every stack, horizontally first and then
		// down (all measures in a staff before going to next staff)
		for (int i = 0; i < numStaves; i++){
			//make sure this is one of the staves we're supposed to draw
			if (parts.indexOf(stacks[0].measures[i].staff.partRef) == -1 ||
					stacks[0].measures[i].staff.visible == false){
				continue;
			}

			//add any staff vertical offset for this staff
			vStaffPos += staffVPosOffsets[i];
			
			//track the horizontal position of the start of each measure
			num horizMeasPos = systemIndent;

			//draw the staff lines for this staff
			drawStaff(systemWidth, visualSystem, systemIndent, vStaffPos);

			//add the notes - create a list of lists of VisualNoteGroups to
			//hold onto the notes - we'll use this to add the ties
			List<List<VisualNoteGroup>> vngLists = [];
			for (int j = 0; j < numStacks; j++){
				MeasureStack cStack = stacks[j];
				Measure cMeasure = cStack.measures[i];
				drawNotes(cMeasure, systemIndent, vngLists, visualSystem,
					vStaffPos, addedObjects, removedObjects);

				//add clef, key and time
				addClefKeyTime(cMeasure, systemIndent, vStaffPos, visualSystem,
					vngLists);

				addAttachments(cMeasure, systemIndent, vStaffPos, visualSystem);

				//mark the stack as rendered (technically it hasn't been
				//finished until this method completes, but this value isn't
				//checked inside the SystemRenderer)
				if (i == 0){
					cStack.needsRendering = false;
				}
				
				//create VisualMeasure
				num clefOffset = 0;
				if (j + 1 < numStacks && stacks[j + 1].newClef) {
					clefOffset = _scoreProps.clefWidth +
						_scoreProps.clefDistanceFromBarline;
				}
				else if (cStack.newClef && j > 0) {
					clefOffset = -1 * (_scoreProps.clefWidth +
						_scoreProps.clefDistanceFromBarline);
				}
				
				var vMeasure = new VisualMeasure(horizMeasPos, vStaffPos, 
						cStack.width + clefOffset, 4 * _scoreProps.staffLineSpacing,
						cMeasure);
				vMeasure.vSystemRef = visualSystem;
				visualSystem.visualMeasures.add(vMeasure);
				
				horizMeasPos += cStack.width + clefOffset;
			}

			//add the beams
			drawBeams(vngLists, systemIndent, vStaffPos, visualSystem);

			//add the tuplets
			drawTuplets(vngLists, vStaffPos, visualSystem);

			//add the ties
			drawTies(vngLists, vStaffPos, visualSystem);

			//increment the vertical staff position
			vStaffPos += staffSpacing;
		}

		//draw the bar lines
		renderVerticalBarlines(staffGroupings, systemIndent, visualSystem,
			vStaffPos - staffSpacing, stacks, systemWidth);
		
		//draw repeat signs and endings
		_drawRepeats(staffGroupings, systemIndent, visualSystem,
			vStaffPos - staffSpacing, stacks);

		//draw the slurs
		drawSlurs(system, visualSystem, parts);
		
		return visualSystem;
	}




	void drawStaff(num systemWidth, VisualSystem vSystem, num systemIndent, num vStaffPos) {
		vSystem.graphics.beginPath();
		for (int i = 0; i < 5; i++) {
			vSystem.graphics.moveTo(systemIndent, i * _scoreProps.staffLineSpacing + vStaffPos);
			vSystem.graphics.lineTo(systemWidth, i * _scoreProps.staffLineSpacing + vStaffPos);
		}
		vSystem.graphics.strokeColor(0xFF000000, _scoreProps.staffLineWidth);
		vSystem.graphics.closePath();
	}


	void drawNotes(Measure measure, num systemIndent, List<List<VisualNoteGroup>> vngLists,
							   VisualSystem vSystem, num vStaffPos, List<DisplayObject> addedObjects, List<DisplayObject> removedObjects) {
		//num systemHStartPos = systemIndent; //the extra inset from the left margin for this system
		//int partStaffIndex = measure.staff.partRef.staves.indexOf(measure.staff); //the index of the current staff within the current part's staves (not system's)
		//if this measure does not need to have its notes recreated, we'll just take the VisualNoteGroups that were created from the last render, reposition them,
		//and add them to this new system
		
		VisualNoteGroup visNoteGroup;
		
		if (!measure.notesNeedRendering){
			int numLegacyVNGs = _legacyVNoteGroups.length; 
			
			for (int i = 0; i < measure.voices.length; i++){
				//keep track of all of the notes added and the voices they are added to.
				if (vngLists.length < i + 1){
					//vngLists[i] = new List<VisualNoteGroup>();
					vngLists.add(new List<VisualNoteGroup>());
				}
				//find the VisualNoteGroup from the previous render that corresponds to each NoteGroup object
				for (var noteGroup in measure.voices[i].noteGroups) {
					bool loopedOnce = false; //normally the notes will be in the same order, but occasionally we may have to loop back around once to find it
					while(_legacyVNGIndex < numLegacyVNGs && _legacyVNoteGroups[_legacyVNGIndex].noteGroup != noteGroup){
						_legacyVNGIndex++;
						if (_legacyVNGIndex >= numLegacyVNGs){
							if (!loopedOnce){
								loopedOnce = true;
								_legacyVNGIndex = 0;
							}
						}
					}
					if (_legacyVNGIndex >= numLegacyVNGs){
						throw "Looking for a VisualNoteGroup that is not available for re-render! This probably means a Measure with a new note was not marked for re-rendering.";
					}
					visNoteGroup = _legacyVNoteGroups[_legacyVNGIndex];

					//we need to get rid of beams and tie attachments, leaving lyrics (and eventually tuplets)
					List<DisplayObject> attachments = [];
					for (var attachment in visNoteGroup.visualAttachments){
						if (attachment is Shape){ //keep only the ones that aren't Shapes
							attachments.add(attachment);
						}
					}
					visNoteGroup.visualAttachments = attachments;

					//update the VNG's position and add it to this system
					visNoteGroup.x = systemIndent + measure.stack.startPosition + noteGroup.hPos;
					visNoteGroup.y = vStaffPos;
					visNoteGroup.originalPosition.x = visNoteGroup.x;
					visNoteGroup.originalPosition.y = visNoteGroup.y;
					vSystem.addChild(visNoteGroup);
					visNoteGroup.vSystemRef = vSystem;
					vSystem.visNoteGroups.add(visNoteGroup);
					vngLists[i].add(visNoteGroup);
				}
			}
		}
		else {
			//go through every voice and create VisualNoteGroup objects for the notes in them. Store these both in a list that holds all of the notes on this system as well as the voices array to be returned
			//num systemHStartPos = _measures[0].extraLeftSystemMargin; //the extra inset from the left margin for this system

			for (int i = 0; i < measure.voices.length; i++) {
				//keep track of all of the notes added and the voices they are added to.
				if (vngLists.length < i + 1){
					//vngLists[i] = new List<VisualNoteGroup>();
					vngLists.add(new List<VisualNoteGroup>());
				}

				for (var noteGroup in measure.voices[i].noteGroups) {
					//String currentStaffsClefType = measure.clefs[partStaffIndex]; //measures contain the clefs for all staves, so pick the one for the current staff
					//visNoteGroup = new VisualNoteGroup(noteGroup, currentStaffsClefType, _scoreProps, vSystem);
					visNoteGroup = new VisualNoteGroup(noteGroup, _scoreProps, vSystem);
					//visNoteGroup.x = systemHStartPos + measure.startPosition + noteGroup.hPos;
					visNoteGroup.x = systemIndent + measure.stack.startPosition + noteGroup.hPos;
					visNoteGroup.y += vStaffPos;
					visNoteGroup.originalPosition = new Point(visNoteGroup.x, visNoteGroup.y);
					vSystem.addChild(visNoteGroup);
					vSystem.visNoteGroups.add(visNoteGroup);
					vngLists[i].add(visNoteGroup);
					addedObjects.add(visNoteGroup);
				}
			}

			//find any VisualNoteGroups from a previous render that used to belong to this measure. They must be added to our list of removed objects
			//since they won't be added to the new VisualSystem.
			if (_legacyVNoteGroups != null && _legacyVNoteGroups.length > 0){
				while(_legacyVNGIndex < _legacyVNoteGroups.length && _legacyVNoteGroups[_legacyVNGIndex].noteGroup.voice.measure == measure){
					removedObjects.add(_legacyVNoteGroups[_legacyVNGIndex]);
					_legacyVNGIndex++;
				}
			}

			measure.notesNeedRendering = false; //set the render requirement flag to false so that the notes won't be needlessly recreated
		}
	}

	void drawBeams(List<List<VisualNoteGroup>> vngLists, num systemIndent, num vStaffPos, VisualSystem vSystem) {
		//num systemHStartPos = _measures[0].extraLeftSystemMargin; //the extra inset from the left margin for this system
		//num systemHStartPos = systemIndent; //the extra inset from the left margin for this system
		//List<Point> currentBeams = []; //holds Point objects which contain the starting coordinates for beams
		Map<int, Point> currentBeams = {}; //holds Point objects which contain the starting coordinates for beams
		//num beamWidth = _scoreProps.beamWidth * _scoreProps.scale / ScoreProperties.STANDARD_SCALE;
		num beamWidth = _scoreProps.beamWidth;
		num stemEndPos = 0;
		num hPos = 0;
		num vPos = 0;
		//Shape beam;
		for (var vngList in vngLists){
			for (var vng in vngList) {
				NoteGroup noteGroup = vng.noteGroup;
				//make sure this noteGroup is visible
				if (!noteGroup.visible){
					//kill all beams involving this note
					currentBeams = {};
					continue;
				}
				
				num scale = (!noteGroup.isGrace)? 1 : 0.65;
				num stackPos = noteGroup.voice.measure.stack.startPosition; //horizontal position of the measure stack
				beamWidth = _scoreProps.beamWidth * scale;
				//num halfNoteheadWidth = scale * _scoreProps.noteheadWidth / 2;
				for (int i = 0; i < noteGroup.beamStates.length; i++) {
					//find the vertical attach point for a beam
					if (noteGroup.beamStates[i] != BeamState.CONTINUE && noteGroup.beamStates[i] != BeamState.NONE) {
						//num stemEndPos = noteGroup.stemEndPos * _scoreProps.scale / ScoreProperties.STANDARD_SCALE;
						stemEndPos = noteGroup.stemEndPos;
						//num hPos = (noteGroup.stemDirection == StemDirection.UP)? systemIndent + stackPos + noteGroup.hPos + halfNoteheadWidth: systemIndent + stackPos + noteGroup.hPos - halfNoteheadWidth;
						hPos = systemIndent + stackPos + noteGroup.hPos + noteGroup.stemHPos;
						//num vPos = (noteGroup.stemDirection == StemDirection.UP)? -1 * stemEndPos + (beamWidth * 2 * i) : -1 * stemEndPos - (beamWidth * 2 * i);
						vPos = (noteGroup.stemDirection == StemDirection.UP)? stemEndPos + (beamWidth * 2 * i) : stemEndPos - (beamWidth * 2 * i);
						vPos += vStaffPos;
					}
					switch(noteGroup.beamStates[i]) {
						case BeamState.BEGIN:
							//store the starting point for the beam in an array. The outer most beam will be index 0, the second beam index 1, etc.
							currentBeams[i] = new Point(hPos, vPos);
							break;
						case BeamState.END:
							//retrieve the starting point for the beam with the matching index
							Point startingPoint = currentBeams[i];
							
							if (startingPoint != null) {
								//create the beam as a shape and add it
//								beam = new BeamShape();
//								beam.graphics.beginPath();
//								beam.graphics.lineTo(hPos - startingPoint.x, vPos - startingPoint.y);
//								beam.graphics.strokeColor(0xFF000000, beamWidth, JointStyle.ROUND, CapsStyle.SQUARE);
//								beam.graphics.closePath();
//								beam.x = startingPoint.x;
//								beam.y = startingPoint.y;
//								vSystem.addChild(beam);
//								vng.visualAttachments.add(beam);
								
								vSystem.graphics.beginPath();
								vSystem.graphics.moveTo(startingPoint.x, startingPoint.y);
								vSystem.graphics.lineTo(hPos, vPos);
								vSystem.graphics.strokeColor(0xFF000000, beamWidth, JointStyle.ROUND, CapsStyle.NONE);
								vSystem.graphics.closePath();
							}
							break;
						case BeamState.CONTINUE:
							//do nothing
							break;
						case BeamState.FORWARD_HOOK:
							//draw a line straight to the right
//							beam = new BeamShape();
//							beam.graphics.beginPath();
//							beam.graphics.lineTo(_scoreProps.noteheadWidth / 1.5, 0);
//							beam.graphics.strokeColor(0xFF000000, beamWidth, JointStyle.ROUND, CapsStyle.SQUARE);
//							beam.graphics.closePath();
//							beam.x = hPos;
//							beam.y = vPos;
//							vSystem.addChild(beam);
//							vng.visualAttachments.add(beam);
							
							vSystem.graphics.beginPath();
							vSystem.graphics.moveTo(hPos, vPos);
							vSystem.graphics.lineTo(hPos + _scoreProps.noteheadWidth / 1.5, vPos);
							vSystem.graphics.strokeColor(0xFF000000, beamWidth, JointStyle.ROUND, CapsStyle.NONE);
							vSystem.graphics.closePath();
							
							break;
						case BeamState.BACKWARD_HOOK:
							//draw a line straight to the left
//							beam = new BeamShape();
//							beam.graphics.beginPath();
//							beam.graphics.lineTo(-1 * _scoreProps.noteheadWidth / 1.5, 0);
//							beam.graphics.strokeColor(0xFF000000, beamWidth, JointStyle.ROUND, CapsStyle.SQUARE);
//							beam.graphics.closePath();
//							beam.x = hPos;
//							beam.y = vPos;
//							vSystem.addChild(beam);
//							vng.visualAttachments.add(beam);
							
							vSystem.graphics.beginPath();
							vSystem.graphics.moveTo(hPos, vPos);
							vSystem.graphics.lineTo(hPos - _scoreProps.noteheadWidth / 1.5, vPos);
							vSystem.graphics.strokeColor(0xFF000000, beamWidth, JointStyle.ROUND, CapsStyle.NONE);
							vSystem.graphics.closePath();
							
							break;
						case BeamState.NONE:
							//do nothing
							break;
						default:
							print("Unrecognized Beam Stage! VisualSystem.drawBeams() ${noteGroup.beamStates[i]}");
					}
				}
			}
		}
	}

//	void drawTuplets(List<List<VisualNoteGroup>> vngLists, num vStaffPos, VisualSystem vSystem) {
//		//go through every note on the system. If it has a Tuplet object, draw its value to a TextField and copy it onto a Bitmap object. Add the Bitmap in the location
//		//at the middle of the notes that comprise the tuplet, positioned vertically above or below according to the definition
//		TextField tupletTF = new TextField();
//
//		for (var vngList in vngLists){
//			for (var vng in vngList) {
//				NoteGroup noteGroup = vng.noteGroup;
//				if (noteGroup.tuplets == null) {
//					continue;
//				}
//				for (var tuplet in noteGroup.tuplets) {
//					if (tuplet.firstNote == vng.noteGroup) {
//						//TextField tupletTF = new TextField();
//
//						tupletTF.text = tuplet.numerator.toString();
//						BitmapData bd = new BitmapData(20, 20, true, 0x00000000);
//						bd.draw(tupletTF);
//						Bitmap bitmap = new Bitmap(bd);
//						if (tuplet.above) {
//							bitmap.x = vng.x + ((tuplet.endNote.hPos - vng.noteGroup.hPos) / 2);
//							//bitmap.filters = [new GlowFilter(0x00FF00)];
//							if (vng.noteGroup.isRest) {
//								bitmap.y = vng.noteGroup.restVPos - 30 + vStaffPos;
//								//bitmap.filters = [new GlowFilter()];
//							}
//							else if (vng.noteGroup.stemDirection == StemDirection.UP) {
//								//bitmap.y = -1 * vng.noteGroup.stemEndPos - 20 + vStaffPos;
//								bitmap.y = vng.noteGroup.stemEndPos - 20 + vStaffPos;
//							}
//							else {
//								bitmap.y = vng.noteGroup.notes[vng.noteGroup.notes.length - 1].vPos - 20 + vStaffPos;
//							}
//						}
//						else {
//							//bitmap.x = vng.x + ((tuplet.endNote.hPos - vng.noteGroup.hPos) / 2) - bitmap.width / 2;
//							bitmap.x = vng.x + ((tuplet.endNote.hPos - vng.noteGroup.hPos) / 2);
//							if (vng.noteGroup.isRest) {
//								bitmap.y = vng.noteGroup.restVPos + 20 + vStaffPos;
//							}
//							else if (vng.noteGroup.stemDirection == StemDirection.UP) {
//								bitmap.y = vng.noteGroup.notes[0].vPos + 5 + vStaffPos;
//							}
//							else {
//								//bitmap.y = -1 * vng.noteGroup.stemEndPos + 5 + vStaffPos;
//								bitmap.y = vng.noteGroup.stemEndPos + 5 + vStaffPos;
//							}
//						}
//						vSystem.addChild(bitmap);
//					}
//				}
//			}
//		}
//	}
	
	void drawTuplets(List<List<VisualNoteGroup>> vngLists, num vStaffPos, VisualSystem vSystem) {
		//go through every note on the system. If it has a Tuplet object, draw its value to a 
		//TextField and copy it onto a Bitmap object. Add the Bitmap in the location
		//at the middle of the notes that comprise the tuplet, positioned vertically above or 
		//below according to the definition
		var tupletTF = new TextField();
		bool drawTupletBrackets = false;
		for (var vngList in vngLists){
			for (var vng in vngList) {
				if (vng.noteGroup.tuplets == null){
					continue;
				}
				var noteGroup = vng.noteGroup;
				for (var tuplet in noteGroup.tuplets) {
					if (tuplet.firstNote.visible == false || tuplet.endNote.visible == false){
						continue; //don't draw tuplets unless start and end points are visible
					}
					if (tuplet.firstNote == noteGroup) {

						tupletTF.text = tuplet.numerator.toString();
						var bd = new BitmapData(20, 20, 0x00000000);
						bd.draw(tupletTF);
						var bitmap = new Bitmap(bd);
						
						//NEW RENDER TECHNIQUE
						num centerX = vng.x + ((tuplet.endNote.hPos - vng.noteGroup.hPos) / 2) + 
										tuplet.firstNote.stemHPos / 2;
						bitmap.x = centerX;
						num vPos = tuplet.vPos + vStaffPos;
						bitmap.y = vPos - bitmap.height / 2;
						if (tuplet.showBracket){
							if (drawTupletBrackets == false){
								drawTupletBrackets = true;
								vSystem.graphics.beginPath();
							}
							num startX = vng.x;
							num endX = vng.x + (tuplet.endNote.hPos - vng.noteGroup.hPos) + 
										_scoreProps.noteheadWidth;
							num hookEndVPos = (tuplet.above)
									? vPos + _scoreProps.staffLineSpacing / 2 
									: vPos - _scoreProps.staffLineSpacing / 2;
							vSystem.graphics.moveTo(startX, hookEndVPos);
							vSystem.graphics.lineTo(startX, vPos);
							vSystem.graphics.lineTo(centerX - 0.3 * _scoreProps.staffLineSpacing, vPos);
							vSystem.graphics.moveTo(centerX + 1.2 * _scoreProps.staffLineSpacing, vPos);
							vSystem.graphics.lineTo(endX, vPos);
							vSystem.graphics.lineTo(endX, hookEndVPos);
						}
						
						vSystem.addChild(bitmap);
					}
				}
			}
		}
		if (drawTupletBrackets){
			vSystem.graphics.strokeColor(0xFF000000, _scoreProps.tupletBracketWidth, JointStyle.ROUND, CapsStyle.NONE);
		}
	}

	void addClefKeyTime(Measure measure, num systemIndent, num vStaffPos, VisualSystem vSystem, List<List<VisualNoteGroup>> vngLists) {
		//track the horizontal position based on what has been added
		//num hInsertPos = measure.startPosition + _measures[0].extraLeftSystemMargin;
		num hInsertPos = measure.stack.startPosition + systemIndent;

		//int partStaffIndex = measure.staff.partRef.staves.indexOf(measure.staff); //the index of the current staff within the current part's staves (not system's)

		//String clefType = measure.clefs[partStaffIndex];
		List<Clef> clefList = measure.clefs;
		String clefType = clefList[0].type;

		//add the start of measure clef
		if (clefList[0].show){
			hInsertPos += _scoreProps.clefDistanceFromBarline;
			drawClef(clefType, clefList[0].smallSize, hInsertPos, vStaffPos, vSystem);

			hInsertPos += _scoreProps.clefWidth;
		}
		else if (measure.stack.newClef){
			//even if this measure didn't have a clef, another measure in the stack might have, and we need to keep things lined up vertically
			hInsertPos += _scoreProps.clefDistanceFromBarline + _scoreProps.clefWidth;
		}

		//add any mid measure clefs
		int i = 1;
		while (i < clefList.length){
			Clef clef = clefList[i];
			bool breakMiddle = false;
			for (var vngList in vngLists){
				int numVNGs = vngList.length;
				for (int j = 0; j < numVNGs; j++){
					if (vngList[j].noteGroup.clef == clef){
						drawClef(clef.type, clef.smallSize, vngList[j].x - _scoreProps.clefWidth - _scoreProps.clefDistanceFromBarline, vStaffPos, vSystem);
						breakMiddle = true;
						break;
					}
				}
				if (breakMiddle) {
					break;
				}
			}
			i++;
		}
		
		//add the key
		if (measure.showKey) {

			hInsertPos += _scoreProps.clefDistanceFromBarline;

			int displayKey = measure.displayKey;
			int outgoingKey = measure.outgoingKey;

			//figure out whether this is sharps or flats and choose the positionings based on the clef
			List<int> sharpPositions = TC_SHARP_POSITIONS;
			List<int> flatPositions = TC_FLAT_POSITIONS;
			switch (clefType) {
				case ClefType.TREBLE:
					sharpPositions = TC_SHARP_POSITIONS;
					flatPositions = TC_FLAT_POSITIONS;
					break;
				case ClefType.BASS:
					sharpPositions = BC_SHARP_POSITIONS;
					flatPositions = BC_FLAT_POSITIONS;
					break;
				case ClefType.TENOR:
					sharpPositions = TENOR_SHARP_POSITIONS;
					flatPositions = TENOR_FLAT_POSITIONS;
					break;
				case ClefType.ALTO:
					sharpPositions = ALTO_SHARP_POSITIONS;
					flatPositions = ALTO_FLAT_POSITIONS;
					break;
				default:
					print("unrecognized clef type! $clefType VisualSystem.addClefKeyTime()");
			}

			List<int> accidentalList = PitchUtils.getAccidentalsForNewKeySignature(displayKey, outgoingKey);

			int numAccidentals = 0;

			//first we draw any naturals that cancel flats
			for (int i = 0; i < 7; i++){
				if (accidentalList[i] == 1){
					drawAccidental(MusicTextures.natural, 0.6, (hInsertPos + (numAccidentals * _scoreProps.keySigWidth)).round(), flatPositions[i], vStaffPos, vSystem);
					numAccidentals++;
				}
			}
			//now draw naturals that cancel sharps
			for (int i = 7; i < 14; i++){
				if (accidentalList[i] == 1){
					drawAccidental(MusicTextures.natural, 0.6, (hInsertPos + (numAccidentals * _scoreProps.keySigWidth)).round(), sharpPositions[i - 7], vStaffPos, vSystem);
					numAccidentals++;
				}
			}
			//draw flats for the new key
			for (int i = 14; i < 21; i++){
				if (accidentalList[i] == 1){
					drawAccidental(MusicTextures.flat, 0.6, (hInsertPos + (numAccidentals * _scoreProps.keySigWidth)).round(), 
							flatPositions[i - 14], vStaffPos, vSystem, -0.5 * _scoreProps.staffLineSpacing);
					numAccidentals++;
				}
				else if (accidentalList[i] == 2) { //double flat
					drawAccidental(MusicTextures.doubleFlat, 1.0, (hInsertPos + (numAccidentals * _scoreProps.keySigWidth)).round(), 
							flatPositions[i - 14], vStaffPos, vSystem, -0.5 * _scoreProps.staffLineSpacing);
					numAccidentals++;
				}
			}
			//draw sharps for the new key
			for (int i = 21; i < 28; i++){
				if (accidentalList[i] == 1){
					drawAccidental(MusicTextures.sharp, 0.75, (hInsertPos + (numAccidentals * _scoreProps.keySigWidth)).round(), sharpPositions[i - 21], vStaffPos, vSystem);
					numAccidentals++;
				}
				else if (accidentalList[i] == 2) { //double sharp
					drawAccidental(MusicTextures.doubleSharp, 0.8, (hInsertPos + (numAccidentals * _scoreProps.keySigWidth)).round(), sharpPositions[i - 21], vStaffPos, vSystem);
					numAccidentals++;
				}
			}

			hInsertPos += _scoreProps.keySigWidth * measure.stack.maxKeySize;

		}

		//add the time sig
		if (measure.showTime) {
			hInsertPos += _scoreProps.clefDistanceFromBarline;
			//time sig goes at measStackPos + sysIndent + stackIndent - clefWidth + clefDistanceFromBarline
			//num stackIndent = (measure.stack.newSystem)? measure.stack.indentAsSystemLeader : measure.stack.indent;
			//hInsertPos = measure.stack.startPosition + systemIndent + stackIndent - 8 * (_scoreProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT) + _scoreProps.clefDistanceFromBarline;

			TextField timeTF = new TextField();
			//TextFormat tFormat = new TextFormat("Arial", 26 * _scoreProps.scale / ScoreProperties.STANDARD_SCALE);
			const num sizeMultiple = 4.0; //experiment 3/8/2015
			TextFormat tFormat = new TextFormat("Arial", 3 * sizeMultiple * _scoreProps.staffLineSpacing, 0xFF000000, 
												align: TextFormatAlign.CENTER);
			tFormat.leading = -1.3 * sizeMultiple * _scoreProps.noteheadWidth;
			timeTF.defaultTextFormat = tFormat;
			timeTF.text = (measure.displayNumBeats == null)
							? measure.numBeats.toString() + "\n" + measure.beatType.toString()
		      				: measure.displayNumBeats.toString() + "\n" + measure.displayBeatType.toString();
			timeTF.autoSize = TextFieldAutoSize.CENTER;

			Bitmap timeBitmap = new Bitmap(new BitmapData(timeTF.textWidth.round() + 2, timeTF.textHeight.round(), 0x00FFFFFF));
			timeBitmap.bitmapData.draw(timeTF);
			timeBitmap.x = hInsertPos;
			timeBitmap.y = vStaffPos - timeBitmap.height / (7 * sizeMultiple);
			timeBitmap.scaleX = timeBitmap.scaleY = 1 / sizeMultiple;
			vSystem.addChild(timeBitmap);
		}
	}

	void drawClef(String clefType, bool smallSize, num xPos, num vStaffPos, VisualSystem vSystem) {
		Bitmap clefShape;
		switch (clefType) {
			case ClefType.TREBLE:
				clefShape = (new Bitmap(MusicTextures.trebleClef));
				clefShape.y = (smallSize)? vStaffPos - 1 * _scoreProps.staffLineSpacing 
										: vStaffPos - 2 * _scoreProps.staffLineSpacing;
				//treble clef needs resizing to fit - it's uniquely too short
				//clefShape.height = 7.9 * _scoreProps.staffLineSpacing;
				//clefShape.scaleX = clefShape.scaleY;
				break;
				
			case ClefType.BASS:
				clefShape = (new Bitmap(MusicTextures.bassClef));
				clefShape.y = (smallSize)? vStaffPos + _scoreProps.staffLineSpacing / 6 : vStaffPos;
				break;
				
			case ClefType.TENOR:
				clefShape = (new Bitmap(MusicTextures.tenorClef));
				clefShape.y = (smallSize)? vStaffPos + _scoreProps.staffLineSpacing / 6 : vStaffPos;
				break;
				
			case ClefType.ALTO:
				clefShape = (new Bitmap(MusicTextures.altoClef));
				clefShape.y = (smallSize)? vStaffPos + _scoreProps.staffLineSpacing / 6 : vStaffPos;
				break;
				
			default:
				print("unrecognized clef type! $clefType VisualSystem.addClefKeyTime()");
				clefShape = (new Bitmap(MusicTextures.trebleClef));
		}
		clefShape.x = xPos;
		
		//clefShape.scaleX = clefShape.scaleY = _scoreProps.clefWidth / (clefShape.width);
		if (smallSize){
			clefShape.scaleX = clefShape.scaleY *= 0.75;
		}
		vSystem.addChild(clefShape);
	}

	void drawAccidental(BitmapData accidentalBD, num scaling, int hInsertPos, int stepsFromTopStaffLine, 
	                    num vStaffPos, VisualSystem vSystem, [num vertOffset = 0]) {
		Bitmap accidentalShape = new Bitmap(accidentalBD);
		//accidentalShape.width = scaling * _scoreProps.noteheadWidth;
		//accidentalShape.scaleY = accidentalShape.scaleX;
		accidentalShape.x = hInsertPos;
		accidentalShape.y = vStaffPos + (stepsFromTopStaffLine * (_scoreProps.staffLineSpacing / 2)) - 
							accidentalShape.height / 2 + vertOffset;
		vSystem.addChild(accidentalShape);
//		if (accidentalBD == MusicTextures.flat){
//			print('bdWidth=${accidentalBD.width} bdHeight=${accidentalBD.height} ' +
//					'asWidth=${accidentalShape.width} asHeight=${accidentalShape.height} ' +
//					'asScaleX=${accidentalShape.scaleX} asScaleY=${accidentalShape.scaleY} ' +
//					'asX=${accidentalShape.x} asY=${accidentalShape.y} ' +
//					'vOffset=$vertOffset vStaffPos=$vStaffPos');
//		}
	}

	void addAttachments(Measure cMeasure, num systemIndent, num vStaffPos, VisualSystem visualSystem) {
		num hOffset = systemIndent + cMeasure.stack.startPosition;

		//add the measure attachments
		List<MeasureAttachment> attachments = cMeasure.attachments;
		if (attachments != null){
			int numAttachments = attachments.length;
			for (int i = 0; i < numAttachments; i++){
				MeasureAttachment attachment = attachments[i];
				DisplayObject visualAttachment = null; //we check if this is null at the end, so we need to always set it to null first

				//if it's a dynamic...
				if (attachments[i] is Dynamic){
					Dynamic dynamicSymbol = attachments[i] as Dynamic;
					switch(dynamicSymbol.type){
						case DynamicType.F:
							visualAttachment = new Bitmap(MusicTextures.f);
							break;
						case DynamicType.FF:
							visualAttachment = new Bitmap(MusicTextures.ff);
							break;
						case DynamicType.FFF:
							visualAttachment = new Bitmap(MusicTextures.fff);
							break;
						case DynamicType.FFFF:
							visualAttachment = new Bitmap(MusicTextures.fff);
							break;
						case DynamicType.P:
							visualAttachment = new Bitmap(MusicTextures.p);
							break;
						case DynamicType.PP:
							visualAttachment = new Bitmap(MusicTextures.pp);
							break;
						case DynamicType.PPP:
							visualAttachment = new Bitmap(MusicTextures.ppp);
							break;
						case DynamicType.PPPP:
							visualAttachment = new Bitmap(MusicTextures.ppp);
							break;
						case DynamicType.MF:
							visualAttachment = new Bitmap(MusicTextures.mf);
							break;
						case DynamicType.MP:
							visualAttachment = new Bitmap(MusicTextures.mp);
							break;
						default:
							//print('here');
							//unknown dynamic
					}
				}

				//position and add the visualAttachment
				if (visualAttachment != null){
					//visualAttachment.scaleX = visualAttachment.scaleY = 0.4;
					
					//print ((attachment as Dynamic).type);
					//print(attachment.hPos);
					visualAttachment.x = attachment.hPos + hOffset;
					visualAttachment.y = attachment.vPos + vStaffPos;
					//print('${visualAttachment.x}  ${visualAttachment.y}  ${visualAttachment.bounds}');
					visualSystem.addChild(visualAttachment);
				}
			}
		}

	}

	/**
	 * draws the vertical barlines for the system - should only be called after all staves/parts have been added
	 */
	void renderVerticalBarlines(List<int> staffGroupings, num systemIndent,
			VisualSystem vSystem, num vStaffPos, List<MeasureStack> stacks,
			num systemWidth) {
		vSystem.graphics.beginPath();
		//draw the left barline if the system has more than one staff
		if (staffGroupings.length > 1 || (staffGroupings != null &&
				staffGroupings.length > 0 && staffGroupings[0] > 1)) {
			//this.graphics.moveTo(_measures[0].extraLeftSystemMargin, 0);
			vSystem.graphics.moveTo(systemIndent, 0);
			//this.graphics.lineTo(_measures[0].extraLeftSystemMargin, _currentVStaffPos + 4 * _scoreProps.staffLineSpacing);
			vSystem.graphics.lineTo(systemIndent, vStaffPos + 4 * _scoreProps.staffLineSpacing);
		}

		//draw the final barline
		if (stacks.last.next == null){
			//final barline of the piece
			//first draw the stroke for the beginning of system line since we don't want it drawn thick
			vSystem.graphics.strokeColor(0xFF000000, _scoreProps.lightBarlineWidth);
			vSystem.graphics.closePath();
			vSystem.graphics.beginPath();
			
			//draw the heavy end line
			vSystem.graphics.moveTo(systemWidth, 0);
			vSystem.graphics.lineTo(systemWidth, vStaffPos + 4 * _scoreProps.staffLineSpacing);
			vSystem.graphics.strokeColor(0xFF000000, _scoreProps.heavyBarlineWidth, JointStyle.ROUND, CapsStyle.NONE);

			//draw a light line before it
			vSystem.graphics.moveTo(systemWidth - _scoreProps.staffLineSpacing, 0);
			vSystem.graphics.lineTo(systemWidth - _scoreProps.staffLineSpacing, vStaffPos + 4 * _scoreProps.staffLineSpacing);
		}
		else {
			//final barline of system
			vSystem.graphics.moveTo(systemWidth, 0);
			vSystem.graphics.lineTo(systemWidth, vStaffPos + 4 * _scoreProps.staffLineSpacing);
			//vSystem.graphics.moveTo(_scoreProps.pageWidth - _scoreProps.leftPageMargin - _scoreProps.rightPageMargin, 0);
			//vSystem.graphics.lineTo(_scoreProps.pageWidth - _scoreProps.leftPageMargin - _scoreProps.rightPageMargin, vStaffPos + 4 * _scoreProps.staffLineSpacing);
		}

		//draw the barlines in the middle
		num vertStartPos = 0;
		for (var stavesInGroup in staffGroupings) {
			num vertEndPos = vertStartPos + ((stavesInGroup - 1) * (4 * _scoreProps.staffLineSpacing + _scoreProps.staffSpacing)) + (4 * _scoreProps.staffLineSpacing);
			//num horizPos = _measures[0].extraLeftSystemMargin;
			num horizPos = systemIndent;
			for (int i = 0; i < stacks.length - 1; i++) {
				//TEMP code - draw indent marks
				/*vSystem.graphics.lineStyle(1, 0x0000FF);
				vSystem.graphics.moveTo(horizPos + stacks[i].indent, vertStartPos);
				vSystem.graphics.lineTo(horizPos + stacks[i].indent, vertEndPos);
				vSystem.graphics.lineStyle(1, 0x000000);*/

				//draw the barlines
				horizPos += stacks[i].width;
				num clefOffset = (stacks[i + 1].newClef)? _scoreProps.clefWidth + _scoreProps.clefDistanceFromBarline : 0;
				vSystem.graphics.moveTo(horizPos + clefOffset, vertStartPos);
				vSystem.graphics.lineTo(horizPos + clefOffset, vertEndPos);
			}
			vertStartPos += stavesInGroup * (4 * _scoreProps.staffLineSpacing + _scoreProps.staffSpacing);
		}
		vSystem.graphics.strokeColor(0xFF000000, _scoreProps.lightBarlineWidth);
		vSystem.graphics.closePath();
	}
	
	void _drawRepeats(List<int> staffGroupings, num systemIndent, VisualSystem vSystem, num vStaffPos,
						List<MeasureStack> stacks){
		
		num vertStartPos = 0;
		num space = _scoreProps.staffLineSpacing;
		for (var stavesInGroup in staffGroupings) {
			num vertEndPos = vertStartPos + ((stavesInGroup - 1) * 
					(4 * space + _scoreProps.staffSpacing)) + 
					(4 * space);
			
			num horizPos = systemIndent;
			for (int i = 0; i < stacks.length; i++) {
				var stack = stacks[i];
				if (stack.repeatDOs != null){
					for (var rdo in stack.repeatDOs){
						num heavyPos;
						num lightPos;
						num dotsPos;
						//get the horiz position of the heavy and thin barlines and dots
						if (rdo.repeatDirection == RepeatDirection.FORWARD){
							heavyPos = horizPos - 2 * _scoreProps.measureLeadIn +
										((i == 0)? stack.indentAsSystemLeader : stack.indent);
							if (heavyPos > horizPos){
								//the stack indent positions for bars with repeats
								//are placed at 2 * measureLeadIn UNLESS the bar
								//contains extra stuff at the front that creates
								//a larger indent.
								heavyPos += space;
							}
							lightPos = heavyPos + space;
							dotsPos = lightPos + 0.5 * space;
						}
						else if (rdo.repeatDirection == RepeatDirection.BACKWARD){
							heavyPos = horizPos + stack.width;
							lightPos = heavyPos - space;
                            dotsPos = lightPos - 0.5 * space;
						}
						else if (rdo.endingType != null){
							//draw an ending bracket
							num leftPos = horizPos - _scoreProps.measureLeadIn + 
									((i == 0)? stack.indentAsSystemLeader : stack.indent);
							num rightPos = horizPos + stack.width;
							num vPos = rdo.endingVPos;
							vSystem.graphics.beginPath();
							vSystem.graphics.moveTo(leftPos, vPos);
							vSystem.graphics.lineTo(rightPos, vPos);
							
							if (rdo.endingType == EndingType.START){
								vSystem.graphics.moveTo(leftPos, vPos);
								vSystem.graphics.lineTo(leftPos, vPos + 1.5 * space);
								if (rdo.endingNumber != null){
									num textPos = leftPos + space;
									var tf = new TextField(rdo.endingNumber, 
												new TextFormat("arial", 12 * space / 12, 0));
									tf.x = textPos;
									tf.y = vPos + space / 4;
									vSystem.addChild(tf);
								}
							}
							else if (rdo.endingType == EndingType.STOP) {
								vSystem.graphics.moveTo(rightPos, vPos);
                               	vSystem.graphics.lineTo(rightPos, vPos + 1.5 * space);
							}
							vSystem.graphics.strokeColor(0xFF000000, _scoreProps.lightBarlineWidth);
						}
						if (heavyPos != null){
							//draw the barlines
							vSystem.graphics.beginPath();
							vSystem.graphics.moveTo(heavyPos, vertStartPos);
                            vSystem.graphics.lineTo(heavyPos, vertEndPos);
                            vSystem.graphics.strokeColor(0xFF000000, _scoreProps.heavyBarlineWidth, 
                            							JointStyle.ROUND, CapsStyle.NONE);
                            vSystem.graphics.closePath();
                            
                            vSystem.graphics.beginPath();
                            vSystem.graphics.moveTo(lightPos, vertStartPos);
                            vSystem.graphics.lineTo(lightPos, vertEndPos);
                            vSystem.graphics.strokeColor(0xFF000000, _scoreProps.lightBarlineWidth);
                            vSystem.graphics.closePath();
                            
                            //draw the dots
                            vSystem.graphics.beginPath();
                            for (int j = 0; j < stavesInGroup; j++){
                            	num vPos = vertStartPos + j * (4 * space + _scoreProps.staffSpacing);
                                vSystem.graphics.circle(dotsPos, vPos + 1.5 * space, space / 5);
                                vSystem.graphics.circle(dotsPos, vPos + 2.5 * space, space / 5);
                                vSystem.graphics.fillColor(0xFF000000);
                            }
                            vSystem.graphics.closePath();
						}
					}
				}
				horizPos += stacks[i].width;
			}
			vertStartPos += stavesInGroup * (4 * _scoreProps.staffLineSpacing + _scoreProps.staffSpacing);
		}
	}

	/**
	 * add the ties for the notes on the current staff
	 * @param	vngLists a list of lists of VisualNoteGroups (each voice is a list)
	 * @param	vStaffPos the offset from the top of the system that the current staff begins
	 */
	void drawTies(List<List<VisualNoteGroup>> vngLists, num vStaffPos, VisualSystem vSystem) {
		//each voice is a list of VisualNoteGroup objects
		//we'll look in each list (voice) at the VisualNoteGroup objects and inside their respective notes to check the tie states
		num noteheadWidth = _scoreProps.noteheadWidth;
		num tieStartOffset = 0.8 * noteheadWidth;
		num tieEndOffset = 0.3 * noteheadWidth;
		VisualNoteGroup nextVNG;
		for (int i = 0; i < vngLists.length; i++){
			List<VisualNoteGroup> vngList = vngLists[i];
			int numNotes = vngList.length;
			for (int j = 0; j < numNotes; j++) {
				VisualNoteGroup cVNG = vngList[j]; //current VisualNoteGroup
				if (cVNG.noteGroup.visible == false){
					continue;
				}
				for (var note in cVNG.noteGroup.notes) {
					if (note.visible == false){
						continue;
					}
					switch (note.tieState) {
						//for tie starts, we'll draw a tie either to the next note (if it's to the right on the same system), or just to the end of the system.
						case TieState.START:
							if (j < numNotes - 1) { //if the next note is to the right, draw the tie between the notes
								nextVNG = vngList[j + 1];
								var nextNote = nextVNG.noteGroup.notes.where((e)=>e.displayCents == note.displayCents);
								//drawTie(cVNG.x + (0.3 * cVNG.width), nextVNG.x, note.vPos + vStaffPos, vSystem, cVNG, note.vPos);
								if (nextVNG.noteGroup.visible && nextNote.length > 0 && nextNote.first.visible){
									drawTie(cVNG.x + note.hPos + tieStartOffset, nextVNG.x + tieEndOffset, 
												note.vPos + vStaffPos, vSystem, cVNG, note.vPos);
								}
							}
							else { //otherwise draw it to the end of the system
								//drawTie(cVNG.x, vSystem.systemRef.systemWidth, note.vPos + vStaffPos, vSystem, cVNG, note.vPos);
								drawTie(cVNG.x + note.hPos + tieStartOffset, vSystem.systemRef.systemWidth, 
													note.vPos + vStaffPos, vSystem, cVNG, note.vPos);
							}
							break;
						//for tie continues, we'll draw the forward tie with the same conditions as a START tie, but we also have to draw a backwards tie IF it's the first note on a system
						case TieState.CONTINUE:
							if (j < numNotes - 1) { //if the next note is to the right, draw the tie between the notes
								nextVNG = vngList[j + 1];
								var nextNote = nextVNG.noteGroup.notes.where((e)=>e.pitchName == note.pitchName);
								//drawTie(cVNG.x + (0.8 * cVNG.width), nextVNG.x, note.vPos + vStaffPos, vSystem, cVNG, note.vPos);
								if (nextVNG.noteGroup.visible && nextNote.length > 0 && nextNote.first.visible){
									drawTie(cVNG.x + note.hPos + tieStartOffset, nextVNG.x + tieEndOffset, 
											note.vPos + vStaffPos, vSystem, cVNG, note.vPos);
								}

								if (j == 0){ //if this is the first note on the system...
									//draw a tie back towards the beginning of the system
									drawTie(cVNG.x - 20, cVNG.x + tieEndOffset, note.vPos + vStaffPos, vSystem, cVNG, note.vPos);
								}
							}
							else { //otherwise draw it to the end of the system
								drawTie(cVNG.x + tieStartOffset, vSystem.systemRef.systemWidth, 
										note.vPos + vStaffPos, vSystem, cVNG, note.vPos);

								//and then draw a tie back towards the beginning of the system, since this is the first note on a new system
								//drawTie(cVNG.x - 20, cVNG.x, note.vPos + vStaffPos, cVNG.systemRef, cVNG, note.vPos);
							}
							break;
						//for tie stops, we only have to draw the tie if it's the first note on the system (drawn as a backwards tie)
						case TieState.STOP:
							if (j == 0) {
								drawTie(cVNG.x - 20, cVNG.x + tieEndOffset, note.vPos + vStaffPos, vSystem, cVNG, note.vPos);
							}
							break;
						default:
							//no tie to draw
					}
				}
			}
		}

		
	}
	
	void drawTie(num x1Val, num x2Val, num yVal, VisualSystem vSystem, VisualNoteGroup vng, num vPosInStaff) {
		bool curveDown = false;
		if (vng.noteGroup.stemDirection == StemDirection.UP ||
				(vng.noteGroup.stemDirection == StemDirection.NO_STEM && vPosInStaff > _scoreProps.staffLineSpacing * 3)) {
			curveDown = true;
		}

		Shape tieShape = new Shape();
		tieShape.graphics.beginPath();
		var yControl = (curveDown)? 7 : -7;
		var length = x2Val - x1Val;
		tieShape.graphics.moveTo(0, 0);
		tieShape.graphics.bezierCurveTo(length / 3, yControl, 2 * length / 3, yControl, length, 0);
		tieShape.graphics.moveTo(0, 0);
        tieShape.graphics.bezierCurveTo(length / 3, yControl - 1, 2 * length / 3, yControl - 1, length, 0);
		tieShape.graphics.moveTo(0, 0);
		tieShape.graphics.bezierCurveTo(length / 3, yControl - 2, 2 * length / 3, yControl - 2, length, 0);
		tieShape.graphics.strokeColor(0xFF000000, 1);
//		tieShape.graphics.quadraticCurveTo((x2Val - x1Val) / 2, (curveDown)? 7 : -7, (x2Val - x1Val), 0);
//		tieShape.graphics.strokeColor(0xFF000000, 2);
		tieShape.graphics.closePath();
		
		tieShape.x = (curveDown)? x1Val - 1 : x1Val - 0;
		tieShape.y = (curveDown)? yVal + 6 : yVal - 6;
		
		vSystem.addChild(tieShape);
		vng.visualAttachments.add(tieShape);
	}

	void drawSlurs(System system, VisualSystem vSystem, List<Part> parts) {
		if (system.slurSegments == null) {
			return;
		}
		vSystem.graphics.beginPath();
		for (var segment in system.slurSegments){
			if (parts.indexOf(segment.slur.firstNote.voice.measure.staff.partRef) == -1) {
				continue; //don't draw slurs that aren't in the rendered parts.
			}
			if (segment.slur.firstNote.visible == false || segment.slur.endNote.visible == false){
				continue; //don't draw slurs for invisible notes
			}
			var points = segment.points;
			vSystem.graphics.moveTo(points[0].x, points[0].y);
			vSystem.graphics.bezierCurveTo(points[1].x, points[1].y, points[2].x, points[2].y, points[3].x, points[3].y);
			vSystem.graphics.moveTo(points[0].x, points[0].y);
            vSystem.graphics.bezierCurveTo(points[1].x, points[1].y - 1, points[2].x, points[2].y - 1, points[3].x, points[3].y);
			vSystem.graphics.moveTo(points[0].x, points[0].y);
			vSystem.graphics.bezierCurveTo(points[1].x, points[1].y - 2, points[2].x, points[2].y - 2, points[3].x, points[3].y);
			//print('p1: ${points[1].y}, p2: ${points[2].y}');
		}
		vSystem.graphics.strokeColor(0xFF000000, 1);
		vSystem.graphics.closePath();
	}


	/**
	 * These are the VisualNoteGroup objects from the previous render session. They are re-used when possible.
	 */
	List<VisualNoteGroup> get legacyVNoteGroups { return _legacyVNoteGroups; }
	void set legacyVNoteGroups(List<VisualNoteGroup> value) {
		_legacyVNoteGroups = value;
		_legacyVNGIndex = 0;
	}
}

