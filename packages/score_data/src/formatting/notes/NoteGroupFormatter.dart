part of score_data.formatting;

class NoteGroupFormatter {
	
	ScoreProperties _scoreProps;
	
	NoteGroupFormatter(ScoreProperties scoreProperties) {
		_scoreProps = scoreProperties;
	}
	
	/**
	 * gets the stem directions for all of the notes in the system
	 * @param	system the System to process
	 */
	void getSystemStemDirections(System system) {
		List<MeasureStack> stacks = system.measureStacks;
		for (var stack in stacks) {
			List<Measure> measures = stack.measures;
			for (var measure in measures) {
				getMeasureStemDirections(measure);
			}
		}
	}
	
	/**
	 * gets the stem directions for all of the notes in the measure
	 * @param	measure the Measure to process
	 */
	void getMeasureStemDirections(Measure measure) {
		int numVoices = measure.voices.length;
		
		int numVisibleVoices = 0;
		for (var voice in measure.voices){
			for (var ng in voice.noteGroups){
				if (ng.visible){
					numVisibleVoices++;
					break;
				}
			}
		}
		
		for (int voiceIndex = 0; voiceIndex < numVoices; voiceIndex++) {
			List<NoteGroup> noteGroups = measure.voices[voiceIndex].noteGroups;
			
			int currentUpScore = 0; //for up stem consideration (low notes have higher scores)
			int currentDownScore = 0; //for down stem consideration (high notes have higher scores)
			int highestUpScore = 0; //the highest up stem score we've seen for the current beam group
			int highestDownScore = 0; //the highest down stem score we've seen for the current beam group
			int numUpVotes = 0; //the number of times for the current beam group that the Up stem points beat the Down
			int numDownVotes = 0; //the number of times for the current beam group that the Down stem points beat the Up
			
			List<NoteGroup> beamGroup = new List<NoteGroup>(); //temporarily holds notes that are in a beam group
			
			for (var ng in noteGroups) {
				if (ng.isRest){
					//float rests up or down if multiple voices are present
					//if (numVoices > 1){
					if (numVisibleVoices > 1){
						ng.restVPos = (voiceIndex % 2 == 0)? _scoreProps.staffLineSpacing * -1 : _scoreProps.staffLineSpacing * 5;
					}
					else {
						//otherwise center them
						ng.restVPos = _scoreProps.staffLineSpacing * 2;
					}
					//nothing more to do for rests
					continue;
				}

				if (ng.stemDirection == StemDirection.NO_STEM) {
					//skip notes which have no stems
					continue;
				}
				
				//if there is more than one layer/voice, force the first, third, fifth, etc. layers to have 
				//up stems, and the others to have down stems
				//if (numVoices > 1) {
				if (numVisibleVoices > 1){
					ng.stemDirection = (voiceIndex % 2 == 0)? StemDirection.UP : StemDirection.DOWN;
					continue;
				}
				
				//get the scores for the current ng
				var visNotes = ng.visibleNotes;
				currentUpScore = visNotes[0].stepsFromTopStaffLine - 4;
				currentDownScore = 4 - visNotes.last.stepsFromTopStaffLine;
				//currentUpScore = ng.notes[0].stepsFromTopStaffLine - 4;
				//currentDownScore = 4 - ng.notes[ng.notes.length - 1].stepsFromTopStaffLine;
				
				//add a vote for whichever is bigger
				if (currentUpScore > currentDownScore) {
					numUpVotes++;
				}
				else {
					numDownVotes++;
				}
				
				//see if this is our highest/lowest yet
				if (currentUpScore > highestUpScore) {
					highestUpScore = currentUpScore;
				}
				if (currentDownScore > highestDownScore) {
					highestDownScore = currentDownScore;
				}
				
				
				if (ng.beamStates.length == 0 || ng.beamStates[0] == BeamState.NONE) { //if the note has no beam or beamlet...
					//decide its direction and reset the scores
					ng.stemDirection = (highestUpScore > highestDownScore)? StemDirection.UP : StemDirection.DOWN;
					highestUpScore = highestDownScore = numUpVotes = numDownVotes = 0; //reset the scores
					/*if (highestUpScore > highestDownScore) {
						ng.stemDirection = StemDirection.UP;
					}*/
				}
				else if (ng.beamStates[0] == BeamState.END) { //if the note was the last of a beam group...
					beamGroup.add(ng); //add the note to the beam group
					
					//if the strongest Up stem note (lowest note) was stronger than the strongest Down stem note, OR they were EQUALLY strong and there were more Up votes,
					//the Up stem wins. Otherwise the Down stem wins (down stem wins ties - highest/lowest note gets priority over num votes, so num votes is a tie breaker)
					if (highestUpScore > highestDownScore || (highestUpScore == highestDownScore && numUpVotes > numDownVotes)) {
						setStemDirectionsForBeamedNotes(beamGroup, StemDirection.UP);
					}
					else {
						setStemDirectionsForBeamedNotes(beamGroup, StemDirection.DOWN);
					}
					highestUpScore = highestDownScore = numUpVotes = numDownVotes = 0; //reset the scores
					beamGroup = new List<NoteGroup>(); //clear the beamed note list
				}
				else { //this note starts or continues a beam group - add it to our list and continue to the next note						
					beamGroup.add(ng);
				}
			}
		}
	}
	
	void setStemDirectionsForBeamedNotes(List<NoteGroup> beamedNotes, String direction) {
		for (var beamedNG in beamedNotes) {
			beamedNG.stemDirection = direction;
		}
	}
	
	/**
	 * sets the positions of noteheads within a notegroup for the passed in system
	 * @param	system the system to process
	 */
	void getSystemNoteheadOffsets(System system) {
		List<MeasureStack> stacks = system.measureStacks;
		for (var stack in stacks) {
			List<Measure> measures = stack.measures;
			for (var measure in measures) {
				getMeasureNoteheadOffsets(measure);
			}
		}
	}

	/**
	 * sets the positions of noteheads within a notegroup for the passed in Measure
	 * @param	measure the Measure to process
	 */
	void getMeasureNoteheadOffsets(Measure measure) {
		for (var voice in measure.voices) {
			List<NoteGroup> groups = voice.noteGroups;
			for (var ng in groups) {
				getNoteheadOffsets(ng);
			}
		}
	}
	
	/**
	 * sets the positions of noteheads within a notegroup
	 * @param	noteGroup the noteGroup to process
	 */
//	void getNoteheadOffsetsOld(NoteGroup noteGroup) {
//		if (noteGroup.isRest){
//			return; //nothing for rests
//		}
//
//		bool placeOnLeft;
//		List<Note> notes = noteGroup.notes;
//		int numNotes = notes.length;
//		int lastPosition = 1000; //the line/space position of the last notehead - our cluster logic looks for close notes, so we start out with a large value that won't trigger it
//		num leftNotePos = -1 * _scoreProps.noteheadWidth; //the offset used for a notehead that appears on the left side of a stem
//		num rightNotePos = _scoreProps.noteheadWidth; //the offset used for a notehead that appears on the right side of a stem
//		Note cNote;
//		if (noteGroup.stemDirection == StemDirection.UP) {
//			//up stem notes start with the bottom notehead on the left
//			placeOnLeft = true;
//			for (int i = 0; i < numNotes; i++){
//				cNote = notes[i];
//				if (lastPosition - cNote.stepsFromTopStaffLine <= 1) { //if the last notehead was 1 step away (or less)...
//					placeOnLeft = !placeOnLeft;
//					cNote.hPos = (placeOnLeft)? 0 : rightNotePos;
//				}
//				else { //by default we always place on left with an Up stem.
//					placeOnLeft = true; //reset this to true since we no longer have evidence of a cluster
//					cNote.hPos = 0;
//				}
//				lastPosition = cNote.stepsFromTopStaffLine;
//			}
//		}
//		else if (noteGroup.stemDirection == StemDirection.DOWN){
//			//down stem notes start with the top notehead on the right
//			placeOnLeft = false;
//			lastPosition = -1000;
//			int i = numNotes - 1;
//			while (i >= 0){ //we go from top down (top note is always last in the list)
//				cNote = notes[i];
//				if (cNote.stepsFromTopStaffLine - lastPosition <= 1) { //if the last notehead was 1 step away (or less)...
//					placeOnLeft = !placeOnLeft;
//					cNote.hPos = (placeOnLeft)? leftNotePos : 0;
//				}
//				else { //by default we always place on left with an Up stem.
//					placeOnLeft = false; //reset this to true since we no longer have evidence of a cluster
//					cNote.hPos = 0;
//				}
//				lastPosition = cNote.stepsFromTopStaffLine;
//				i--;
//			}
//		}
//		else {
//			//notes that have no stems (whole notes) will need logic for determining whether to favor up or down stem functionality.
//			//for now, we'll just use up stem logic - the only situation where this breaks is when we have whole note clusters of 3, 5, 7, etc. notes.
//			
//			placeOnLeft = true;
//			for (int i = 0; i < numNotes; i++){
//				cNote = notes[i];
//				if (lastPosition - cNote.stepsFromTopStaffLine <= 1) { //if the last notehead was 1 step away (or less)...
//					placeOnLeft = !placeOnLeft;
//					cNote.hPos = (placeOnLeft)? 0 : rightNotePos;
//				}
//				else { //by default we always place on left with an Up stem.
//					placeOnLeft = true; //reset this to true since we no longer have evidence of a cluster
//					cNote.hPos = 0;
//				}
//				lastPosition = cNote.stepsFromTopStaffLine;
//			}
//		}
//
//
//		//position the accidentals for the notes
//		//for this implementation we'll follow what I believe is Noteflight's model. Within a notegroup, the highest note gets
//		//first priority in having its accidental as close as possible. The lowest note then gets second pick. Then comes the
//		//second note from the top, then the second note from the bottom, and so on, working from the outside in. No two accidentals
//		//which are less than a 7th apart can have their accidentals positioned at the same "level" - a level being essentially
//		//the number of accidental widths away from the note.
//
//		//I believe that Finale's model is similar but differs in that if a note with an accidental is more than a 6th below a previous
//		//note with a first level accidental, it not only gets to share the first level but also BECOMES the new top note in regards to the
//		//notes that fall below it.
//
//		//before we start, we should special case the situation where there is only one note
//		if (numNotes == 1){
//			if (notes[0].accidental != AccidentalType.NONE){
//				//notes[0].accidentalPos = (noteGroup.stemDirection == StemDirection.UP)? leftNotePos : leftNotePos * 2;
//				notes[0].accidentalPos = leftNotePos * 1.5;
//				noteGroup.numAccidentalLevels = 1;
//			}
//		}
//
//		//we'll use a single array to keep track of the levels that have been claimed at each stepsFromTopStaffLine position (which serves as the index)
//		int offset = -1 * notes[numNotes - 1].stepsFromTopStaffLine; //make the steps 0 based by adding an offset needed to make the top note 0
//		//List<int> levelClaimsList = new List<int>(notes[0].stepsFromTopStaffLine + offset + 1, true);
//		//int numPositions = levelClaimsList.length;
//		List<int> levelClaimsList = [];
//		int numPositions = notes[0].stepsFromTopStaffLine + offset + 1;
//
//		for (int i = 0; i < numNotes; i++){
//			//start with last (top) note, then first, then 2nd to last, etc.
//			cNote = (i % 2 == 0)? notes[numNotes - i ~/ 2 - 1] : notes[i ~/ 2];
//
//			if (cNote.accidental == AccidentalType.NONE){
//				continue; //skip notes that have no accidental
//			}
//
//			//get the position for our note and set the range that we look through for level positions that have been claimed
//			int noteIndex = cNote.stepsFromTopStaffLine + offset;
//			int lowerBound = (noteIndex - 5 >= 0)? noteIndex - 5 : 0;
//			int upperBound = (noteIndex + 5 <= numPositions - 1)? noteIndex + 5 : numPositions - 1;
//
//			//find the lowest unclaimed level within our bounds
//			int cLevel = 1;
//			bool repeat = true;
//			while (repeat) {
//				repeat = false;
//				int j = lowerBound;
//				while ( j <= upperBound){
//					if (levelClaimsList[j] == cLevel){
//						cLevel++;
//						repeat = true;
//						break;
//					}
//					j++;
//				}
//			}
//
//			//set the position of the accidental and update the NoteGroup's highest level tracker
//			levelClaimsList[noteIndex] = cLevel;
//			//cNote.accidentalPos = (noteGroup.stemDirection == StemDirection.UP)? leftNotePos * cLevel : leftNotePos * (cLevel + 1);
//			cNote.accidentalPos = leftNotePos * 1.5 + ((cLevel - 1) * leftNotePos);
//			if (cLevel > noteGroup.numAccidentalLevels){
//				noteGroup.numAccidentalLevels = cLevel;
//			}
//			
//		}
//		
//	}

	/**
	 * sets the positions of noteheads within a notegroup
	 * @param	noteGroup the noteGroup to process
	 */
	void getNoteheadOffsets(NoteGroup noteGroup) {
		if (noteGroup.isRest){
			return; //nothing for rests
		}

		//within a NoteGroup, there are 2 positions for the stems and noteheads. The default position for a single notehead will be 0.
		//If the stem is up, the stem must be placed in the 2nd position (one notehead's width to the right of 0). If the stem is down,
		//it will be placed at 0 UNLESS there is a cluster which causes one or more noteheads to be positioned in the 2nd position, in
		//which case the stem will also be moved to the second position

		bool placeOnLeft;
		var notes = noteGroup.visibleNotes;
		//List<Note> notes = noteGroup.notes;
		int numNotes = notes.length;
		int lastPosition = 1000; //the line/space position of the last notehead - our cluster logic looks for close notes, so we start out with a large value that won't trigger it
		num leftNotePos = 0; //notes on the left will always be positioned at 0
		num rightNotePos = (!noteGroup.isGrace)? _scoreProps.noteheadWidth : 0.65 * _scoreProps.noteheadWidth; //the offset used for a notehead that appears on the right side of a stem
		num stemHPos = 0; //the offset used for the stem - up stems and chords with notes on both the left and right place the stem in the rightNotePos
		num stemStartPos; //the starting vertical position of the stem
		Note cNote;
		if (noteGroup.stemDirection == StemDirection.UP) {
			stemStartPos = notes[0].vPos;
			stemHPos = rightNotePos;
			//up stem notes start with the bottom notehead on the left
			placeOnLeft = true;
			for (int i = 0; i < numNotes; i++){
				cNote = notes[i];
				if (lastPosition - cNote.stepsFromTopStaffLine <= 1) { //if the last notehead was 1 step away (or less)...
					placeOnLeft = !placeOnLeft;
					cNote.hPos = (placeOnLeft)? leftNotePos : rightNotePos;
				}
				else { //by default we always place on left with an Up stem.
					placeOnLeft = true; //reset this to true since we no longer have evidence of a cluster
					cNote.hPos = 0;
				}
				lastPosition = cNote.stepsFromTopStaffLine;
			}
		}
		else if (noteGroup.stemDirection == StemDirection.DOWN){
			stemStartPos = notes[numNotes - 1].vPos;
			//down stem notes start with the top notehead on the right
			placeOnLeft = false;
			lastPosition = -1000;
			bool clusterFound = false;
			int i = numNotes - 1;
			while (i >= 0){ //we go from top down (top note is always last in the list)
				cNote = notes[i];
				if (cNote.stepsFromTopStaffLine - lastPosition <= 1) { //if the last notehead was 1 step away (or less)...
					placeOnLeft = !placeOnLeft;
					//we've found a cluster, which means we're going to have to do a second pass through the notes at the end (see comment in else{})
					//for now we set the value of the position 1 notehead's width too far to the left so that when it's corrected, it will be in place.
					cNote.hPos = (placeOnLeft)? -1 * rightNotePos : leftNotePos;
					stemHPos = rightNotePos;
					clusterFound = true;
				}
				else {
					//by default with a down stem, both the stem and the notes go at 0. However, if we encounter a cluster, then the stem
					//will be positioned at right along with any notes that are not part of a cluster or which fall on the right in a cluster
					//we'll have to do another pass through the notes to correct the settings if a cluster is found
					placeOnLeft = false; //reset this to true since we no longer have evidence of a cluster
					cNote.hPos = 0;
				}
				lastPosition = cNote.stepsFromTopStaffLine;
				
				i--;
			}

			if (clusterFound){
				//correct the positions - they're all 1 notehead's width too far to the left
				for (int i = 0; i < numNotes; i++){
					notes[i].hPos += rightNotePos;
				}
			}
		}
		else {
			stemStartPos = 0;
			//notes that have no stems (whole notes) will need logic for determining whether to favor up or down stem functionality.
			//for now, we'll just use up stem logic - the only situation where this breaks is when we have whole note clusters of 3, 5, 7, etc. notes.
			stemHPos = rightNotePos;
			placeOnLeft = true;
			for (int i = 0; i < numNotes; i++){
				cNote = notes[i];
				if (lastPosition - cNote.stepsFromTopStaffLine <= 1) { //if the last notehead was 1 step away (or less)...
					placeOnLeft = !placeOnLeft;
					cNote.hPos = (placeOnLeft)? leftNotePos : rightNotePos;
				}
				else { //by default we always place on left with an Up stem.
					placeOnLeft = true; //reset this to true since we no longer have evidence of a cluster
					cNote.hPos = 0;
				}
				lastPosition = cNote.stepsFromTopStaffLine;
			}
		}

		noteGroup.stemHPos = stemHPos;
		noteGroup.stemStartPos = stemStartPos;

		//position the accidentals for the notes
		//for this implementation we'll follow what I believe is Noteflight's model. Within a notegroup, the highest note gets
		//first priority in having its accidental as close as possible. The lowest note then gets second pick. Then comes the
		//second note from the top, then the second note from the bottom, and so on, working from the outside in. No two accidentals
		//which are less than a 7th apart can have their accidentals positioned at the same "level" - a level being essentially
		//the number of accidental widths away from the note.

		//I believe that Finale's model is similar but differs in that if a note with an accidental is more than a 6th below a previous
		//note with a first level accidental, it not only gets to share the first level but also BECOMES the new top note in regards to the
		//notes that fall below it.

		/*if (noteGroup.voice.measure.stack.number == 5 && !noteGroup.isRest && noteGroup.notes[0].accidental != "none"){
			trace();
		}*/

		noteGroup.numAccidentalLevels = 0;
		//before we start, we should special case the situation where there is only one note
		if (numNotes == 1){
			//if (notes[0].accidental != AccidentalType.NONE){
			if (notes[0].showAccidental){
				notes[0].accidentalPos = -1.1 * rightNotePos;
				noteGroup.numAccidentalLevels = 1;
			}
		}
		else {
			//we'll use a single array to keep track of the levels that have been claimed at each stepsFromTopStaffLine position (which serves as the index)
			int offset = -1 * notes[numNotes - 1].stepsFromTopStaffLine; //make the steps 0 based by adding an offset needed to make the top note 0
			int listLength = notes[0].stepsFromTopStaffLine + offset + 1;
			//List<int> levelClaimsList = new List<int>(listLength, true);
			Map<int, int> levelClaimsList = new Map<int, int>();
			int numPositions = listLength;

			for (int i = 0; i < numNotes; i++){
				//start with last (top) note, then first, then 2nd to last, etc.
				cNote = (i % 2 == 0)? notes[numNotes - (i ~/ 2) - 1] : notes[i ~/ 2];

				//if (cNote.accidental == AccidentalType.NONE){
				if (cNote.showAccidental == false){
					continue; //skip notes that have no accidental
				}

				//get the position for our note and set the range that we look through for level positions that have been claimed
				int noteIndex = cNote.stepsFromTopStaffLine + offset;
				int lowerBound = (noteIndex - 5 >= 0)? noteIndex - 5 : 0;
				int upperBound = (noteIndex + 5 <= numPositions - 1)? noteIndex + 5 : numPositions - 1;

				//find the lowest unclaimed level within our bounds
				int cLevel = 1;
				bool repeat = true;
				while (repeat) {
					repeat = false;
					int j = lowerBound;
					while (j <= upperBound){
						if (levelClaimsList[j] == cLevel){
							cLevel++;
							repeat = true;
							break;
						}
						j++;
					}
				}

				//set the position of the accidental and update the NoteGroup's highest level tracker
				levelClaimsList[noteIndex] = cLevel;
				//cNote.accidentalPos = (noteGroup.stemDirection == StemDirection.UP)? leftNotePos * cLevel : leftNotePos * (cLevel + 1);
				cNote.accidentalPos = -1.1 * rightNotePos - ((cLevel - 1) * rightNotePos);
				if (cLevel > noteGroup.numAccidentalLevels){
					noteGroup.numAccidentalLevels = cLevel;
				}

			}
		}



	}
	
	/**
	 * gets the stem end positions for all NoteGroups in the System
	 * @param	system the System to process
	 */
	void getSystemStemEndPositions(System system) {
		List<MeasureStack> stacks = system.measureStacks;
		for (var stack in stacks) {
			List<Measure> measures = stack.measures;
			for (var measure in measures) {
				getMeasureStemEndPositions(measure);
			}
		}
	}
	
	/**
	 * gets the stem end positions for all NoteGroups in the Measure
	 * @param	measure the Measure to process
	 */
	void getMeasureStemEndPositions(Measure measure) {
		for (var voice in measure.voices) {
			List<NoteGroup> noteGroups = voice.noteGroups;
			
			//beam tracking variables
			List<NoteGroup> beamedNotes = [];
			NoteGroup firstNote = null; //first note in the beam group
			NoteGroup lastNote = null; //last note in the beam group
			num firstNoteRP = 0; //first note's requested line/space stem end position
			num lastNoteRP = 0; //last note's requested line/space stem end position
			num interiorHighestRP = 0; //highest requested line/space stem end position of an interior note
			num interiorLowestRP = 0; //lowest requested line/space stem end position of an interior note
			int beamedNoteCount = 0; //number of notes in current beam group
			
			for (var ng in noteGroups) {
				if (ng.isRest || ng.stemDirection == StemDirection.NO_STEM) { //skip rests and notes with no stems
					continue;
				}
				
				//get the requested stem end position (the value this note would take if not mitigated by any circumstances)
				int requestedStemPos = getRequestedStemEndPosition(ng); 
				
				if (ng.beamStates.length == 0 || ng.beamStates[0] == BeamState.NONE) { //normal note - no beam
					//ng.stemEndPos = -1 * (_scoreProps.staffLineSpacing / 2) * requestedStemPos;
					ng.stemEndPos = (_scoreProps.staffLineSpacing / 2) * requestedStemPos;
				}
				
				else if (ng.beamStates[0] == BeamState.BEGIN) { //Beginning of new beam group
					beamedNotes = [ng]; // start a new set of beamed notes and add the first note to it
					beamedNoteCount = 1;
					firstNote = ng;
					firstNoteRP = requestedStemPos; //mark the requested stem end position of the first note
					
					//reset the values for the interior notes
					interiorHighestRP = 1000; //(a very low stem value that will always be surpassed by an interior note)
					interiorLowestRP = -1000; //(a very high stem value that will always be surpassed by an interior note)
					
				}
				else if (ng.beamStates[0] == BeamState.CONTINUE) { //continuation of beam
					//collect the data for this note and add it to the beam group
					if (requestedStemPos < interiorHighestRP) {
						interiorHighestRP = requestedStemPos;
					}
					if (requestedStemPos > interiorLowestRP) {
						interiorLowestRP = requestedStemPos;
					}
					beamedNotes.add(ng);
					beamedNoteCount++;
				}
				else if (ng.beamStates[0] == BeamState.END) { //end of beam
					lastNoteRP = requestedStemPos; //mark the requested stem end position of the last note
					lastNote = ng;
					beamedNotes.add(ng); //add the note to the beam group
					beamedNoteCount++;
					
					//run the beam angle logic and get resulting stem end positions
					
					//first we compute the line/space positions of the two end notes
					
					if (firstNote.stemDirection == StemDirection.UP) { //Up Stem
						if (firstNoteRP < interiorHighestRP || lastNoteRP < interiorHighestRP) {
							//we'll potentially have a slanted stem, because either the first or last note is uniquely the highest beam point
							if (firstNoteRP <= lastNoteRP) { //if the first note was equally high or higher than the last note...
								lastNoteRP = firstNoteRP + ((lastNoteRP - firstNoteRP) / 4); //adjust the stem end position of the last note to be based on first note's position
							}
							else {
								firstNoteRP = lastNoteRP + ((firstNoteRP - lastNoteRP) / 4); //adjust the stem end position of the first note to be based on last note's position
							}
						}
						else {
							//we'll have a flat stem, because the highest end note is matched or exceeded by at least one interior note
							firstNoteRP = interiorHighestRP; //use the requested position for the winning interior note for both first and last notes
							lastNoteRP = interiorHighestRP;
						}
					}
					else { //Down Stem
						if (firstNoteRP > interiorLowestRP || lastNoteRP > interiorLowestRP) {
							//we'll potentially have a slanted stem, because either the first or last note is uniquely the lowest beam point
							if (firstNoteRP >= lastNoteRP) { //if the first note was equally low or lower than the last note...
								lastNoteRP = firstNoteRP - ((firstNoteRP - lastNoteRP) / 4); //adjust the stem end position of the last note to be based on first note's position
							}
							else {
								firstNoteRP = lastNoteRP - ((lastNoteRP - firstNoteRP) / 4); //adjust the stem end position of the first note to be based on last note's position
							}
						}
						else {
							//we'll have a flat stem, because the lowest end note is matched or exceeded by at least one interior note
							firstNoteRP = interiorLowestRP; //use the requested position for the winning interior note for both first and last notes
							lastNoteRP = interiorLowestRP;
						}
					}
					
					//now convert the space/line positions to pixel values used for rendering
					//firstNote.stemEndPos = -1 * (_scoreProps.staffLineSpacing / 2) * firstNoteRP;
					//lastNote.stemEndPos = -1 * (_scoreProps.staffLineSpacing / 2) * lastNoteRP;
					firstNote.stemEndPos = (_scoreProps.staffLineSpacing / 2) * firstNoteRP;
					lastNote.stemEndPos = (_scoreProps.staffLineSpacing / 2) * lastNoteRP;

					//compute the values for any interior notes
					num totalHDistance = lastNote.hPos - firstNote.hPos; //we base each interior note's stem end position on its proportion of the distance between the two ends
					num totalRise = lastNote.stemEndPos - firstNote.stemEndPos; //total pixel rise (or fall) between start and end of beam
					int i = 1;
					while (i < beamedNoteCount - 1) { //this won't be entered if we have no interior notes
						NoteGroup cIntNote = beamedNotes[i]; //current internal noteGroup
						cIntNote.stemEndPos = firstNote.stemEndPos + (totalRise * ((cIntNote.hPos - firstNote.hPos) / totalHDistance));
						i++;
					}
				}
				
			}
			
		}
		
	}
	
	int getRequestedStemEndPosition(NoteGroup noteGroup) {
		Note decidingNote;
		int bonusDurationLength;
		int penaltyLength;
		int request;
		var notes = noteGroup.visibleNotes;
		if (noteGroup.stemDirection == StemDirection.UP) {
			decidingNote = notes.last; //top note decides stem request length
			//decidingNote = noteGroup.notes[noteGroup.notes.length - 1]; //top note decides stem request length
			bonusDurationLength = (noteGroup.maxBeams < 2)? 0 : noteGroup.maxBeams - 2; //notes with 3 or more flags or beams get extra space
			if (!noteGroup.isGrace) {
				//stem length is shorter if note has no flag and is above middle line
				penaltyLength = ((noteGroup.maxBeams == 0 || noteGroup.beamStates.length > 0) && decidingNote.stepsFromTopStaffLine < 4)? 1 : 0; 
			}
			else {
				penaltyLength = 3; //grace notes have shorter stems
			}
			
			request = decidingNote.stepsFromTopStaffLine - 7 - bonusDurationLength + penaltyLength;
			return (request <= 4)? request : 4; //make sure the stem goes at least to the middle line
		}
		else {
			decidingNote = notes[0]; //bottom note decides stem request length
			//decidingNote = noteGroup.notes[0]; //bottom note decides stem request length
			bonusDurationLength = (noteGroup.maxBeams < 2)? 0 : noteGroup.maxBeams - 2; //notes with 3 or more flags or beams get extra space
			if (!noteGroup.isGrace) {
				//stem length is shorter if note has no flag and is above middle line
				penaltyLength = ((noteGroup.maxBeams == 0 || noteGroup.beamStates.length > 0) && decidingNote.stepsFromTopStaffLine > 4)? 1 : 0; 
			}
			else {
				penaltyLength = 3; //grace notes have shorter stems
			}
			
			request = decidingNote.stepsFromTopStaffLine + 7 + bonusDurationLength - penaltyLength;
			return (request >= 4)? request : 4; //make sure the stem goes at least to the middle line
		}
	}
	
	
}