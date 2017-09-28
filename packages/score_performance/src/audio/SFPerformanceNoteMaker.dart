part of score_performance.audio;

class SFPerformanceNoteMaker {
	
	SequenceBuilder _sequenceBuilder;
	SFLoader _sfLoader;
	
	num _tempoRatio;
	List<SampleTimeStampDO> _sampleTimeStamps;
	
	List<num> _beats; //qNote positions of the beats in the playback region
	List<num> _countoffBeats; //qNote positions of the beats in the countoff
	
	static const num COMPOUND_METER_TEMPO_CUTOFF = 80; //at this tempo, beats and clicks will be sent once every 3 in compound meters instead of each beat
	num _qNotesPerCountoffBeat; //the duration of each countoff beat, in qNotes
	
	SFPerformanceNoteMaker(SFLoader sfLoader){
		_sfLoader = sfLoader;
		_init();
	}
	
	/**
	 * creates playback notes for all notes in the passed in list of Parts
	 * @param parts the Parts that contain the notes you want played
	 * @param tempoRatio the ratio of the tempo to the default tempo of the piece
	 * @param playSoundFontNotes if true, notes will be played
	 * @param metronomeVolume from 0 to 1.0
	 * @param startNG the NoteGroup with the qNoteTime where playback should begin
	 * @param endQNoteTime the time when playback should stop. Notes that start at this time will not be played.
	 * @param numCountoffBeats the number of countoff beats that should be played
	 * @param playbackPath the order playback should follow through the score - this should not
	 * take into account the startNG or endQNoteTime, but rather cover the entire piece. See Score.playbackPath.
	 * Values are presented as pairs of startQNoteTimes (inclusive) and stopQNoteTimes (exclusive). The
	 * startNG and endQNoteTime will override. If you pass in null for the playbackPath, a path from beginning
	 * to end will be inferred.
	 */
	void addNotesInParts(List<Part> parts, [num tempoRatio = 1.0, bool playSoundFontNotes = true,
							num metronomeVolume = 0, NoteGroup startNG = null, num endQNoteTime = null,
							int numCountoffBeats = 0, List<num> playbackPath = null]) {
		
		_sequenceBuilder.clearSequence();
		
		_tempoRatio = tempoRatio;
		
		var measures = parts[0].staves[0].measures;
		
		if (startNG == null){ startNG = measures[0].voices[0].noteGroups[0]; }
		num startQNoteTime = _getNoteOrStackTime(startNG);
		if (endQNoteTime == null) { endQNoteTime = measures.last.stack.endTime; }
		
		//get the list of PlaybackRegions
		var regions = _getPlaybackRegions(startQNoteTime, endQNoteTime, playbackPath, measures);
		
		//get all of the tempo markers in the piece - (this will create ones at the beginning and end if they don't exist)
		List<TempoMarker> tempoMarkers = _getTempoMarkers(measures);
		
		//calculate actual playback qNoteStartTime, including countoff. This can be negative (if the countoff happens near/at beginning)
		num startNGMarkerTempo = _getMostRecentTempoMarker(tempoMarkers, startQNoteTime).tempo; //tempo at startNG - without tempoRatio calc
		num realStartQNoteTime = _calculateQNoteStartTime(startQNoteTime,
			startNG.voice.measure, startNGMarkerTempo * _tempoRatio, numCountoffBeats);
		

		//create the SampleTimeStampDO objects
		_sampleTimeStamps = _createSampleTimeStamps(realStartQNoteTime, startNGMarkerTempo, tempoMarkers, regions);
		

		//Create the Playback Notes
		_createPlaybackNotes(parts, playSoundFontNotes, regions);
		


		//create metronome beats
		_createMetronomeBeats(parts, metronomeVolume, regions);
		
		
		//create countoff clicks
		_createCountoffClicks(numCountoffBeats, startNGMarkerTempo, realStartQNoteTime);
		
	}
	
	
	void _init(){
		_sequenceBuilder = new SequenceBuilder();
	}

	///returns either the qNoteTime of the NoteGroup or the Stack it lies in,
	///whichever is greater (protection against grace notes)
	num _getNoteOrStackTime(NoteGroup ng){
		num stackTime = ng.voice.measure.stack.startTime;
		return (ng.qNoteTime > stackTime)? ng.qNoteTime : stackTime;
	}
	
	List<PlaybackRegion> _getPlaybackRegions(num startQNoteTime, num endQNoteTime, List<num> playbackPath,
											List<Measure> measures){
		
		if (playbackPath == null || playbackPath.length % 2 != 0){
			return [new PlaybackRegion(startQNoteTime, endQNoteTime)];
		}
		
		NoteGroup _getNoteGroupAtTime(num qNoteTime){
			for (int i = measures.length - 1; i >= 0; i--){
				if (measures[i].stack.startTime <= qNoteTime){
					return measures[i].voices[0].noteGroups[0];
				}
			}
			return measures[0].voices[0].noteGroups[0];
		}
		
		List<PlaybackRegion> regions = [];
		bool beginningFound = false;
		int latestEndRegionIndex;
		for (int i = 0; i < playbackPath.length - 1; i += 2){
			//make note of the first region that contains the startNG
			if (!beginningFound && playbackPath[i] <= startQNoteTime &&
					playbackPath[i+1] > startQNoteTime){
				beginningFound = true;
			}
			if (beginningFound){
				//we only start adding regions after finding the beginning region
				//make note of the last region that contains the endQNoteTime
				if (playbackPath[i] < endQNoteTime && playbackPath[i+1] >= endQNoteTime){
					//regions.length is correct, because we add the new region after
					latestEndRegionIndex = regions.length; 
				}
				
				if (regions.length == 0){
					//for the first region that contains the startNG, the startNG is the start point
					regions.add(new PlaybackRegion(startQNoteTime, playbackPath[i+1]));
				}
				else {
					//we begin creating the remaining regions after the start region is found
					//and the first region was already created
					var ng = _getNoteGroupAtTime(playbackPath[i]);
	             	regions.add(new PlaybackRegion(_getNoteOrStackTime(ng),
		                playbackPath[i+1]));
				}
			}
			
		}
		
		
		if (beginningFound && latestEndRegionIndex != null){
			//now change the end point of the last region containing the endQNoteTime and 
			//eliminate any regions that follow it.
			regions[latestEndRegionIndex].qNoteEndTime = endQNoteTime;
			regions = regions.sublist(0, latestEndRegionIndex + 1);
			return regions;
		}
		else {
			//something went wrong - we didn't find either the start or the end point
			return [new PlaybackRegion(startQNoteTime, endQNoteTime)];
		}
		
	}
	
	List<TempoMarker> _getTempoMarkers(List<Measure> measures){
		int numMeasures = measures.length;
		var firstStack = measures[0].stack;
		if (firstStack.tempoMarkers == null || firstStack.tempoMarkers.length == 0 || 
				firstStack.tempoMarkers[0].qNoteTime > 0) {
			var tempoMarker = new TempoMarker();
			tempoMarker.tempo = ScoreProperties.DEFAULT_TEMPO;
			tempoMarker.qNoteTime = 0;
			firstStack.tempoMarkers = [tempoMarker];
		}
		var lastStack = measures[numMeasures - 1].stack;
		if (lastStack.tempoMarkers == null || lastStack.tempoMarkers.length == 0 ||
				lastStack.tempoMarkers[lastStack.tempoMarkers.length - 1].qNoteTime < lastStack.endTime) {
			if (lastStack.tempoMarkers == null){
				lastStack.tempoMarkers = [];
			}
			var tempoMarker = new TempoMarker();
			tempoMarker.tempo = 120;
			tempoMarker.qNoteTime = lastStack.endTime;
			lastStack.tempoMarkers.add(tempoMarker);
		}
		
		List<TempoMarker> markers = [];
		
		for (int i = 0; i < numMeasures; i++){
			var cStack = measures[i].stack;
			if (cStack.tempoMarkers != null){
				for (var tempoMarker in cStack.tempoMarkers){
					markers.add(tempoMarker);
				}
			}
		}
		
		return markers;
	}
	
	TempoMarker _getMostRecentTempoMarker(List<TempoMarker> markers, num qNoteTime){
		for (int tmIndex = markers.length - 1; tmIndex >= 0; tmIndex--){
			if (markers[tmIndex].qNoteTime <= qNoteTime){
				return markers[tmIndex];
			}
		}
		return markers[0];
	}
	
	num _calculateQNoteStartTime(num startQNoteTime, Measure startMeasure,
				num actualCountoffTempo, int numCountoffBeats){
		//num startQNoteTime = startNG.qNoteTime;
		
		//calculate the QNote duration of the countoff and use it to adjust the start qnote time
		//var startMeasure = startNG.voice.measure;
		int beatType = startMeasure.beatType;
		//actualCountoffTempo includes tempo ratio calculation
      	if (beatType % 8 == 0 && actualCountoffTempo >= COMPOUND_METER_TEMPO_CUTOFF) {
      		//compound meter - counting 1 beat for every 3
      		_qNotesPerCountoffBeat = 3 * (4 / beatType);
      	}
      	else {
      		_qNotesPerCountoffBeat = 4 / beatType;
      	}
      	
      	//////////////////////
      	//calculate how far the startNG is off the main beat (in case it acts like a pickup note)
      	//imagine a startNG 16th note on qNote 2.75 in 4/4 time, with the barline at 4.0. 
      	//The distance to the bar is 1.25 (ex. 1/16 1/4 | 1/4 1/4 1/4 1/4)
      	num barEndTime = startMeasure.stack.endTime;
      	num distToBar = barEndTime - startQNoteTime;
      	num distToNearestBeat = distToBar;
      	while(distToNearestBeat >= _qNotesPerCountoffBeat){ //if startNG is on a beat, distToNearestBeat will become 0
      		distToNearestBeat -= _qNotesPerCountoffBeat;
      		//brings us down to 0.25
      	}
      	//the distToNearestBeat has now become the distance from the start note to the next beat.
      	//therefore, the countoff beat which happens prior to this is 1 - distToNearestBeat before the 
      	//start note. We shorten our countoff by this amount so that the countoff beats are in time
      	//with the beat of the starting measure, NOT the timing of the first note (which is off beat)
      	num adjustedCountoffBeats = numCountoffBeats - distToNearestBeat;
      	/////////////////////
      	
      	startQNoteTime -= adjustedCountoffBeats * _qNotesPerCountoffBeat;
      	
      	return startQNoteTime;
	}
	
	List<SampleTimeStampDO> _createSampleTimeStamps(num startQNoteTime, num startNGMarkerTempo, 
    									List<TempoMarker> tempoMarkers, List<PlaybackRegion> regions){
		List<SampleTimeStampDO> sampleTimeStamps = [];
        
		//create the initial sampleTimeStampDO - 
		//the first is at 0 samples and the startQNoteTime (start of countoff, not startNote)
		SampleTimeStampDO timeStamp = new SampleTimeStampDO(0, startQNoteTime);
		timeStamp.msTime = 0;
		timeStamp.tempo = startNGMarkerTempo * _tempoRatio;
		sampleTimeStamps.add(timeStamp);
		
		//now go through the regions and tempo markers and create playback time stamps
		int lastStampSampleTime = timeStamp.sampleTime;
		num lastStampQNoteTime = timeStamp.qNoteTime;
		num cSampleToQNoteRatio = 44100 / (timeStamp.tempo / 60);
		
		for (int regionIndex = 0; regionIndex < regions.length; regionIndex++){
			var region = regions[regionIndex];
			int tmIndex;
			TempoMarker tm;
			for (tmIndex = tempoMarkers.length - 1; tmIndex >= 0; tmIndex--){
				if (tempoMarkers[tmIndex].qNoteTime <= region.qNoteStartTime){
					tm = tempoMarkers[tmIndex];
					break; //found TM for beginning tempo of region
				}
			}
			
			//create the first time stamp for the new region
			num qNoteDelta;
			if (regionIndex > 0){
				//for regions after the first region, we calculate a qNoteDelta from the time of the
				//last tempo marker in the previous region to the end of the previous region. This is
				//because the start qNoteTime of the new region is not necessarily directly after the
				//finish of the previous region (because of repeat jumping, etc.). We need this delta
				//value to calculate the sample position for the beginning of the new region
				var lastRegion = regions[regionIndex - 1];
				qNoteDelta = lastRegion.qNoteEndTime - lastStampQNoteTime;
			}
			else {
				//the qNoteDelta for the first region is just the difference from the beginning of the
				//playback (including countoff if present) to the start qNoteTime of the first region
				qNoteDelta = region.qNoteStartTime - sampleTimeStamps[0].qNoteTime;
			}
			var prevStamp = sampleTimeStamps.last;
			prevStamp.qNoteEndTime = prevStamp.qNoteTime + qNoteDelta;
			
			int sampleTime = lastStampSampleTime + (cSampleToQNoteRatio * qNoteDelta).toInt();
			timeStamp = new SampleTimeStampDO(sampleTime, region.qNoteStartTime);
			timeStamp.msTime = sampleTime ~/ 44.1;
			timeStamp.tempo = tm.tempo * _tempoRatio;
			cSampleToQNoteRatio = 44100 / (timeStamp.tempo / 60);
			
			prevStamp.nextSampleTimeStampDO = timeStamp;
			
			sampleTimeStamps.add(timeStamp);
			region.timeStamps = [timeStamp];
			
			lastStampQNoteTime = timeStamp.qNoteTime;
            lastStampSampleTime = timeStamp.sampleTime;
            
            //now create additional time stamps for any tempo marker within the region
            tmIndex++;
            while (tmIndex < tempoMarkers.length && tempoMarkers[tmIndex].qNoteTime < region.qNoteEndTime){
            	tm = tempoMarkers[tmIndex];
            	//var lastRegion = regions[regionIndex - 1];
                //qNoteDelta = lastRegion.qNoteEndTime - lastStampQNoteTime;
            	qNoteDelta = tm.qNoteTime - lastStampQNoteTime;
            	
            	var prevStamp = sampleTimeStamps.last;
                prevStamp.qNoteEndTime = prevStamp.qNoteTime + qNoteDelta;
                
                sampleTime = lastStampSampleTime + (cSampleToQNoteRatio * qNoteDelta).toInt();
    			//timeStamp = new SampleTimeStampDO(sampleTime, region.qNoteStartTime);
                timeStamp = new SampleTimeStampDO(sampleTime, tm.qNoteTime);
    			timeStamp.msTime = sampleTime ~/ 44.1;
    			timeStamp.tempo = tm.tempo * _tempoRatio;
    			cSampleToQNoteRatio = 44100 / (timeStamp.tempo / 60);
    			
    			prevStamp.nextSampleTimeStampDO = timeStamp;
    			
    			sampleTimeStamps.add(timeStamp);
    			region.timeStamps.add(timeStamp);
    			
    			lastStampQNoteTime = timeStamp.qNoteTime;
                lastStampSampleTime = timeStamp.sampleTime;
                
                tmIndex++;
            }
		}
		
		if (sampleTimeStamps.last.qNoteTime < regions.last.qNoteEndTime){
			//make sure there's a time stamp at the very end
			var prevTS = sampleTimeStamps.last;
			num endQNoteTime = regions.last.qNoteEndTime;
			num qNoteDelta = endQNoteTime - prevTS.qNoteTime;
			prevTS.qNoteEndTime = prevTS.qNoteTime + qNoteDelta;
			cSampleToQNoteRatio = 44100 / (prevTS.tempo / 60);
			int sampleTime = prevTS.sampleTime + (cSampleToQNoteRatio * qNoteDelta).toInt();
			var finalTS = new SampleTimeStampDO(sampleTime, endQNoteTime);
			finalTS.msTime = sampleTime ~/ 44.1;
			finalTS.tempo = prevTS.tempo;
			finalTS.qNoteEndTime = finalTS.qNoteTime;
			prevTS.nextSampleTimeStampDO = finalTS;
			sampleTimeStamps.add(finalTS);
		}
		
		//we could do a check here to guard against the first and second time stamps being identical. This
		//could happen if there is no countoff. Alternatively, we could eliminate the second time stamp
		//regardless, because its tempo should match the first time stamp's tempo. But it might be useful
		//to have a time stamp aligned with the first region's startQNoteTime
		
		return sampleTimeStamps;
	}
	
	SampleTimeStampDO _getTimeStamp(num qNoteTime, List<SampleTimeStampDO> timeStamps) {
		int numStamps = timeStamps.length;
		for (int tsIndex = numStamps - 1; tsIndex >= 0; tsIndex--){
			if (timeStamps[tsIndex].qNoteTime <= qNoteTime){
				return timeStamps[tsIndex];
			}
		}
		return _sampleTimeStamps[0];
	}
	
	void _createPlaybackNotes(List<Part> parts, bool playSoundFontNotes, List<PlaybackRegion> regions){
		SampleTimeStampDO timeStamp;
		//int numStamps = _sampleTimeStamps.length;
		
		for (var part in parts){
			_sequenceBuilder.preset = (part.midiChannel % 16 != 10)? _sfLoader.getPreset(part.midiPreset, 0) : _sfLoader.getPreset(0, 128);

			//build the notes
			var noteGroups = part.noteGroups;
			int numNoteGroups = noteGroups.length;

			//variables for tracking dynamics
			//var partVol:Number = Math.min(1 / parts.length, 0.15); //base volume of the part - dynamics can't exceed this
			num pan = part.pan;
			num partVol = part.volume;
			Measure cMeasure;
			num measureStartDynamic = partVol * 0.4; //current dynamic at beginning of current measure (some dynamic's ratio X partVol)
			
			for (var region in regions){
				var startQNoteTime = region.qNoteStartTime;
				var endQNoteTime = region.qNoteEndTime;
				for (int i = 0; i < numNoteGroups; i++){
					var ng = noteGroups[i];
					
					if (ng.qNoteTime >= endQNoteTime){
						continue; //EXPERIMENT - break not safe, because ng's not in order with multi-staff parts
						//break; //this should work here, right?
					}
					
					var notes = ng.notes;
					int numNotes = notes.length;
					timeStamp = _getTimeStamp(ng.qNoteTime, region.timeStamps);
					//var startTime:int = ng.qNoteTime * 22050;
					int startTime = timeStamp.sampleTime + ((ng.qNoteTime - timeStamp.qNoteTime) * (60 / timeStamp.tempo) * 44100).toInt();
					if (startTime < 0){ //beware of grace notes at the beginning of the piece
						startTime = 0;
					}
					ng.playbackStartTime = startTime;
					ng.playbackTempo = timeStamp.tempo;
					if (part.muted || !playSoundFontNotes){
						continue;
					}
					//trace(ng.playbackStartTime, ng.playbackTempo);
					
					num ngQnDur = (ng.qNoteTime + ng.qNoteDuration <= endQNoteTime)? 
											ng.qNoteDuration : endQNoteTime - ng.qNoteTime;
					//int duration = (!ng.isGrace)? (ng.qNoteDuration * ((60 / timeStamp.tempo) * 44100)).toInt() : (0.125 * 22050).toInt();
					int duration = (!ng.isGrace)? (ngQnDur * ((60 / timeStamp.tempo) * 44100)).toInt() : (0.125 * 22050).toInt();
					int tieDuration = 0;
					for (int j = 0; j < numNotes; j++){
						var note = notes[j];
	
						//check for ties - we'll increase our duration of the first note if we find them
						if (note.tieState != TieState.NONE){
							if (note.tieState == TieState.START){
								int tempIndex = i + 1;
								bool tieEndFound = false;
								tieDuration = 0;
								while (!tieEndFound && tempIndex < numNoteGroups){
									var nextNG = noteGroups[tempIndex];
									var nextNoteTimeStamp = _getTimeStamp(nextNG.qNoteTime, region.timeStamps);
									if (nextNG.voice.number == ng.voice.number){
										var nextNGsNotes = nextNG.notes;
										bool tieTargetFound = false;
										for (var nextNote in nextNGsNotes){
											if (nextNote.displayCents == note.displayCents){
												if (nextNote.tieState == TieState.STOP){
													tieTargetFound = true;
													tieEndFound = true;
													tieDuration +=  (nextNG.qNoteDuration * ((60 / nextNoteTimeStamp.tempo) * 44100)).toInt();
													break;
												}
												else if (nextNote.tieState == TieState.CONTINUE){
													tieTargetFound = true;
													tieDuration +=  (nextNG.qNoteDuration * ((60 / nextNoteTimeStamp.tempo) * 44100)).toInt();
													break;
												}
											}
										}
										if (!tieTargetFound){ //safety check - if for some reason the next note didn't have a matching note to tie to, quit.
											break;
										}
									}
									else {
										//do nothing - this note must have been in a different voice
									}
									tempIndex++;
								}
							}
							else {
								continue; //if this continues or ends a tie, it doesn't get a new note
							}
						}
	
						//get the dynamic level - we keep track of the dynamic level at the start of each measure and update this value when we
						//come to each new measure by looking for any dynamics in the previous measure. To find the dynamic level of a note,
						//we start with this measureStartDynamic as our base line and then look through the measure for any dynamics placed
						//before or on our ng
	
						var measure = ng.voice.measure;
						if (cMeasure != measure){
							if (cMeasure != null){
								//set the starting dynamic for this new measure to be where we left off at the end of the previous measure
								for (var attachment in cMeasure.attachments){
									if (attachment is Dynamic){
										measureStartDynamic = (attachment as Dynamic).volume * partVol;
									}
								}
							}
							cMeasure = measure;
						}
	
						//look for any dynamics in this measure before the NG which would override
						num noteVolume = measureStartDynamic;
						for (var attachment in measure.attachments){
							if (attachment.qNoteTime <= ng.qNoteTime && attachment is Dynamic){
								noteVolume = (attachment as Dynamic).volume * partVol;
							}
						}
	
	
						//make sure this note is in the playback range - we do this check here in order to keep track
						//of the dynamic level
						//if (ng.qNoteTime < startNG.qNoteTime || ng.qNoteTime >= endQNoteTime){
						if (ng.qNoteTime < startQNoteTime){
	    					continue;
	    				}
						
						//add the note
						if (note.playbackCents <= 0) {
							int pitch = (note.displayCents ~/ 100) -
								part.chromaticTransposition +
								12 * part.playbackOctaveDelta;
							_sequenceBuilder.addNoteToSequence(pitch, startTime,
								duration + tieDuration, noteVolume, pan);
						}
						else { //playbackCents override pitch (used for non-pitched percussion)
							//print('index: ' + i.toString() + '  playbackCents: ' + note.playbackCents.toString());
							_sequenceBuilder.addNoteToSequence(note.playbackCents ~/ 100, startTime,
																duration + tieDuration, noteVolume, pan);
						}
					}
				}
			}
		}
	}
	
	void _createMetronomeBeats(List<Part> parts, num metronomeVolume, List<PlaybackRegion> regions){
		_beats = [];
		//int numStamps = _sampleTimeStamps.length;
		_sequenceBuilder.preset = _sfLoader.getPreset(0, 128); //choose the drums preset
		var measures = parts[0].staves[0].measures;
		num beatQNoteTime = 0;
		int beatSampleTime = 0;
		for (var region in regions){
			var startQNoteTime = region.qNoteStartTime;
			var endQNoteTime = region.qNoteEndTime;
			for (var measure in measures) {
				if (measure.stack.isPickup) {
					//fast forward to the end of the pickup measure to start our metronome clicks
					beatQNoteTime = measure.stack.endTime;
					
					//add beat entries for any complete beats within the pickup measure
					num pickupBeatTime = beatQNoteTime;
					num pickupBeatDuration = (measure.beatGroups.length > 1)? measure.beatGroups[1] - measure.beatGroups[0] : 
																					measure.stack.endTime;
					
					while (pickupBeatTime - pickupBeatDuration >= 0) {
						pickupBeatTime -= pickupBeatDuration;
						if (pickupBeatTime >= startQNoteTime && pickupBeatTime < endQNoteTime){
							_beats.insert(0, pickupBeatTime);
						}
					}
					continue;
				}
				beatQNoteTime = measure.stack.startTime; //EXPERIMENTAL
				int numBeats = measure.numBeats;
				int beatType = measure.beatType;
				for (int i = 0; i < numBeats; i++) {
					if (beatQNoteTime >= startQNoteTime && beatQNoteTime < endQNoteTime){
						var timeStamp = _getTimeStamp(beatQNoteTime, region.timeStamps);
						if (beatType % 8 != 0 || i % 3 == 0 || timeStamp.tempo < COMPOUND_METER_TEMPO_CUTOFF) {
							_beats.add(beatQNoteTime);
							int metronomeNote;
							num actualMetVolume;
							if (beatQNoteTime != measure.stack.startTime) {
								metronomeNote = 37;
								actualMetVolume = metronomeVolume * 0.8;
							}
							else {
								metronomeNote = 33;
								actualMetVolume = metronomeVolume;
							}
							
							//timeStamp = _getTimeStamp(beatQNoteTime, numStamps);
							beatSampleTime = timeStamp.sampleTime + ((beatQNoteTime - timeStamp.qNoteTime) * (60 / timeStamp.tempo) * 44100).toInt();
							//make sure this beat is in the playback range
							if (beatQNoteTime < startQNoteTime || beatQNoteTime >= endQNoteTime){
		  						continue;
		  					}
							_sequenceBuilder.addNoteToSequence(metronomeNote, beatSampleTime, 5512, actualMetVolume, 0.5);
						}
					}
					beatQNoteTime += 4 / beatType;
				}
			}
		}
	}
	
	void _createCountoffClicks(int numCountoffBeats, num startNGMarkerTempo, num startQNoteTime){
		_sequenceBuilder.preset = _sfLoader.getPreset(0, 128); //choose the drums preset
		num remainingClicks = numCountoffBeats;
		int clickPos = 0; //in samples
		num cSampleToQNoteRatio = 44100 / (startNGMarkerTempo * _tempoRatio / 60);
		_countoffBeats = [];
		num qNoteTime = startQNoteTime;
		while (remainingClicks > 0){
			_sequenceBuilder.addNoteToSequence(37, clickPos, 5512, 0.8, 0.5);
			clickPos += (_qNotesPerCountoffBeat * cSampleToQNoteRatio).toInt();
			remainingClicks -= 1;
			
			//keep track of the positions of each countoff beat (for visualization later)
			_countoffBeats.add(qNoteTime);
			qNoteTime += _qNotesPerCountoffBeat;
		}
	}
	
	/**
	 * the notes to be performed - give these to the player/performer object
	 */
	List<PerformanceNoteDO> get performanceNotes { return _sequenceBuilder.sequence; }
	
	List<SampleTimeStampDO> get sampleTimeStamps { return _sampleTimeStamps.toList(growable: false); }
	
	/**
	 * gets the qNote positions of the beats in the playback region (from startNG to endNG)
	 */
	List<num> get beatQNotePositions => _beats;
	
	/**
	 * gets the qNote positions of the beats in the countoff
	 */
	List<num> get countoffBeatQNotePositions => _countoffBeats;

}

class PlaybackRegion {
	//NoteGroup startNG;
	num qNoteStartTime;
	num qNoteEndTime;
	List<SampleTimeStampDO> timeStamps;

	PlaybackRegion(num qNoteStartTime, num qNoteEndTime){
		//this.startNG = startNG;
		this.qNoteStartTime = qNoteStartTime;
		this.qNoteEndTime = qNoteEndTime;
	}
}

