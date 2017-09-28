part of score_data.music_creation;

class ScoreManager	{
	/*[Embed(source = "DefaultScoreSettings.xml", mimeType="application/octet-stream")]
	private const SCORE_SETTINGS_XML:Class;*/
	
	//private const DEFAULT_DPQ:int = 26880;
	
	Score _score;

	NoteManager _noteManager;
	TranspositionManager _transpositionManager;
	PitchNameManager _pitchNameManager;
	
	ScoreManager() {
	}

	////////////////////////////////TRANSPOSITION//////////////////////////////
	///prevents transposition of all parts set to midiChannel 10
	void preventPercussionTransposition() {
		_transpositionManager.preventPercussionTransposition();
	}

	/**
	 * Changes the octave of each note in a list. This is intended to operate
	 * on all of the notes in a single part, staff and voice and should not be
	 * used on a sub-selection of notes or notes from multiple parts, staves, or
	 * voices.
	 * @param octaveShiftValues a List<int> with each value designating the
	 * number of octaves to transpose each corresponding note.
	 * @param ngsNoTieIntosOrRests - a List<NoteGroup> that contains all the
	 * NoteGroups from one part/staff/voice which aren't rests and which aren't
	 * the target (landing spot) of ties. This list is typically obtained via
	 * calling Part.getNoteGroupsWithoutRestsOrTieIntos().
	 */
	void adjustOctavesOfNotes(List<int> octaveShiftValues,
		List<NoteGroup> ngsNoTieIntosOrRests) {

		_transpositionManager.adjustOctavesOfNotes(octaveShiftValues,
			ngsNoTieIntosOrRests);
	}

	/**
	 * transposes all of the notes in a given part by the specifed number
	 * of octaves.
	 * @octaveDelta - +1 for up one octave, -1 for down one octave, etc.
	 */
	void changeOctaveOfPart(Part part, int octaveDelta){
		_transpositionManager.changeOctaveOfPart(part, octaveDelta);
	}

	///transposes the entire song by the relative amount specified
	///positive values for chromaticShift/diatonicShift transpose the song up, negative down
	///values are relative, so 2,1 always transposes the song up a whole step from its current key
	///changes concertKey, displayKey, and transposes notes
	///@preventInitialKeyOptimization - if you want the first region's key to be exactly what you set without
	///looking for a better enharmonic equivalent, set this to true
	///@playbackOctaveCorrection - this option will adjust the
	///Part.playbackOctaveDelta property for each part by one or
	///more octaves to minimize the transposition's effect on the playback pitch.
	void transposeSong(int diatonicShift, int chromaticShift,
			[bool preventInitialKeyOptimization = false,
			int playbackOctaveDelta = 0]){
		_transpositionManager.transposeSong(chromaticShift, diatonicShift,
			preventInitialKeyOptimization, playbackOctaveDelta);
		_pitchNameManager.updateNoteNames();
	}

	///sets the transposition for the requested part, transposing the notes and display key
	///chromaticTrans and diatonicTrans are absolute values, not relative shifts. So trumpet
	///should always be 2 and 1 (the amount the transposed pitches APPEAR above concert pitch
	void setPartTransposition(Part part, int chromaticTrans, [int diatonicTrans = null]){
		_transpositionManager.setPartTransposition(part, chromaticTrans, diatonicTrans);
		_pitchNameManager.updateNoteNames();
	}

	///transposes the entire song to the specified key, proportionally changing key signatures
	///that happen after the first measure
	///@newConcertKey - the new concert key (3 would be 2 sharps, -2 would be 2 flats)
	///@transposeDirection - matches constant from TransposeDirection class - 0 is NEAREST
	///returns a TranspositionDO object with the chromatic/diatonic steps used for the transposition
	void setConcertKeyOfSong(int newConcertKey, [int transposeDirection = 0]){
		//var tdo = _transpositionManager.setConcertKeyOfSong(newConcertKey, transposeDirection);
		_transpositionManager.setConcertKeyOfSong(newConcertKey, transposeDirection);
		_pitchNameManager.updateNoteNames();

		//return tdo;
	}

	/**
	 * reverts transpositions that were performed by transposeSong(),
	 * setConcertKeyOfSong(), changeOctaveOfPart(), and adjustOctavesOfNotes()
	 * @param steps - the number of steps in the transposition history to undo.
	 * If 0 (default), all transpositions will be undone.
	 */
	void revertTranspositions([int steps = 0]) {
		_transpositionManager.revertTranspositions(steps);
	}

	//////////////////////////////NOTE NAMES/LYRICS////////////////////////////

	/**
	 * reverts pitch names to original lyrics (if showNoteNames() was called)
	 */
	void showLyrics(){
		_pitchNameManager.showLyrics();
	}

	/**
	 * replaces lyrics with pitch names for each note
	 */
	void showNoteNames(Staff staff) {
		_pitchNameManager.showNoteNames(staff);
	}

	///////////////////////////////SCORE CREATION//////////////////////////////
	
	/**
	 * creates a new Score object, populates its scoreSettings property and creates a single first measure
	 * @param	scoreSettings optional set of data for setting ScoreProperties values
	 */
	void createScore([ScoreProperties scoreSettings = null]) {
		//create the score object
		this.score = new Score();
		//_score = new Score();
		//_noteManager = new NoteManager(_score);
		
		//create the ScoreProperties object
		if (scoreSettings != null) {
			_score.scoreProperties = scoreSettings;
		}
		else {
			_score.scoreProperties = ScoreProperties.getNewScoreProperties();
		}
		
		//create the first page, system, part, staff, measure stack and measure
		var page = new Page();
		var system = new System(_score.scoreProperties);
		system.newPage = true;
		page.addSystem(system);
		_score.addPage(page);
		
	}
	
	/**
	 * adds the part to the score
	 * @param	name the name of the part
	 * @param	abbr abbreviated name of the part
	 * @param	diatonicTransposition number of diatonic steps that this part appears below concert pitch (- values for appearing above)
	 * @param	chromaticTransposition number of chromatic steps that this part sounds above concert pitch (- values for sounding below)
	 * @return
	 */
	Part addPart(String name, String abbr, int diatonicTransposition, int chromaticTransposition) {
		String partID = "P" + (_score.parts.length + 1).toString();
		var part = new Part(partID, name, abbr);
		//part.diatonicTransposition = diatonicTransposition;
		//part.chromaticTransposition = chromaticTransposition;
		part.setTransposition(diatonicTransposition, chromaticTransposition, false);
		
		_score.addPart(part);
		return part;
	}
	
	/**
	 * adds a new staff to the part
	 * @param	part the Part to add a staff to
	 */
	Staff addStaff(Part part) {
		var staff = new Staff();
		part.addStaff(staff);
		return staff;
	}
	
	/**
	 * adds the measure at the position indicated
	 * @param	positionIndex the index to insert the measure at - if greater than the number of measures in the song, it is just added to the end
	 * @return
	 */
	MeasureStack addMeasureStack([int positionIndex = 0xFFFFFF]) {
		if (_score.parts.length < 1 || _score.parts[0].staves.length < 1) {
			throw ("No parts and/or staves have been added to the score - you must add a part and a staff before adding measure stacks");
		}
		
		var firstStaff = _score.parts[0].staves[0];
		

		int numExistingMeasures = firstStaff.measures.length;

		positionIndex = numExistingMeasures; //TEMPORARY OVERRIDE CODE - WE DON'T HAVE CODE HERE YET FOR MOVING NOTES FORWARD TO ACCOMMODATE INSERTION

		//make sure the requested positionIndex is within bounds
		if (positionIndex > numExistingMeasures || positionIndex < 0) {
			positionIndex = numExistingMeasures;
		}
		
		//create the new stack and get the previous and next stacks
		var newStack = new MeasureStack();
		MeasureStack prevStack;
		if (numExistingMeasures > 0) {
			var prevStack = firstStaff.measures[numExistingMeasures - 1].stack;
			prevStack.systemRef.addStackAfterExistingStack(newStack, prevStack); //add the new stack to the same system as the previous stack (this links the stacks as well)
			
			//copy data from the previous stack
			newStack.startTime = prevStack.endTime;
			newStack.endTime = prevStack.endTime + prevStack.dpqLength;
			newStack.maxKeySize = prevStack.maxKeySize;
		}
		else {
			//with no previous measure, default to 4/4 time
			newStack.startTime = 0;
			newStack.endTime = 4;
			newStack.maxKeySize = 0;
			newStack.newSystem = true;
			newStack.newClef = true;
			newStack.newKey = true;
			//newStack.newTime = true;

			//add the stack to the first system
			_score.pages[0].systems[0].addMeasureStack(newStack);
		}
		
		
		//set the measure number
		newStack.number = positionIndex + 1;
		
		//now create a measure for every staff
		int staffIndex = 0; //the current staff we're adding a measure to
		for (var part in _score.parts) {
			for (var staff in part.staves) {
				var newMeasure = new Measure();
				if (prevStack != null) {
					var prevMeasure = prevStack.measures[staffIndex];
					newMeasure.beatGroups = prevMeasure.beatGroups.sublist(0);
					newMeasure.beatType = prevMeasure.beatType;
					newMeasure.numBeats = prevMeasure.numBeats;

					newMeasure.displayKey = prevMeasure.displayKey;
					newMeasure.concertKey = prevMeasure.concertKey;
					newMeasure.isMajorKey = prevMeasure.isMajorKey;
					newMeasure.diatonicTransposition = prevMeasure.diatonicTransposition;
					newMeasure.chromaticTransposition = prevMeasure.chromaticTransposition;
					//newMeasure.transposition = prevMeasure.transposition;

					//newMeasure.clefs = prevMeasure.clefs.slice();
					var clef = new Clef();
					clef.type = prevMeasure.clefs[prevMeasure.clefs.length - 1].type;
					clef.qNoteTime = newStack.startTime;
					newMeasure.clefs.add(clef);
				}
				else {
					//with no previous measure, default to 4/4 time
					newMeasure.beatGroups = [0, 1, 2, 3];
					newMeasure.beatType = 4;
					newMeasure.numBeats = 4;
					newMeasure.showTime = true;

					newMeasure.concertKey = 0;
					newMeasure.displayKey = PitchUtils.getKeySigAlterationForTransposition(part.diatonicTransposition, part.chromaticTransposition);
					newMeasure.diatonicTransposition = part.diatonicTransposition;
					newMeasure.chromaticTransposition = part.chromaticTransposition;
					newMeasure.isMajorKey = true;

					int keySize = newMeasure.displayKey.abs();
					if (keySize > newStack.maxKeySize){
						newStack.maxKeySize = keySize;
					}
					
					var clef = new Clef();
					clef.isNew = true;
					clef.show = true;
					clef.type = ClefType.TREBLE;
					clef.qNoteTime = 0;
					newMeasure.clefs.add(clef);
				}
				
				//set the references and add the Measure to the stack and the staff
				newMeasure.stack = newStack;
				newStack.addMeasure(newMeasure);
				staff.insertMeasure(newMeasure, positionIndex);
				
				//assign an initial voice to the measure and fill it with rests
				newMeasure.getVoiceByNumber(1);
				_noteManager.fillMeasure(newMeasure);
				
				staffIndex++;
			}
		}
		
		return newStack;
		
	}

	void deleteMeasures(Measure firstMeasure, Measure lastMeasure) {
		int startIndex = firstMeasure.staff.measures.indexOf(firstMeasure);
		int endIndex = lastMeasure.staff.measures.indexOf(lastMeasure);

		//remove the measures
		var parts = _score.parts;
		for (var part in parts){
			var staves= part.staves;
			for (var staff in staves){
				var measures = staff.measures;
				for (int i = endIndex; i >= startIndex; i--){
					//check for connections between notes in these measures and other measures, such as slurs
					var voices = measures[i].voices;
					for (var cVoice in voices){
						var cNoteGroups = cVoice.noteGroups;
						for (var cng in cNoteGroups){
							for (var slur in cng.slurs){
								removeSlur(slur);
							}
						}
					}
					
					//remove the measure
					staff.removeMeasureAt(i);
				}

				//if a measure follows our deleted region, we have to check its properties to see if things like clefs, key and time sigs
				//need to be shown
				if (measures.length > startIndex){
					var nextMeas = measures[startIndex];
					if (startIndex > 0){
						var prevMeas = measures[startIndex - 1];

						if (nextMeas.beatType != prevMeas.beatType || nextMeas.numBeats != prevMeas.numBeats){
							nextMeas.showTime = true;
							//nextMeas.stack.newTime = true;
						}
						if (nextMeas.concertKey != prevMeas.concertKey){
							nextMeas.showKey = true;
							nextMeas.stack.newKey = true;
						}
						if (nextMeas.clefs[0].type != prevMeas.clefs[prevMeas.clefs.length - 1].type){
							nextMeas.clefs[0].show = true;
							nextMeas.stack.newClef = true;
						}
					}
					else {
						nextMeas.showTime = true;
						//nextMeas.stack.newTime = true;

						nextMeas.showKey = true;
						nextMeas.stack.newKey = true;

						nextMeas.clefs[0].show = true;
						nextMeas.stack.newClef = true;
					}
				}
			}
		}

		//remove the stacks
		var stacks = _score.getMeasureStacks();
		num totalTime = 0; //the total amount of time (in qNotes) that we remove - needed for updating time stamps
		for (int i = endIndex; i >= startIndex; i--){
			var stack = stacks[i];
			stack.systemRef.needsRendering = true;
			totalTime += stack.dpqLength;
			stack.systemRef.removeStack(stacks[i]);
		}

		totalTime *= -1;

		//update the time stamps on the stacks

		stacks = _score.getMeasureStacks(); //do this again, since our stacks variable is a newly created vector, not linked to the Score object
		if (startIndex < stacks.length){

			stacks[startIndex].needsRendering = true;

			int numMeasures = stacks.length;
			for (int i = startIndex; i < numMeasures; i++){
				var stack = stacks[i];
				stack.startTime += totalTime;
				stack.endTime += totalTime;
			}

			//update the time stamps on the notes

			for (int i = startIndex; i < numMeasures; i++){
				for (var part in parts){
					var staves = part.staves;
					for (var staff in staves){
						var measure = staff.measures[i];
						for (var voice in measure.voices){
							_noteManager.changeNoteGroupTimeStamps(voice.noteGroupContainers, totalTime,
																	measure.stack.endTime, voice, true);
						}
					}
				}
			}
		}
	}

	void changeTime(MeasureStack firstMeasureStack, MeasureStack lastMeasureStack, int numBeats, int beatType, List<num> beatGroups) {
		//find the starting and ending indexes of our measures
		var stacks = _score.getMeasureStacks();
		int startMeasureIndex = (firstMeasureStack != null)? stacks.indexOf(firstMeasureStack) : 0;
		int endMeasureIndex = (lastMeasureStack != null)? stacks.indexOf(lastMeasureStack) : stacks.length - 1;

		if (startMeasureIndex == -1 || endMeasureIndex == -1){
			return; //make sure we have valid indexes
		}

		//set the new time property for the stacks in the region
		//if there was a previous measure, and its time already matched the one we are now setting, the first stack should not show a new time
		//otherwise this is either the first stack in the piece or a stack with a different time - in either case, we must show the time
		MeasureStack prevStack = (startMeasureIndex > 0)? stacks[startMeasureIndex - 1] : null;
		var firstStack = stacks[startMeasureIndex];
		bool showTime = !(prevStack != null && prevStack.measures[0].numBeats == numBeats && 
							prevStack.measures[0].beatType == beatType);
		//firstStack.newTime = !(prevStack != null && prevStack.measures[0].numBeats == numBeats && prevStack.measures[0].beatType == beatType);
		for (var measure in firstStack.measures){
			//measure.showTime = firstStack.newTime;
			measure.showTime = showTime;
		}

		//if there is a measure following the changed region, it will need to show the time if it differs
		if (endMeasureIndex < stacks.length - 1){
			var nextStack = stacks[endMeasureIndex + 1];
			bool showTime = nextStack.measures[0].numBeats != numBeats || nextStack.measures[0].beatType != beatType;
			//nextStack.newTime = nextStack.measures[0].numBeats != numBeats || nextStack.measures[0].beatType != beatType;
			nextStack.measures[0].notesNeedRendering = true;

			for (var measure in nextStack.measures){
				//measure.showTime = nextStack.newTime;
				measure.showTime = showTime;
			}
		}

		//all of the other stacks in the region will have newKey set to false
		for (int i = startMeasureIndex + 1; i <= endMeasureIndex; i++){
			//stacks[i].newTime = false;
			//added measure showTime update on 3/19/2015
			for (var measure in stacks[i].measures){
				measure.showTime = false;
			}
		}

		//update the start and end times for each stack. For the stacks within the region, we use the new time signature to calculate the length
		//of each measure. For measures that follow our region, we use their current time signatures to get their length again.
		//we'll track the current offset for each stack so that we can apply it to the notes without recalculating
		int numStacks = stacks.length;
		List<num> timeOffsets = [];
		for (int i = 0; i < numStacks - startMeasureIndex; i++){
			timeOffsets.add(0);
		}
		//var timeOffsets = new List<num>(numStacks - startMeasureIndex);
		num cTime = firstStack.startTime;
		for (int i = startMeasureIndex; i < numStacks; i++){
			var stack = stacks[i];
			timeOffsets.add(cTime - stack.startTime);
			stack.startTime = cTime;
			cTime += (i <= endMeasureIndex)? numBeats * (4 / beatType) : stack.measures[0].numBeats * (4 / stack.measures[0].beatType);
			stack.endTime = cTime;
		}


		//for each measure, we'll have to change the start time of the notes and of the measure stacks. This will affect all notes until the end of the piece,
		//even though we only change the time signature through the end of the requested region

		var parts = _score.parts;
		for (var part in parts){
			var staves = part.staves;
			for (int i = 0; i < staves.length; i++){
				var staff = staves[i];
				var measures = staff.measures;
				int numMeasures = measures.length;

				for (int j = startMeasureIndex; j < numMeasures; j++){
					var cMeasure = measures[j];
					var voices = cMeasure.voices;
					
					for (var voice in voices){
						var ngContainers = voice.noteGroupContainers;
						_noteManager.changeNoteGroupTimeStamps(ngContainers, timeOffsets[j - startMeasureIndex], cMeasure.stack.endTime, voice, j <= endMeasureIndex);
					}
					if (j <= endMeasureIndex){
						cMeasure.numBeats = numBeats;
						cMeasure.beatType = beatType;
						cMeasure.displayNumBeats = null;
						cMeasure.displayBeatType = null;
						cMeasure.beatGroups = beatGroups.sublist(0);

						if (j > startMeasureIndex){
							cMeasure.showTime = false;
						}
					}

					cMeasure.notesNeedRendering = true;
				}
			}
		}

		//fill the measures with rests
		for (var part in parts){
			var staves = part.staves;
			for (int i = 0; i < staves.length; i++){
				var staff = staves[i];
				var measures = staff.measures;
				for (int j = startMeasureIndex; j <= endMeasureIndex; j++){
					_noteManager.fillMeasure(measures[j]);
				}
			}
		}
	}



	/**
	 * Changes the clef for the requested region
	 * @param firstMeasure the first measure of the region
	 * @param lastMeasure the last measure of the region
	 * @param clefType a String matching a constant from the ClefType class.
	 */
	void changeClef(Measure firstMeasure, Measure lastMeasure, String clefType) {

		var measures = firstMeasure.staff.measures;
		int startMeasureIndex = measures.indexOf(firstMeasure);
		int endMeasureIndex = measures.indexOf(lastMeasure);
		if (endMeasureIndex == -1){
			endMeasureIndex = measures.length - 1;
		}

		//create the clef in the first measure and mark it as new if it's different than the one from the previous measure
		var newClef = new Clef();
		newClef.isNew = startMeasureIndex == 0 || measures[startMeasureIndex - 1].clefs[measures[startMeasureIndex - 1].clefs.length - 1].type != clefType;
		newClef.show = newClef.isNew;
		newClef.type = clefType;
		newClef.qNoteTime = firstMeasure.stack.startTime;
		firstMeasure.clefs = [newClef];
		firstMeasure.stack.newClef = newClef.isNew;

		//check to see if the measure that follows the changed region needs to have its clef shown (because it's different than the new clef)
		if (endMeasureIndex < measures.length - 1){
			var followingMeasure = measures[endMeasureIndex + 1];
			followingMeasure.clefs[0].isNew = followingMeasure.clefs[0].type != clefType;
			followingMeasure.clefs[0].show = followingMeasure.clefs[0].isNew;
			followingMeasure.stack.newClef = followingMeasure.clefs[0].isNew;
			followingMeasure.notesNeedRendering = true;
		}

		num spacePerStep = _score.scoreProperties.staffLineSpacing / 2;
		
		for (int i = startMeasureIndex; i <= endMeasureIndex; i++){
			var measure = measures[i];
			if (i > startMeasureIndex){
				//clear the clefs
				newClef = new Clef();
				newClef.type = clefType;
				newClef.qNoteTime = measure.stack.startTime;
				measure.clefs = [newClef];
				measure.stack.newClef = false;
			}

			var voices = measure.voices;
			for (var voice in voices){
				var noteGroups = voice.noteGroups;
				int numNoteGroups = noteGroups.length;
				for (int j = 0; j < numNoteGroups; j++){
					var notes = noteGroups[j].notes;
					int numNotes = notes.length;
					for (int k = 0; k < numNotes; k++){
						var note = notes[k];
						int steps = PitchUtils.getStepsFromTopStaffLine(note.pitchName, clefType);
						note.stepsFromTopStaffLine = steps;
						note.legerLines = PitchUtils.getNumberOfLegerLines(steps);
						note.vPos = spacePerStep * steps;
					}
				}
			}

			measure.notesNeedRendering = true;
		}
	}

	/**
	 * changes the passed in NoteGroup's duration. Any notes overlapped by an increase in duration are deleted.
	 * any gaps created are filled with rests
	 * @param noteGroup the NoteGroup object to change
	 * @param newDuration the new Duration Unit duration (a power of 2 matching a duration in the DurationType constants)
	 * @param numDots the number of augmentation dots
	 */
	void changeDuration(NoteGroup noteGroup, int newDuration, int numDots) {
		_noteManager.changeDuration(noteGroup, newDuration, numDots);
	}

	void addTuplet(NoteGroup ng, int numerator, int denominator, int numeratorDuration, int denominatorDuration) {
		_noteManager.addTuplet(ng,  numerator, denominator, numeratorDuration, denominatorDuration);
	}

	/**
	 * Toggles the tie state for the requested Note
	 * @param note the Note to change
	 */
	void toggleTie(Note note) {
		_noteManager.toggleTie(note);
	}

	/**
	 * adds the pitch to the specified NoteGroup
	 * @param noteGroup the NoteGroup to add the Note to
	 * @param pitchLetterName A, B, C, D, E, F, or G (uppercase)
	 * @param octave the octave for the note - C4 is middle C, the note below it is B3.
	 * @param alteration a value from -2 (double flat) to 2 (double sharp). This is an absolute alteration - not relative to the key signature's adjustment for this pitch.
	 */
	void addPitch(NoteGroup noteGroup, String pitchLetterName, int octave, int alteration) {
		_noteManager.addPitch(noteGroup, pitchLetterName, octave, alteration);
	}

	/**
	 * removes the Note from the NoteGroup
	 * @param noteGroup the NoteGroup to remove the Note from
	 * @param note the Note to remove
	 */
	void removePitch(NoteGroup noteGroup, Note note) {
		_noteManager.removePitch(noteGroup, note);
	}
	
	/**
	 * changes the octave of the specified Note
	 * @param note the Note to change
	 * @param octaveDelta the number of octaves to shift the note - negative values for transposing down.
	 */
	void changeNoteOctave(Note note, int octaveDelta) {
		_noteManager.changeNoteOctave(note, octaveDelta);
	}
	
	/**
	 * changes the octave of the specified NoteGroup
	 * @param ng the NoteGroup to change
	 * @param octaveDelta the number of octaves to shift the note - negative values for transposing down.
	 */
	void changeNoteGroupOctave(NoteGroup ng, int octaveDelta) {
		_noteManager.changeNoteGroupOctave(ng, octaveDelta);
	}

	/**
	 * For music coming from MusicXML, this creates NoteGroupContainer objects for NoteGroups and Tuplets,
	 * adding relative time stamps and creating a hierarchy that makes it possible to fill measures with rests
	 */
	void createNoteGroupContainers() {
		_noteManager.createNoteGroupContainers();
	}

	/**
	 * adds a slur between two notes
	 * @param ng1 the first NoteGroup
	 * @param ng2 the second NoteGroup
	 */
	void addSlur(NoteGroup ng1, NoteGroup ng2) {
		_noteManager.addSlur(ng1, ng2);
	}

	/**
	 * removes a Slur from the score
	 * @param slur the Slur to remove
	 */
	void removeSlur(Slur slur) {
		_noteManager.removeSlur(slur);
	}




	Score get score { return _score; }
	void set score(Score value) {
		_score = value;
		_noteManager = new NoteManager(value);
		_transpositionManager = new TranspositionManager(value, _noteManager);
		_pitchNameManager = new PitchNameManager(value);
	}
}

