part of score_data.formatting;

class MusicBeamer {
	
	int successCount = 0;
	
	MusicBeamer() {
		
	}
	
	/**
	 * sets beam state for each NoteGroup in the system - it does not set the height or direction of stems
	 * @param	system the System to process
	 */
	void getSystemBeamGroupings(System system) {
		List<MeasureStack> stacks = system.measureStacks;
		for (var stack in stacks) {
			List<Measure> measures = stack.measures;
			for (var measure in measures) {
				getMeasureBeamGroupings(measure);
			}
		}
	}
	
	/**
	 * sets beam state for each NoteGroup in the measure - it does not set the height or direction of stems
	 * @param	measure the Measure to process
	 */
	void getMeasureBeamGroupings(Measure measure) {
		//List<int> codeHits = [0,0,0,0,0,0,0,0,0,0,0,0,0,0];
		
		//String debugOutput = "";
		for (var voice in measure.voices) {
			List<NoteGroup> noteGroups = voice.noteGroups;

			//we'll only consider notes (not rests). Our loop will start by populating noteGroup2 and then move on until a second note is found, in 
			//which case ng2 will be swapped to ng1 and we'll process the beaming requirements for the two notes
			NoteGroup ng1 = null;
			NoteGroup ng2 = null;
			
			//every time we start a new primary beam, we'll keep track of the starter note's time. This is used for determining beamlet directions.
			//we store this information in an array with indexes that match the beam level
			//List<num> currentBeamStartTimes = [];
			Map<int, num> currentBeamStartTimes = new Map<int, num>();
			
			for (var cng in noteGroups) {
				//clear any existing beams
				cng.beamStates = new List<String>(cng.maxBeams);
				for (int i = 0; i < cng.beamStates.length; i++){
					cng.beamStates[i] = BeamState.NONE;
				}
				
				if (cng.maxBeams <= 0) {
					//if it's a quarter note or larger, skip this note and clear out the existing notes since we have to start over
					ng1 = null;
					ng2 = null;
					continue;
				}
				else if (cng.isRest) {
					//if it's a rest, we skip it
					continue;
				}
				
				//swap our leading note (ng2) into the trailing note (ng1) and place the new leading note in ng2
				ng1 = ng2;
				ng2 = cng;
				
				if (ng1 == null) {
					continue; //if this was the first eighth or smaller duration note in the measure, ng1 will still be null. Continue on, as there's nothing to beam yet.
				}
				
				if ((ng1.isGrace && !ng2.isGrace) || (!ng1.isGrace && ng2.isGrace)) {
					continue; //grace notes can't be beamed to anything except grace notes
				}
				
				
				//figure out if the end time of ng1 falls in the same beat group as the start of ng2 - they must belong to the same beat group in this manner in order to be beamed.
				int numBeatGroups = measure.beatGroups.length;
				
				//beat groups and note start times (relative to the measure start) both start from 0
				//num ng1EndTime = double.parse(ng1.qNoteTime.toStringAsFixed(4)) - double.parse(measure.stack.startTime.toStringAsFixed(4)) + double.parse(ng1.qNoteDuration.toStringAsFixed(4)) - 0.001; // we subtract a small amount to kill tuplet rounding errors in dpq calculation
				//ng1EndTime = double.parse(ng1EndTime.toStringAsFixed(4));
				num ng1EndTime = ng1.qNoteTime - measure.stack.startTime + (ng1.qNoteDuration) - 0.001;
				//print("ng1EndTime: " + ng1EndTime.toString());
				int beatGroupIndex = 0;
				
				while ((beatGroupIndex < numBeatGroups) && (ng1EndTime > measure.beatGroups[beatGroupIndex])) {
					//keep looking to the next beat group until we find one that's later than the ending of our first ng, or until we come to the last one
					//debugOutput += (beatGroupIndex.toString() + " : " + numBeatGroups.toString() + " : " + ng1EndTime.toString() + " : " + measure.beatGroups[beatGroupIndex].toString() + "\n");
					beatGroupIndex++;
					//successCount++;
					//codeHits[0]++;
				}
				
				
				//now see if the ng2 belongs to the same beat group
				if (beatGroupIndex == numBeatGroups || ng2.qNoteTime - measure.stack.startTime < measure.beatGroups[beatGroupIndex]) {
					//codeHits[1]++;
					//okay... we have two notes that we can beam together.
					//handle the first note's beam status
					for (int i = 0; i < ng1.maxBeams; i++) {
						//codeHits[2]++;
						//if (ng1.beamStates.length <= i) { //if we didn't have a beam coming from previous note
						if (ng1.beamStates.length <= i || ng1.beamStates[i] == BeamState.NONE) { //if we didn't have a beam coming from previous note
							//codeHits[3]++;
							if (i < ng2.maxBeams) { //if ng2 also supports a beam at this level...
								//codeHits[4]++;
								ng1.beamStates[i] = BeamState.BEGIN; //we begin a regular beam to it
								currentBeamStartTimes[i] = ng1.qNoteTime;
							}
							else {
								//codeHits[5]++;
								//this beam level isn't matched by the following note, so we need a beamlet
								ng1.beamStates[i] = getBeamletDirection(currentBeamStartTimes[currentBeamStartTimes.length - 1], 
																		ng1.qNoteTime, ng1.qNoteDuration, ng1.beamStates[i-1]);
							}
						}
						else { //we already had a beam at this level - either as beamlet or beam
							//codeHits[6]++;
							if (i < ng2.maxBeams) { //if ng2 also supports a beam at this level...
								//dart2js we're getting here...
								//html.window.alert('what the heck');
								//codeHits[7]++;
								if (ng1.beamStates[i] == BeamState.END) { //if ng1's previous beam state was as an end...
									//codeHits[8]++;
									//successCount++;
									//dart2js but not here...
									ng1.beamStates[i] = BeamState.CONTINUE; //we change it to a continuation instead
									//html.window.alert('continue beam');
								}
								else { //otherwise ng1's previous beam state was as a beamlet, so...
									//codeHits[9]++;
									ng1.beamStates[i] = BeamState.BEGIN; //we change it to be a Beginning instead
									currentBeamStartTimes[i] = ng1.qNoteTime;
								}
							}
							else { //ng2 can't match us at this beam level
								//codeHits[10]++;
								//this beam doesn't continue to the next note, and it has already been described as either
								//a beam end or a beamlet. Nothing to do.
								
								//EDIT - THERE IS A PROBLEM WITH BEAMLET DIRECTION IN SOME CASES. In 4/4, the figure
								//8th, 32nd, dotted 16th causes 32nd beamlet to point towards eighth note (should point
								//to 16th.) Potential fix - if beamState[i] is beamlet, and beamStates[i - 1] == beamSTART,
								//then beamSate[i] = BeamState.FORWARD_HOOK
							}
						}
					}
					
					//handle the second note's beam status
					for (int i = 0; i < ng2.maxBeams; i++) {
						//codeHits[11]++;
						if (i < ng1.maxBeams) { //if ng1 was sending us a beam at this level...
							//codeHits[12]++;
							//dart2js we get here...
							ng2.beamStates[i] = BeamState.END; //finish it. (we'll consider continuing it next time around when it has become ng1)
							//currentBeamStartTimes[i] = null; //as3 - this was an ordingary array which allowed nulls
							currentBeamStartTimes[i] = -1;
						}
						else { //ng1 didn't send us a beam at this level
							//codeHits[13]++;
							//so we need a beamlet, at least until we become ng1 and can see if we need to be a Start instead
							ng2.beamStates[i] = getBeamletDirection(currentBeamStartTimes[currentBeamStartTimes.length - 1], 
																	ng2.qNoteTime, ng2.qNoteDuration, ng2.beamStates[i-1]);
						}
					}
				}
			}

		}
		if (successCount > 0){
			//html.window.alert(debugOutput);
			//html.window.alert(successCount.toString());
		}
		
//		String codeHitOutput = "";
//		for (int i = 0; i < codeHits.length; i++){
//			codeHitOutput += codeHits[i].toString() + "\t"; 
//		}
//		print('code hits: ' + codeHitOutput);
		
	}
	
	/**
	 * Gets the direction for the beamlet
	 * @param	beamStartTime the start time of the first note of the beam group
	 * @param	noteTime the start time of the note whose beamlet direction we're setting
	 * @param	noteDuration the duration of the note whose beamlet direction we're setting
	 * @param	previousBeamLevelState The beam state of the immediately preceding beam level (the 8th note beam if we're considering a sixteenth note level beam, etc.)
	 * @return	BeamState.BACKWARD_HOOK or BeamState.FORWARD_HOOK
	 */
	String getBeamletDirection(num beamStartTime, num noteTime, num noteDuration, String previousBeamLevelState) {
		if (previousBeamLevelState == BeamState.END) { //last note in beam or sub beam group always hooks backwards
			return BeamState.BACKWARD_HOOK;
		}
		else if (previousBeamLevelState == BeamState.BACKWARD_HOOK || previousBeamLevelState == BeamState.FORWARD_HOOK) {
			//if a hook was already in place, we match it regardless
			return previousBeamLevelState;
		}

		if (noteDuration == 0){ //watch out for grace notes that have no duration
			noteDuration = 0.25;
		}
		
		//if it's not the last note, the hook direction is determined based on whether the note is at a position within the beam group that is an even multiple
		//of the note's duration - ex. a 16th note at the beginning or 3rd 16th position would be forward hook
		bool isEvenMultiple = false;
		while (noteTime >= beamStartTime - 0.001) {
			if (noteTime - beamStartTime < 0.001) { //the other side of this window is set by the while loop header
				isEvenMultiple = true;
				break;
			}
			noteTime -= noteDuration;
		}
		return (isEvenMultiple)? BeamState.FORWARD_HOOK : BeamState.BACKWARD_HOOK;
	}
	
}