part of score_data.music_creation;

class NoteManager {

	Score _score; //the Score data object

	NoteManager(Score score) {
		_score = score;
	}
	
	/**
	 * adds the pitch to the specified Note
	 * @param note the Note to change
	 * @param octaveDelta the number of octaves to shift the note - negative values for transposing down.
	 */
	void changeNoteOctave(Note note, int octaveDelta) {
		var noteGroup = note.noteGroup;
//		if (noteGroup.qNoteTime == 56.0){
//			print('56.0');
//		}
		var measure = noteGroup.voice.measure;

		//edit the Note
		int oldOctave = int.parse(note.pitchName.substring(1));
		note.pitchName = note.pitchName[0] + (oldOctave + octaveDelta).toString();
		note.displayCents += 1200 * octaveDelta;
//		if (measure.staff.partRef.percussionMap != null){
//			//check to see if this note is on a non-pitched percussion staff
//			var percussionMap = measure.staff.partRef.percussionMap;
//			if (percussionMap[note.displayCents / 100] != null){
//				note.playbackCents = percussionMap[note.displayCents / 100] * 100;
//			}
//			else if (percussionMap[0] != null){
//				note.playbackCents = percussionMap[0] * 100;
//			}
//			else {
//				note.playbackCents = 3800;
//			}
//		}
		
		note.stepsFromTopStaffLine = PitchUtils.getStepsFromTopStaffLine(note.pitchName, 
											measure.clefs[measure.clefs.length - 1].type);
		note.vPos = (_score.scoreProperties.staffLineSpacing / 2) * note.stepsFromTopStaffLine;
		note.legerLines = PitchUtils.getNumberOfLegerLines(note.stepsFromTopStaffLine);

		
		//place the new note in order of pitch - lowest pitches first
		if (noteGroup.notes.length > 0){
			noteGroup.sortNotesByPitch();
		}

		//update the accidentals
		updateAccidentals(measure);

		measure.notesNeedRendering = true;
	}
	
	/**
	 * adds the pitch to the specified Note
	 * @param note the Note to change
	 * @param octaveDelta the number of octaves to shift the note - negative values for transposing down.
	 */
	void changeNoteGroupOctave(NoteGroup ng, int octaveDelta) {
		var measure = ng.voice.measure;

		for (var note in ng.notes){
			//edit the Note
			int oldOctave = int.parse(note.pitchName.substring(1));
			note.pitchName = note.pitchName[0] + (oldOctave + octaveDelta).toString();
			note.displayCents += 1200 * octaveDelta;
//			if (measure.staff.partRef.percussionMap != null){
//				//check to see if this note is on a non-pitched percussion staff
//				var percussionMap = measure.staff.partRef.percussionMap;
//				if (percussionMap[note.displayCents / 100] != null){
//					note.playbackCents = percussionMap[note.displayCents / 100] * 100;
//				}
//				else if (percussionMap[0] != null){
//					note.playbackCents = percussionMap[0] * 100;
//				}
//				else {
//					note.playbackCents = 3800;
//				}
//			}
			
			note.stepsFromTopStaffLine = PitchUtils.getStepsFromTopStaffLine(note.pitchName, 
												measure.clefs[measure.clefs.length - 1].type);
			note.vPos = (_score.scoreProperties.staffLineSpacing / 2) * note.stepsFromTopStaffLine;
			note.legerLines = PitchUtils.getNumberOfLegerLines(note.stepsFromTopStaffLine);
		}

		//update the accidentals
		updateAccidentals(measure);

		measure.notesNeedRendering = true;
	}

	/**
	 * changes the passed in NoteGroup's duration. Any notes overlapped by an increase in duration are deleted.
	 * any gaps created are filled with rests
	 * @param noteGroup the NoteGroup object to change
	 * @param newDuration the new Duration Unit duration (a power of 2 matching a duration in the DurationType constants)
	 * @param numDots the number of augmentation dots
	 */
	void changeDuration(NoteGroup noteGroup, int newDuration, int numDots) {
		//check to make sure the duration is different than the one we already have
		if (noteGroup.duration == newDuration && noteGroup.numDots == numDots){
			return;
		}

		//make sure the duration is an allowable size
		if (newDuration != 64 && newDuration != 128 && newDuration != 256 && newDuration != 512 && 
				newDuration != 1024 && newDuration != 2048 && newDuration != 4096){
			return;
		}

		//make sure the new duration will fit
		int totalDuration = newDuration + DurationType.calculateDotDuration(newDuration, numDots);
		if (noteGroup.tuplets != null){
			var tupletNGC = noteGroup.ngcRef.parentNGC; //the NGC with the tuplet's definition - contains all of the notegroups in this tuplet
			var tuplet = tupletNGC.tuplet;
			if (noteGroup.ngcRef.durUnitStartTime + totalDuration > (tupletNGC.durUnitEndTime - tupletNGC.durUnitStartTime) * (tuplet.numerator / tuplet.denominator)){
				return; //the note is too big to fit in its containing tuplet
			}
		}
		else {
			if (noteGroup.ngcRef.durUnitStartTime + totalDuration > (noteGroup.voice.measure.stack.endTime - noteGroup.voice.measure.stack.startTime) * 1024){
				return; //the note is too big to fit in the measure
			}
		}

		//update the notegroup's and ngc's values
		noteGroup.durationType = newDuration;
		noteGroup.duration = newDuration;
		noteGroup.numDots = numDots;
		noteGroup.ngcRef.durUnitEndTime = noteGroup.ngcRef.durUnitStartTime + totalDuration;
		noteGroup.qNoteDuration = totalDuration / 1024;
		noteGroup.stemDirection = (newDuration < 4096)? StemDirection.DOWN : StemDirection.NO_STEM;

		//check to see if the new duration causes the note to overlap following notes. If so, delete them.
		List<NoteGroupContainer> parentList; //the list of NGC's that contains this noteGroup's NGC
		if (noteGroup.tuplets != null){
			//multiply the qNoteDuration by the combined tuplet ratios
			num tupletRatio = 1;
			for (var tuplet in noteGroup.tuplets){
				tupletRatio *= (tuplet.denominator / tuplet.numerator) * (tuplet.denominatorDuration / tuplet.numeratorDuration);
			}
			noteGroup.qNoteDuration *= tupletRatio;

			parentList = noteGroup.ngcRef.parentNGC.ngcList; //the containing list is the NGC that defines the tuplet
		}
		else {
			parentList = noteGroup.voice.noteGroupContainers; //the containing list is the list maintained by the Voice object itself
		}

		for (int i = parentList.length - 1; i >= 0; i--){ //check for the overlaps
			var ngc = parentList[i];
			if (noteGroup.ngcRef.durUnitEndTime > ngc.durUnitStartTime && ngc.durUnitStartTime > noteGroup.ngcRef.durUnitStartTime){
				List<NoteGroup> removedNoteGroups; //track all removed notegroups so we can remove them from the stack as well
				//ngc.noteGroup.voice.removeNoteGroup(ngc.noteGroup); //delete the noteGroup (and ngc) from the voice
				if (ngc.noteGroup != null){
					ngc.noteGroup.voice.removeNoteGroupContainer(ngc); //delete the ngc (and ng) from the voice)
					ngc.noteGroup.voice.measure.stack.removeNoteGroup(ngc.noteGroup); //delete the noteGroup from the stack
					removedNoteGroups = [ngc.noteGroup];
				}
				else { //this container is for a tuplet
					removedNoteGroups = noteGroup.voice.removeNoteGroupContainer(ngc, false);
				}

				//remove the NoteGroups from the stack as well
				if (noteGroup.voice.measure.staff.partRef.visible){
					for (var ngToRemove in removedNoteGroups){
						noteGroup.voice.measure.stack.removeNoteGroup(ngToRemove);
					}
				}

				//remove any slurs
				for (var ngToRemove in removedNoteGroups){
					for (var slur in ngToRemove.slurs){
						removeSlur(slur);
					}
				}
			}
		}

		//add rests to fill any gaps that were left due to deletion or a smaller duration
		var measure = noteGroup.voice.measure;
		fillMeasure(measure);

		measure.notesNeedRendering = true;
	}

	void addTuplet(NoteGroup ng, int numerator, int denominator, int numeratorDuration, int denominatorDuration) {
		//make sure the values are valid
		if (numeratorDuration != 64 && numeratorDuration != 128 && numeratorDuration != 256 && numeratorDuration != 512 &&
						numeratorDuration != 1024 && numeratorDuration != 2048 && numeratorDuration != 4096){
			return;
		}

		if (denominatorDuration != 64 && denominatorDuration != 128 && denominatorDuration != 256 && denominatorDuration != 512 &&
						denominatorDuration != 1024 && denominatorDuration != 2048 && denominatorDuration != 4096){
			return;
		}

		List<NoteGroupContainer> parentList; //the list of NGC's that contains this noteGroup's NGC
		int totalDuration = denominator * denominatorDuration;
		Tuplet tuplet;
		if (ng.tuplets != null){
			var tupletNGC = ng.ngcRef.parentNGC; //the NGC with the tuplet's definition - contains all of the notegroups in this tuplet
			tuplet = tupletNGC.tuplet;
			//THIS LINE SEEMS QUESTIONABLE - should it be (tuplet.numerator * tuplet.numeratorDuration) / (tuplet.denominator * tuplet.denominatorDuration) ? i don't think so...
			if (ng.ngcRef.durUnitStartTime + totalDuration > (tupletNGC.durUnitEndTime - tupletNGC.durUnitStartTime) * (tuplet.numerator / tuplet.denominator)){
				return; //the tuplet is too big to fit in its containing tuplet
			}
			parentList = ng.ngcRef.parentNGC.ngcList; //the containing list is the NGC that defines the tuplet
		}
		else {
			if (ng.ngcRef.durUnitStartTime + totalDuration > (ng.voice.measure.stack.endTime - ng.voice.measure.stack.startTime) * 1024){
				return; //the note is too big to fit in the measure
			}
			parentList = ng.voice.noteGroupContainers; //the containing list is the list maintained by the Voice object itself
		}

		//remove any notegroups and containers that our tuplet's duration will overlap, other than the first NG
		for (int i = parentList.length - 1; i >= 0; i--){ //check for the overlaps
			var ngc = parentList[i];
			if (ng.ngcRef.durUnitStartTime + totalDuration > ngc.durUnitStartTime && ngc.durUnitStartTime > ng.ngcRef.durUnitStartTime){
				//ngc.noteGroup.voice.removeNoteGroup(ngc.noteGroup); //delete the noteGroup (and ngc) from the voice
				List<NoteGroup> removedNoteGroups; //track all removed notegroups so we can remove them from the stack as well
				if (ngc.noteGroup != null){
					ngc.noteGroup.voice.removeNoteGroupContainer(ngc); //delete the ngc (and ng) from the voice)
					ngc.noteGroup.voice.measure.stack.removeNoteGroup(ngc.noteGroup); //delete the noteGroup from the stack
					removedNoteGroups = [ngc.noteGroup];
				}
				else {
					removedNoteGroups = ng.voice.removeNoteGroupContainer(ngc, false);
				}

				//remove the NoteGroups from the stack as well
				if (ng.voice.measure.staff.partRef.visible){
					for (var ngToRemove in removedNoteGroups){
						ng.voice.measure.stack.removeNoteGroup(ngToRemove);
					}
				}

				//remove any slurs
				for (var ngToRemove in removedNoteGroups){
					for (var slur in ngToRemove.slurs){
						removeSlur(slur);
					}
				}
			}
		}

		//create our tuplet definition
		tuplet = new Tuplet();
		tuplet.above = true;
		tuplet.denominator = denominator;
		tuplet.denominatorDuration = denominatorDuration;
		tuplet.numerator = numerator;
		tuplet.numeratorDuration = numeratorDuration;
		tuplet.firstNote = ng;
		tuplet.endNote = ng; //this will be updated when we fill with rests

		if (ng.tuplets == null){
			ng.tuplets = [];
		}
		tuplet.tupletID = ng.tuplets.length + 1;
		ng.tuplets.add(tuplet);

		//convert our NoteGroup's NoteGroupContainer into a new parent, "tuplet" container. We'll store the tuplet definition in
		//this NGC and create a list for child NoteGroupContainers (members of the tuplet). We then will create a new
		//ChildNGC to store the NoteGroup in this list

		int originalDurUnitDuration = ng.ngcRef.durUnitEndTime - ng.ngcRef.durUnitStartTime;
		var parentNGC = ng.ngcRef;
		parentNGC.durUnitEndTime = parentNGC.durUnitStartTime + (denominator * denominatorDuration);
		var childNGC = new NoteGroupContainer();
		childNGC.durUnitStartTime = 0;
		childNGC.durUnitEndTime = originalDurUnitDuration;
		childNGC.noteGroup = ng;
		ng.ngcRef = childNGC;
		childNGC.qNoteStartTime = parentNGC.qNoteStartTime;
		childNGC.parentNGC = parentNGC;
		ng.qNoteDuration *= (tuplet.denominator / tuplet.numerator);
		parentNGC.ngcList = [childNGC];
		parentNGC.noteGroup = null;
		parentNGC.tuplet = tuplet;

		//add rests to fill any gaps that were left due to deletion or a smaller duration
		var measure = ng.voice.measure;
		fillMeasure(measure);

		measure.notesNeedRendering = true;
	}

	/**
	 * Toggles the tie state for the requested Note
	 * @param note the Note to change
	 */
	void toggleTie(Note note) {
		//add the tie and then run the updateTies routine

		if (note.tieState == TieState.NONE){
			note.tieState = TieState.START;
		}
		else if (note.tieState == TieState.STOP){
			note.tieState = TieState.CONTINUE;
		}
		else if (note.tieState == TieState.CONTINUE){
			note.tieState = TieState.STOP;
		}
		else {
			note.tieState = TieState.NONE;
		}

		var measure = note.noteGroup.voice.measure;
		List<Measure> measures = [measure];

		measure.notesNeedRendering = true;

		//if there's a following measure, update the ties in it as well
		var stack = measure.stack;
		if (stack.next != null){
			int measureIndex = stack.measures.indexOf(measure);
			var nextMeasure = stack.next.measures[measureIndex];
			measures[1] = nextMeasure;
			nextMeasure.notesNeedRendering = true;
		}

		//update the ties
		updateTies(measures);
	}


	/**
	 * adds the pitch to the specified NoteGroup
	 * @param noteGroup the NoteGroup to add the Note to
	 * @param pitchLetterName A, B, C, D, E, F, or G (uppercase)
	 * @param octave the octave for the note - C4 is middle C, the note below it is B3.
	 * @param alteration a value from -2 (double flat) to 2 (double sharp). This is an absolute alteration - not relative to the key signature's adjustment for this pitch.
	 */
	void addPitch(NoteGroup noteGroup, String pitchLetterName, int octave, int alteration) {
		var measure = noteGroup.voice.measure;

		//start to create the Note
		var newNote = new Note();
		newNote.pitchName = pitchLetterName + octave.toString();
		//newNote.displayCents = PitchTimeConverter.letterToCents(newNote.pitchName)  + (100 * alteration);
		newNote.displayCents = PitchUtils.pitchNameToDiatonicCents(newNote.pitchName) + (100 * alteration);
		if (noteGroup.voice.measure.staff.partRef.percussionMap != null){
			//check to see if this note is on a non-pitched percussion staff
			var percussionMap = noteGroup.voice.measure.staff.partRef.percussionMap;
			if (percussionMap[newNote.displayCents ~/ 100] != null){
				newNote.playbackCents = percussionMap[newNote.displayCents ~/ 100] * 100;
			}
			else if (percussionMap[0] != null){
				newNote.playbackCents = percussionMap[0] * 100;
			}
			else {
				newNote.playbackCents = 3800;
			}
		}
		//newNote.stepsFromTopStaffLine = PitchUtils.getStepsFromTopStaffLine(newNote.pitchName, measure.clefs[measure.staff.partRef.staves.indexOf(measure.staff)]);
		newNote.stepsFromTopStaffLine = PitchUtils.getStepsFromTopStaffLine(newNote.pitchName, measure.clefs[measure.clefs.length - 1].type);
		newNote.vPos = (_score.scoreProperties.staffLineSpacing / 2) * newNote.stepsFromTopStaffLine;
		newNote.alteration = alteration;
		newNote.legerLines = PitchUtils.getNumberOfLegerLines(newNote.stepsFromTopStaffLine);

		//if this was a whole rest, it might not actually be 4 beats
		if (noteGroup.durationType == DurationType.WHOLE && noteGroup.duration < 4096){
			var newDurationInfo = DurationType.getBaseDurationAndDots(noteGroup.duration);
			noteGroup.durationType = newDurationInfo[0];
			noteGroup.numDots = newDurationInfo[1];
		}


		//make sure our NoteGroup is not still a rest
		noteGroup.isRest = false;
		noteGroup.stemDirection = (noteGroup.duration < 4096)? StemDirection.DOWN : StemDirection.NO_STEM;

		//place the new note in order of pitch - lowest pitches first
		noteGroup.insertNote(newNote);

		//update the accidentals
		updateAccidentals(measure);

		measure.notesNeedRendering = true;
	}

	/**
	 * removes the Note from the NoteGroup
	 * @param noteGroup the NoteGroup to remove the Note from
	 * @param note the Note to remove
	 */
	void removePitch(NoteGroup noteGroup, Note note) {

		//remove the note
		noteGroup.removeNote(note);
		if (noteGroup.notes.length <= 0){
			//noteGroup.isRest = true;

			//remove the NoteGroup if it is empty and fill the measure with rests to close the gap
			var ngcToRemove = noteGroup.ngcRef;
			while (ngcToRemove.parentNGC != null &&
					ngcToRemove.parentNGC.tuplet.firstNote == noteGroup){
				ngcToRemove = ngcToRemove.parentNGC;
			}

			var removedNoteGroups = noteGroup.voice.removeNoteGroupContainer(ngcToRemove);
			//noteGroup.voice.removeNoteGroupContainer(noteGroup.ngcRef);
			if (noteGroup.voice.measure.staff.partRef.visible){
				for (var ng in removedNoteGroups){
					noteGroup.voice.measure.stack.removeNoteGroup(ng);
				}
			}
			//remove any slurs
			for (var ng in removedNoteGroups){
				for (var slur in ng.slurs){
					removeSlur(slur);
				}
			}
			fillMeasure(noteGroup.voice.measure);
		}

		//update the accidentals
		updateAccidentals(noteGroup.voice.measure);

		noteGroup.voice.measure.notesNeedRendering = true;
	}

	/**
	 * updates the accidentals in the measure so that all necessary accidentals are shown and unnecessary ones are hidden
	 * @param measure the Measure to update
	 */
	void updateAccidentals(Measure measure) {
		//we'll store the alteration for pitch we encounter in an array, indexed by its staff line position.
		Map<int, int> pitchHistory = {}; //attempting to use Dart map in place of AS3 Array

		var voices = measure.voices;
		for (var voice in voices){
			var noteGroups = voice.noteGroups;
			int numNoteGroups = noteGroups.length;
			for (int i = 0; i < numNoteGroups; i++){
				//var notes = noteGroups[i].notes;
				if (noteGroups[i].isRest){
					continue;
				}
				var notes = noteGroups[i].visibleNotes;
				for (var note in notes){
					//if our note finishes or continues a tie, it should not show the accidental
					if (note.tieState == TieState.CONTINUE || note.tieState == TieState.STOP){
						//note.accidental = AccidentalType.NONE;
						note.showAccidental = false;
						continue;
					}

					int pos =  note.stepsFromTopStaffLine + 50; //we add 50 to make sure we don't encounter any values less than 0
					//see if a note has already existed for this staff line position
					if (pitchHistory[pos] == null){
						//if a note hasn't existed on this staff line yet, we must check the key signature
						pitchHistory[pos] = PitchUtils.getKeySigAlterationForNote(note.pitchName[0], measure.displayKey);
					}

					if (pitchHistory[pos] == note.alteration){
						//if we match the last alteration noted for this pitch, either by a previous note or the key, we don't show an accidental
						//note.accidental = AccidentalType.NONE;
						note.showAccidental = false;
					}
					else {
						//otherwise we have to show our accidental, and we update the accidental state for this staff line/space
						note.accidental = AccidentalType.getAccidentalType(note.alteration);
						note.showAccidental = true;
						pitchHistory[pos] = note.alteration;
					}
				}
			}
		}
	}

	/**
	 * updates the ties in the measure region, getting rid of orphaned ties and changing the state of ties where necessary
	 * @param measure the measures to update (must be consecutive). The last note in the region will not be updated in terms
	 * of how it connects to the following measure.
	 */
	void updateTies(List<Measure> measures) {
		//first get all of the notes in the same voice between measures into a single list that we can go through in order
		var ngLists = new List<List<NoteGroup>>();
		int numMeasures = measures.length;
		for (int i = 0; i < numMeasures; i++){
			var voices = measures[i].voices;
			int numVoices = voices.length;
			for(int j = 0; j < numVoices; j++){
				var voice = voices[j];
				//it's possible for voices to be skipped in some measures, so we should go by the voice's number rather that index
				while (voice.number >= ngLists.length){
					ngLists.add(new List<NoteGroup>());
				}
				var ngList = ngLists[voice.number];
				int nextNGIndex = ngList.length;
				var noteGroups = voices[j].noteGroups;
				int numNoteGroups = noteGroups.length;
				for (int k = 0; k < numNoteGroups; k++){
					if (k < ngList.length){
						ngList[nextNGIndex] = noteGroups[k];
					}
					else {
						ngList.add(noteGroups[k]);
					}
					nextNGIndex++;
				}
			}
		}


		//now go through the lists of NoteGroups and update the ties
		int numLists = ngLists.length;
		for (int i = 0; i < numLists; i++){
			var ngList = ngLists[i];
			int numNoteGroups = ngList.length;
			//skip checking the last note - we can't cancel or add ties outside of our region as they connect to the following measure
			for (int j = 0; j < numNoteGroups - 1; j++){
				var ng = ngList[j];
				var nextNG = ngList[j + 1];
				var notes = ng.notes;
				int numNotes = notes.length;
				for (int k = 0; k < numNotes; k++){
					var note = notes[k];
					var nextNote = _getMatchingNoteInNextNoteGroup(note, nextNG);
					if (note.tieState == TieState.START || note.tieState == TieState.CONTINUE){ //our note starts or continues a tie
						if (nextNote != null){ //next note receives a tie - it should either be a Stop or a Continue, depending on what it was before
							if (nextNote.tieState == TieState.NONE){
								nextNote.tieState = TieState.STOP;
							}
							else if (nextNote.tieState == TieState.START){
								nextNote.tieState = TieState.CONTINUE;
							}
						}
						else { //no note to tie to! convert to either a tie end (if we were previously a continue) or get rid of our tie
							if (note.tieState == TieState.CONTINUE){
								note.tieState = TieState.STOP;
							}
							else {
								note.tieState = TieState.NONE;
							}
						}
					}
					else { //our note ends a tie or doesn't have one
						if (nextNote != null){
							//with no tie received, the best we can hope for is to change a continue state to a start
							if (nextNote.tieState == TieState.CONTINUE){
								nextNote.tieState = TieState.START;
							}
							else if (nextNote.tieState == TieState.START){
								//leave it as a start tie
							}
							else { //if we were previously a Stop, we must now be a None
								nextNote.tieState = TieState.NONE;
							}
						}
					}
				}
			}
		}

	}
	
	Note _getMatchingNoteInNextNoteGroup(Note firstNote, NoteGroup nextNoteGroup) {
		var nextNotes = nextNoteGroup.notes;
		for (var nxNote in nextNotes){
			if (nxNote.pitchName == firstNote.pitchName && nxNote.alteration == firstNote.alteration){
				return nxNote;
			}
		}
		return null;
	}


	/**
	 * For music coming from MusicXML, this creates NoteGroupContainer objects for NoteGroups and Tuplets,
	 * adding relative time stamps and creating a hierarchy that makes it possible to fill measures with rests
	 */
	void createNoteGroupContainers() {
		//create NoteGroupContainer objects that house NoteGroups and Tuplets in a hierarchical structure


		for (var part in _score.parts){
			for (var staff in part.staves){
				var measures = staff.measures;
				for (var measure in measures){
					var voices = measure.voices;
					for (var voice in voices){
						var topContainer = new NoteGroupContainer();
						topContainer.ngcList = [];

						addNotesToContainer(topContainer.ngcList, null, voice.noteGroups, 0);

						voice.noteGroupContainers = topContainer.ngcList;
					}
				}
			}
		}

	}

	/**
	 * updates the start time values for NoteGroups and their NoteGroupContainers by the specified deltaTime value. Any containers
	 * with an end time beyond the end of the measure are deleted
	 * @param ngcList the list of NoteGroupContainers to adjust
	 * @param deltaTime the amount to adjust the times by (this value is added to their current qNote times)
	 * @param measureEndTime the qnote end time of the measure
	 * @param voiceRef the Voice object to which the NGCs and NoteGroups belong
	 * @param checkEndTimes set to true if you want check the end times of NoteGroupContainers and remove the ones that hang over the end
	 */
	void changeNoteGroupTimeStamps(List<NoteGroupContainer> ngcList, num deltaTime, num measureEndTime, Voice voiceRef, bool checkEndTimes) {
		/*if (ngcList.length == 4 && voiceRef.measure.stack.number == 3){
			trace("here");
		}*/
		for (int i = ngcList.length - 1; i >= 0; i--){
			var ngc = ngcList[i];

			//set the new start time of the note.
			ngc.qNoteStartTime += deltaTime;

			//calculate the new end time of the ngc to see if it extends beyond the end of the measure - we really only need to do this for the top
			//layer of NGC's, as we never allow a partial tuplet.
			if (checkEndTimes){
				num tupletRatio = 1;
				var parentNGC = ngc.parentNGC;
				while (parentNGC != null){ //this code should never execute, because we'll only do the checkEndTimes on the first level - not recursively
					var tuplet = parentNGC.tuplet;
					tupletRatio *= ((tuplet.denominator / tuplet.numerator) * (tuplet.denominatorDuration / tuplet.numeratorDuration));
					parentNGC = parentNGC.parentNGC;
				}
				num ngcEndTime = ngc.qNoteStartTime + (((ngc.durUnitEndTime - ngc.durUnitStartTime) / 1024) * tupletRatio);

				//if the new end time is greater than the end of the measure time, we have to delete it
				if (ngcEndTime > measureEndTime){
					//this removes all sub children as well, so we won't want to do a recursive search or update time stamps
					var removedNoteGroups = voiceRef.removeNoteGroupContainer(ngc);
					for (var ng in removedNoteGroups){
						voiceRef.measure.stack.removeNoteGroup(ng);
						if (ng.slurs != null){
							for (var slur in ng.slurs){
								removeSlur(slur);
							}
						}
					}
					continue;
				}
			}

			//okay, we're still in time bounds. Now we either update the ng for this ngc or do a recursive call for child objects to update their times
			if (ngc.noteGroup != null){
				ngc.noteGroup.qNoteTime += deltaTime;
			}
			else {
				//recursive call for child containers
				changeNoteGroupTimeStamps(ngc.ngcList, deltaTime, measureEndTime, voiceRef, false);
			}
		}
	}

	/**
	 * fills the measure's blank areas with rests
	 * @param	measure the Measure object to fill
	 */
	void fillMeasure(Measure measure) {
		int measureDuration = (measure.numBeats * (1024 * (4 / measure.beatType))).toInt(); //the duration of the measure in Duration Units
		for (var voice in measure.voices) {
			//first check to see if the Voice is empty - if it is, place a whole rest in it that has a value equal to the duration of the measure
			if (voice.noteGroupContainers == null || voice.noteGroupContainers.length == 0){
				//create the NoteGroup
				var noteGroup = new NoteGroup();
				noteGroup.qNoteTime = measure.stack.startTime;
				noteGroup.qNoteDuration = measureDuration / 1024;
				noteGroup.duration = measureDuration;
				noteGroup.durationType = DurationType.WHOLE;
				noteGroup.isRest = true;
				//noteGroup.restVPos = _score.scoreProperties.staffLineSpacing * 2;

				voice.addNoteGroup(noteGroup); //add it to the voice
				if (measure.staff.partRef.visible){ //add it to the stack if this measure is in a visible part
					measure.stack.addNoteGroup(noteGroup);
				}
				

				//create the NoteGroupContainer to hold it
				var ngc = new NoteGroupContainer();
				ngc.noteGroup = noteGroup;
				ngc.durUnitStartTime = 0;
				ngc.durUnitEndTime = measureDuration;
				ngc.parentNGC = null;
				ngc.qNoteStartTime = noteGroup.qNoteTime;

				noteGroup.ngcRef = ngc;

				//create a new list to store the NoteGroupContainers for this voice and add the ngc
				voice.noteGroupContainers = [ngc];
			}
			else {
				//if the voice isn't empty, we must check for gaps.

				//we need to send in a list of the beat positions in the measure so any gaps can be filled with appropriately sized rests
				List<int> beatPositions = [];
				var beatGroups = measure.beatGroups;
				for (int i = 0; i < beatGroups.length; i++){
					beatPositions.add((beatGroups[i] * 1024).toInt()); //convert our beat positions to duration unit times
				}
				int maxRestSize = 1024 * (4 ~/ measure.beatType);
				checkLevelForGaps(voice.noteGroupContainers, null, 0, measureDuration, voice, beatPositions, maxRestSize, measure.stack.startTime, 1);
			}
		}
		
		//EXPERIMENTAL 3/22/2015
		//clear NoteGroup next/prev cache
		for (var voice in measure.voices){
			var ngList = voice.noteGroups;
			if (ngList != null){
				for (int i = 0; i < ngList.length; i++){
					var ng = ngList[i];
					ng.clearNextPrevNGCaches();
					if (i == 0){
						var prevNG = ng.prev;
						if (prevNG != null){
							prevNG.clearNextPrevNGCaches();
						}
					}
					else if (i == ngList.length - 1){
						var nextNG = ng.next;
						if (nextNG != null){
							nextNG.clearNextPrevNGCaches();
						}
					}
				}
			}
		}
	}

	/**
	 * adds a slur between two notes
	 * @param ng1 the first NoteGroup
	 * @param ng2 the second NoteGroup
	 */
	void addSlur(NoteGroup ng1, NoteGroup ng2) {
		//make sure this slur obeys our restrictions
		if (ng1 == null || ng2 == null || ng1.isRest || ng2.isRest || ng1.voice.number != ng2.voice.number ||
						ng1.voice.measure.staff != ng2.voice.measure.staff || ng1 == ng2 || ng1.qNoteTime == ng2.qNoteTime){
			return;
		}

		//create the slur and assign the notegroups as its first and end notes, depending on which one comes first
		var slur = new Slur();
		if (ng1.qNoteTime < ng2.qNoteTime){
			slur.firstNote = ng1;
			slur.endNote = ng2;
		}
		else {
			slur.firstNote = ng2;
			slur.endNote = ng1;
		}

		//add the slur to the noteGroups' slur lists
		if (ng1.slurs != null){
			ng1.slurs.add(slur);
		}
		else {
			ng1.slurs = [slur];
		}

		if (ng2.slurs != null){
			ng2.slurs.add(slur);
		}
		else {
			ng2.slurs = [slur];
		}

		//mark the measures for rendering
		ng1.voice.measure.notesNeedRendering = true;
		ng2.voice.measure.notesNeedRendering = true;

		//assign an ID to the slur - The slurID is only used by MusicXML, and its numbering convention is unreliable, so we'll leave this out.
		//slur.slurID = Math.max(ng1.slurs.length, ng2.slurs.length);
	}

	/**
	 * removes a Slur from the score
	 * @param slur the Slur to remove
	 */
	void removeSlur(Slur slur) {
		var ng1 = slur.firstNote;
		var ng2 = slur.endNote;
		var segments = slur.segments;

		//remove the slur from each noteGroup's slur list
		if (ng1 != null && ng1.slurs != null){
			ng1.slurs.removeAt(ng1.slurs.indexOf(slur));
			if (ng1.slurs.length == 0){
				ng1.slurs = null;
			}
		}
		if (ng2 != null && ng2.slurs != null){
			ng2.slurs.removeAt(ng2.slurs.indexOf(slur));
			if (ng2.slurs.length == 0){
				ng2.slurs = null;
			}
		}

		//mark the measures for rendering
		ng1.voice.measure.notesNeedRendering = true;
		ng2.voice.measure.notesNeedRendering = true;

		//remove the slur's segments from the systems
		SlurSegment segment;
		for (segment in segments){
			segment.systemRef.slurSegments.removeAt(segment.systemRef.slurSegments.indexOf(segment));
		}
		if (segment.systemRef.slurSegments.length == 0){
			segment.systemRef.slurSegments = null;
		}
	}


	/**
	 * checks the contents of one NoteGroupContainer for gaps - calls itself recursively for sub levels
	 * @param ngcList the list of NoteGroupContainer objects for the current level, including containers that hold NoteGroups and Tuplets
	 * @param parentNGC the NoteGroupContainer object that stores the ngcList - this will contain any tuplet information for notes in the ngcList as well as the parent's start time in duration units
	 * @param startTime the expected start time in duration units
	 * @param endTime the expected end time in duration units
	 * @param voice the voice to add any rests to
	 * @param beatPositions the positions of the beat divisions, where rests will need to be split - in duration units
	 * @param maxRestSize the max ordinary rest size, in duration units. Note that rests which occupy a full beat may exceed this (like a dotted rest in compound meters)
	 */
	void checkLevelForGaps(List<NoteGroupContainer> ngcList, NoteGroupContainer parentNGC, int startTime, int endTime, Voice voice,
									   List<int> beatPositions, int maxRestSize, num parentNGCQNoteTime, num tupletRatio) {
		//we have created a hierarchy for our noteGroup objects according to the tuplets they are found in
		//ng
		//ng
		//tuplet - ng
		//		 - ng
		//		 - tuplet - ng
		//		 -		  - ng
		//		 -		  - ng
		//		 - ng
		//ng
		//ng

		//we have modeled this by using NoteGroupContainer objects that can contain a single NoteGroup OR a list of NoteGroupContainer objects along with a Tuplet definition
		//ngc (ng)
		//ngc (ng)
		//ngc (ngcList/Tuplet)
		//		 - ngc
		//etc.

		//when we fill with rests, we use a recursive approach to go through each level of NoteGroupContainers. A measure with no tuplets would have only the top layer (and
		//no recursion would occur). With a single tuplet, a single recursive call happens, and so forth.


		//go through the noteGroupContainers in this level in reverse order and check for gaps that must be filled
		int numContainers = ngcList.length;
		for (int i = numContainers - 1; i >= 0; i--){
			var ngc = ngcList[i];
			if (ngc.durUnitEndTime < endTime){ //if there is a gap between the note and our current end position...
				//call fill gap with rests routine
				fillGapWithRests(ngc.durUnitEndTime, endTime, voice, ngcList, i + 1, beatPositions, maxRestSize, parentNGC, parentNGCQNoteTime, tupletRatio);
			}

			//check to see if this container is a tuplet that needs to be dealt with in a recursive call
			if (ngc.ngcList != null){
				//for tuplets, the beat positions are based on the base note type of the tuplet
				var tuplet = ngc.tuplet;
				List<int> subTupletBeatPositions = [];
				for (int j = 0; j < tuplet.numerator; j++){
					subTupletBeatPositions.add(j * tuplet.numeratorDuration);
				}
				int subTupletMaxRestSize = tuplet.numeratorDuration;
				num subTupletRatio = tupletRatio * ((tuplet.denominator / tuplet.numerator) * (tuplet.denominatorDuration / tuplet.numeratorDuration));
				int unadjustedEndtime = ((ngc.durUnitEndTime - ngc.durUnitStartTime) *
					(tuplet.numerator / tuplet.denominator) *
					(tuplet.numeratorDuration / tuplet.denominatorDuration)).truncate();
				checkLevelForGaps(ngc.ngcList, ngc, 0, unadjustedEndtime, voice, subTupletBeatPositions, subTupletMaxRestSize, ngc.qNoteStartTime, subTupletRatio);
			}

			//update the end time to be the start of this container so that we can check for the next gap
			endTime = ngc.durUnitStartTime;
		}

		//now check for a gap before the first NGC
		if (endTime > startTime){
			fillGapWithRests(startTime, endTime, voice, ngcList, 0, beatPositions, maxRestSize, parentNGC, parentNGCQNoteTime, tupletRatio);
		}
	}

	void fillGapWithRests(int startPoint, int endPoint, Voice voice, List<NoteGroupContainer> ngcList, int ngcListIndex,
									  List<int> beatPositions, int maxRestSize, NoteGroupContainer parentNGC, num parentNGCQNoteTime, num tupletRatio) {
		//working backwards from endPoint to startPoint, we create rests that are no bigger than a beat and which don't overlap beat boundaries
		int currentPos = endPoint; //the current position that we are trying to fill up to (it marks the end point of the next rest we add)
		while (currentPos > startPoint){
			int beatIndex = 0;
			int beatPos = beatPositions[0];
			while(beatIndex + 1 < beatPositions.length && beatPositions[beatIndex + 1] < currentPos){
				beatIndex++;
				beatPos = beatPositions[beatIndex];
			}

			//now we attempt to fill a gap back to our beat position, unless the startPoint is ahead of it.
			int goalPos = (beatPos > startPoint)? beatPos : startPoint; //represents the position we'd like to be at after adding the next rest
			int goalRestSize = currentPos - goalPos;

			//the goal rest size is the amount we WANT to fill with a single rest if possible. If we're not allowed
			//to do that, we will settle for a smaller rest

			//see if the size of our goal rest duration is the width of a beat – this can give it special permission
			//for dotting

			//first figure out how big a beat is
			int beatSize;
			if (beatIndex < beatPositions.length - 1){
				beatSize = (beatPositions[beatIndex + 1]) - beatPos;
			}
			else {
				beatSize = endPoint - beatPos;
			}

			int restSize;
			NoteGroup ng;
			//now see if the goalRestSize is as big as a beat
			if (goalRestSize == beatSize){
				//if it's a full beat, it gets a single rest, even if it means being dotted
				restSize = beatSize;
				currentPos = goalPos;
			}
			else if (goalRestSize < beatSize){
				//if it's less than a full beat, we decide what size rest to use based on whether it's a compound
				//beat or not
				restSize = maxRestSize;
				while (restSize > goalRestSize){
					restSize ~/= 2;
				}
				ng = getRestBySize(restSize);
				currentPos -= restSize;
			}
			else {
				//shouldn't get here.
			}

			//create our rest
			ng = getRestBySize(restSize);
			ng.qNoteTime = parentNGCQNoteTime + ((currentPos * tupletRatio) / 1024); //calculate the qNoteTime based on the parent container, the new rest's position, and the tuplet ratio
			ng.qNoteDuration = (ng.duration / 1024) * tupletRatio;
			ng.voice = voice;

			//get the tuplets for the NoteGroup
			var superNGC = parentNGC;
			if (superNGC != null){
				List<Tuplet> tuplets = [];
				while(superNGC != null && superNGC.tuplet != null){
					tuplets.add(superNGC.tuplet);
					superNGC = superNGC.parentNGC;
				}
				ng.tuplets = tuplets.reversed;
				for (var tuplet in tuplets){
					if (ng.qNoteTime > tuplet.endNote.qNoteTime){
						tuplet.endNote = ng;
					}
					else if (ng.qNoteTime < tuplet.firstNote.qNoteTime){
						tuplet.firstNote = ng;
					}
				}
			}

			//create the NoteGroupContainer for the rest
			var ngc = new NoteGroupContainer();
			ngc.noteGroup = ng;
			ngc.durUnitStartTime = currentPos;
			ngc.durUnitEndTime = currentPos + restSize;
			ngc.qNoteStartTime = ng.qNoteTime;
			ngc.parentNGC = parentNGC;

			ng.ngcRef = ngc;

			ngcList.insert(ngcListIndex,  ngc);

			//insert the ng in the voice
			var noteGroups = voice.noteGroups;
			int numNotes = noteGroups.length;
			int i = 0;
			for (i = numNotes - 1; i >= 0; i--){
				if (noteGroups[i].qNoteTime < ng.qNoteTime){
					break;
				}
			}
			noteGroups.insert(i + 1, ng);

			//insert the ng into the MeasureStack if this Part is visible
			if (voice.measure.staff.partRef.visible){
				voice.measure.stack.addNoteGroup(ng);
			}

		}
	}

	NoteGroup getRestBySize(int goalSize) {
		int baseDuration = 16;
		while (baseDuration < goalSize){
			baseDuration *= 2;
		}

		if (baseDuration > goalSize){
			baseDuration ~/= 2;
		}

		int numDots = 0;
		int dotsValue = baseDuration ~/ 2;
		int totalDuration = baseDuration;
		while (totalDuration < goalSize){
			numDots++;
			totalDuration += dotsValue;
			dotsValue ~/= 2;
		}

		var ng = new NoteGroup();
		ng.duration = goalSize;
		ng.numDots = numDots;
		ng.isRest = true;
		//ng.restVPos = _score.scoreProperties.staffLineSpacing * 2;

		ng.durationType = baseDuration;

		return ng;
	}



	void addNotesToContainer(List<NoteGroupContainer> ngcList, NoteGroupContainer parentNGC,
										 List<NoteGroup> notes, int tupletIndex) {
		int cTime = 0;
		List<NoteGroup> subTupletNGList = []; //for child tuplets
		for (var ng in notes){
			//ng.duration = (ng.duration / ng.partsDPQ) * 1024; //convert to 1024 qnote dur unit time
			//ng.partsDPQ = 1024; //temporary - we should get rid of the need for this
			if (ng.tuplets != null && ng.tuplets.length > tupletIndex){
				subTupletNGList.add(ng);
				if (ng.tuplets[tupletIndex].endNote == ng){
					var subTupletNGC = new NoteGroupContainer();
					subTupletNGC.tuplet = ng.tuplets[tupletIndex];
					subTupletNGC.ngcList = [];
					subTupletNGC.qNoteStartTime = subTupletNGList[0].qNoteTime;
					subTupletNGC.durUnitStartTime = cTime;
					cTime += subTupletNGC.tuplet.denominatorDuration * subTupletNGC.tuplet.denominator;
					subTupletNGC.durUnitEndTime = cTime;
					subTupletNGC.parentNGC = parentNGC;
					addNotesToContainer(subTupletNGC.ngcList, subTupletNGC, subTupletNGList, tupletIndex + 1);
					ngcList.add(subTupletNGC);
					subTupletNGList = [];

				}
			}
			else {
				var ngc = new NoteGroupContainer();
				ng.ngcRef = ngc;
				ngc.noteGroup = ng;
				ngc.qNoteStartTime = ng.qNoteTime;
				ngc.durUnitStartTime = cTime;
				ngc.parentNGC = parentNGC;
				cTime += DurationType.getDurationValue(ng.durationType, ng.numDots);
				ngc.durUnitEndTime = cTime;
				ngcList.add(ngc);
			}
		}
	}
}

