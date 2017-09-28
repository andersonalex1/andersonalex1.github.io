part of score_data.music_creation;

class TranspositionManager {
	Score _score;
	
	NoteManager _noteManager;
	List<MeasureStack> _stacks;

	List<TranspositionRecord> _history = [];
	
	TranspositionManager(this._score, this._noteManager){
		
	}
	
	////////////////////MACRO LEVEL CHANGES//////////////

	///prevents transposition of all parts set to midiChannel 10
	void preventPercussionTransposition() {
		for (var part in _score.parts){
			if (part.midiChannel == 10){
				part.preventTransposition = true;
			}
		}
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

		if (ngsNoTieIntosOrRests.length != octaveShiftValues.length){
			throw "octave shift values don't match up with NoteGroups";
		}

		int length = octaveShiftValues.length;
		for (int i = 0; i < length; i++) {
			int transposition = octaveShiftValues[i];
			if (transposition == 0) continue;

			var ng = ngsNoTieIntosOrRests[i];
			do {
				if (!ng.isRest)
					_noteManager.changeNoteGroupOctave(ng, transposition);
				ng = ng.next;
			}
			while ((i < length - 1 && ng != ngsNoTieIntosOrRests[i+1]) ||
				(i == length - 1 && ng != null));
		}

		var record = new TranspositionRecord();
		record.type = TranspositionType.NOTE_OCTAVES;
		record.ngList = ngsNoTieIntosOrRests;
		record.ngOctaveDeltas = octaveShiftValues;
		_history.add(record);
	}

	/**
	 * transposes all of the notes in a given part by the specifed number
	 * of octaves.
	 * @octaveDelta - +1 for up one octave, -1 for down one octave, etc.
	 */
	void changeOctaveOfPart(Part part, int octaveDelta){
		if (part.preventTransposition){
			return;
		}

		var ngList = part.noteGroupsExcludingRests;
		//changing the octave of notes can resort them, so we need to be careful about traversing
		//the note lists for each ng so that the order of notes in ngList doesn't change
		if (octaveDelta > 0){
			for (var ng in ngList){
				var notes = ng.notes;
				for (int i = notes.length -1; i >= 0; i--){ //transposing up - start at top note
					_noteManager.changeNoteOctave(notes[i], octaveDelta);
				}
			}
		}
		else if (octaveDelta < 0){
			for (var ng in ngList){
				var notes = ng.notes;
				for (int i = 0; i < notes.length; i++){ //transposing down - start at bottom note
					_noteManager.changeNoteOctave(notes[i], octaveDelta);
				}
			}
		}

		var record = new TranspositionRecord();
		record.type = TranspositionType.PART_OCTAVE;
		record.part = part;
		record.octaveDelta = octaveDelta;
		_history.add(record);
	}
	
	///sets the transposition for the requested part, transposing the notes and display key
	///chromaticTrans and diatonicTrans are absolute values, not relative shifts. So trumpet
	///should always be 2 and 1 (the amount the transposed pitches APPEAR above concert pitch
	void setPartTransposition(Part part, int chromaticTrans,
			[int diatonicTrans = null]){
		if (diatonicTrans == null){
			diatonicTrans = PitchUtils.getCommonDiatonicTranspositionFromChromaticSteps(chromaticTrans);
		}
		
		//calculate the shift from previous transposition
		int chromaticShift = chromaticTrans - part.chromaticTransposition;
		int diatonicShift = diatonicTrans - part.diatonicTransposition;
		
		//set the transposition values of the part and measures
		part.setTransposition(diatonicTrans, chromaticTrans);
		
		//for each key region, update the display key and transpose the notes
		var regions = _getKeyMeasureRegions(part);
		for (var reg in regions){
			_updateDisplayKeyOfRegion(reg, false);
			_transposeRegion(reg, chromaticShift, diatonicShift, true);
		}
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
	void transposeSong(int chromaticShift, [int diatonicShift = null,
			bool preventInitialKeyOptimization = false,
			int playbackOctaveDelta = 0]){
		if (diatonicShift == null){
			diatonicShift = PitchUtils.getCommonDiatonicTranspositionFromChromaticSteps(chromaticShift);
		}

		//for each key region, update the concert key and transpose the notes in all parts
		var parts = _score.parts;
		var regions = _getKeyMeasureRegions(_score.parts[0]);
		for (var reg in regions){
			int oldKey = reg.startMeasure.concertKey;
			bool isMajor = reg.startMeasure.isMajorKey;
			
			//calculate the new concert key
			int keyDelta = PitchUtils.getKeySigAlterationForTransposition(diatonicShift, chromaticShift);
			int newKey = reg.startMeasure.concertKey + keyDelta; //new concertKey
			if (!preventInitialKeyOptimization || reg != regions[0]){
				//convert excessive key signatures to enharmonic equivalent
				newKey = _optimizeKeyEnharmonically(newKey);
			}
			
			//adjust the chromatic/diatonic shift to account for enharmonic key flip possibility
			bool transposeUp = chromaticShift > 0;
			var tdo = PitchUtils.getTranspositionForKeyChange(oldKey, newKey, isMajor, isMajor,
																				transposeUp);
			int adjustedChromaticShift = tdo.chromatic;
			int adjustedDiatonicShift = tdo.diatonic;
//			int adjustedChromaticShift = PitchUtils.getChromaticShiftForKeyChange(oldKey, newKey, isMajor, isMajor,
//																				transposeUp);
//			int adjustedDiatonicShift = PitchUtils.getDiatonicShiftForKeyChange(oldKey, newKey, isMajor, isMajor,
//																				transposeUp);
			//make sure we didn't lose octaves
			//3/30/2015 - fix bug where chromaticShift or diatonicShift were 12 or 7, creating additional octave.
			//fix is to check if chromaticShift == adjustedChromaticShift
			bool adjustedUp = false;
			while (adjustedChromaticShift < chromaticShift){
				adjustedChromaticShift += 12;
				adjustedDiatonicShift += 7;
				adjustedUp = true;
			}
			if (adjustedUp && adjustedChromaticShift != chromaticShift) { 
				print ('TranspositionManager: chromaticShift should equal adjustedChromaticShift!!!');
			}
			while (adjustedChromaticShift > chromaticShift){
				adjustedChromaticShift -= 12;
				adjustedDiatonicShift -= 7;
			}
			
			_setConcertKeyForRegion(reg, newKey, isMajor, false);
			for (var part in parts){
				if (part.preventTransposition){
					continue; //EXPERIMENTAL 6/5/2017
				}
				//create measure region with new Part
				_transposeRegion(new MeasureRegion(part, reg.startMeasure, reg.endMeasure),
					adjustedChromaticShift, adjustedDiatonicShift, true);

				part.playbackOctaveDelta += playbackOctaveDelta;
			}
		}

		var record = new TranspositionRecord();
		record.type = TranspositionType.SCORE;
		record.diatonicShift = diatonicShift;
		record.chromaticShift = chromaticShift;
		record.playbackOctaveDelta = playbackOctaveDelta;
		_history.add(record);
	}
	
	
	///transposes the entire song to the specified key, proportionally changing key signatures
	///that happen after the first measure
	///@newConcertKey - the new concert key (3 would be 2 sharps, -2 would be 2 flats)
	///@transposeDirection - matches constant from TransposeDirection class - 0 is NEAREST
	///returns a TranspositionDO object with the chromatic/diatonic steps used for the transposition
	void setConcertKeyOfSong(int newConcertKey, [int transposeDirection = 0]){
		var measure = _score.parts[0].staves[0].measures[0];
		int oldKey = measure.concertKey;
		bool isMajor = measure.isMajorKey;
		
		bool transposeUp;
		if (transposeDirection == TransposeDirection.UP){
			transposeUp = true;
		}
		else if (transposeDirection == TransposeDirection.DOWN){
			transposeUp = false;
		}
		else {
			//find nearest direction
			transposeUp = PitchUtils.getNearestTranspositionDirection(oldKey, newConcertKey, 
																	isMajor, isMajor) >= 0;
		}
		var transDO = PitchUtils.getTranspositionForKeyChange(oldKey, newConcertKey, 
										isMajor, isMajor, transposeUp);
        //int chromaticShift = pitchShift['chromatic'];
        //int diatonicShift = pitchShift['diatonic'];
//		int chromaticShift = PitchUtils.getChromaticShiftForKeyChange(oldKey, newConcertKey, 
//							isMajor, isMajor, transposeUp);
//		int diatonicShift = PitchUtils.getDiatonicShiftForKeyChange(oldKey, newConcertKey, 
//							isMajor, isMajor, transposeUp);
		
		transposeSong(transDO.chromatic, transDO.diatonic, true);
		
		//return transDO;
	}

	/**
	 * reverts transpositions that were performed by transposeSong(),
	 * setConcertKeyOfSong(), changeOctaveOfPart(), and adjustOctavesOfNotes()
	 * @param steps - the number of steps in the transposition history to undo.
	 * If 0 (default), all transpositions will be undone.
	 */
	void revertTranspositions([int steps = 0]) {
		if (steps <= 0 || steps > _history.length){
			steps = _history.length;
		}
		int cutoffIndex = _history.length - steps;

		for (int i = _history.length - 1; i >= cutoffIndex; i--){
			var record = _history[i];
			if (record.type == TranspositionType.SCORE){
				transposeSong(-1 * record.chromaticShift,
					-1 * record.diatonicShift, false,
					-1 * record.playbackOctaveDelta);
			}
			else if (record.type == TranspositionType.PART_OCTAVE){
				changeOctaveOfPart(record.part, -1 * record.octaveDelta);
			}
			else if (record.type == TranspositionType.NOTE_OCTAVES){
				var inverse = record.ngOctaveDeltas.map((val)=> val * -1);
				adjustOctavesOfNotes(inverse.toList(), record.ngList);
			}
		}
		_history = [];
	}

	//currently unused?
	void transposeByChromaticSteps(int chromaticSteps) {
		List<int> diatonicSteps = [ -7, -6, -6, -5, -5, -4, -4, -3, -2, -2, -1, -1,
		0, 1, 1, 2, 2, 3, 4, 4, 5, 5, 6, 6, 7];
		transposeSong(diatonicSteps[chromaticSteps + 12], chromaticSteps);
	}
	

	///////////////////BUILDING BLOCK METHODS//////////////////
	
	///transposes notes for a single part and region
	///optionally updates which notes display accidentals (checking against key
	///and previous accidentals in measure)
	void _transposeRegion(MeasureRegion mr, int chromaticShift, [int diatonicShift = null,
						bool updateDisplayedAccidentals = true]){
		if (diatonicShift == null){
			diatonicShift = PitchUtils.getCommonDiatonicTranspositionFromChromaticSteps(chromaticShift);
		}
	
		//bool transposeUp = chromaticShift > 0;
		
		var staves = mr.part.staves;
		for (int i = 0; i < staves.length; i++){
			var staff = staves[i];
			var measures = staff.measures;
			int j = 0;
			//int displayedKey = 0;
			for (j = mr.startMeasureIndex; j <= mr.endMeasureIndex; j++){
				var cMeasure = measures[j];
				
				var clefList = cMeasure.clefs;

				var voices = cMeasure.voices;
				for (var voice in voices){
					//we have to track the clef through the measure. We always reset it to the beginning of measure 
					//clef at the start of each voice

					var noteGroups = voice.noteGroups;
					int numNoteGroups = noteGroups.length;
					for (int k = 0; k < numNoteGroups; k++){
						var ng = noteGroups[k];
						
						//get the clef for this note based on its time
						num qNoteTime = ng.qNoteTime;
						if (ng.isGrace && ng.attachmentNG != null){
							//grace notes are associated with a following NoteGroup
							qNoteTime = ng.attachmentNG.qNoteTime;
						}
						String clefType;
						for (var clef in clefList){
							if (qNoteTime + 0.0001 > clef.qNoteTime){
								clefType = clef.type;
							}
							else {
								break;
							}
						}
						var notes = ng.notes;
						for (var note in notes) {
							//change the note
							note.stepsFromTopStaffLine -= diatonicShift;
							note.pitchName = PitchUtils.getPitchNameFromStaffLinePosition(note.stepsFromTopStaffLine, clefType);
							note.displayCents += chromaticShift * 100;
							note.alteration = PitchUtils.getAlterationForCents(note.displayCents, note.pitchName);
							note.accidental = AccidentalType.getAccidentalType(note.alteration);
							note.legerLines = PitchUtils.getNumberOfLegerLines(note.stepsFromTopStaffLine);
							note.vPos = (_score.scoreProperties.staffLineSpacing / 2) * note.stepsFromTopStaffLine;
						}
					}
				}

				if (updateDisplayedAccidentals){
					_noteManager.updateAccidentals(cMeasure);
				}

				cMeasure.notesNeedRendering = true;
			}
		}
	}
	
	///calculates the number of accidentals for a new key based on the original key and the change.
	///Wraps new key if it gets too many flats/sharps
	int _optimizeKeyEnharmonically(int key){
		if (key > 7) {
			key -= 12;
		}
		else if (key < -7) {
			key += 12;
		}
		return key;
	}
	
	///updates concertKey to new value and adjusts display key accordingly
	///this affects all parts for the specified region
	///doesn't transpose notes, but can (optionally) update which notes display accidentals
	///the MeasureRegion.part property doesn't matter, since the entire score is affected
	void _setConcertKeyForRegion(MeasureRegion mr, int newConcertKey, bool isMajor,
	                            [bool updateDisplayedAccidentals = true]){
		
		//set the new key property for the stacks in the region
		//if there was a previous measure, and its key already matched the one we are now setting, 
		//the first stack should not show a new key. Otherwise this is either the first stack in the 
		//piece or a stack with a different key - in either case, we must show the key
		mr.startMeasure.stack.newKey = !(mr.startMeasureIndex > 0 && mr.startMeasure.prev.concertKey == newConcertKey);

		//if there is a measure following the changed region, it will need to show the key if it differs
		if (mr.endMeasure.next != null){
			mr.endMeasure.next.stack.newKey = mr.endMeasure.next.concertKey != newConcertKey;
			mr.endMeasure.next.notesNeedRendering = true;
		}

		//all of the other stacks in the region will have newKey set to false
		if (_stacks == null){ _stacks = _score.getMeasureStacks(); }
		for (int i = mr.startMeasureIndex + 1; i <= mr.endMeasureIndex; i++){
			_stacks[i].newKey = false;
		}
		
		
		var parts = _score.parts;
		for (var part in parts){
			_setKeysForPartMeasureRegion(part, mr.startMeasureIndex, mr.endMeasureIndex, 
										newConcertKey, isMajor, updateDisplayedAccidentals);
		}
		
		_updateKeySizeForStacks(mr);
	}


	
	
	///updates displayKey for one measure region and part based on measure transposition settings 	
	///doesn't transpose notes, but can (optionally) update which notes display accidentals
	///intended to be used after changing Part/Measure chromatic/diatonic transpositions
	void _updateDisplayKeyOfRegion(MeasureRegion mr, [bool updateDisplayedAccidentals = true]){
		_setKeysForPartMeasureRegion(mr.part, mr.startMeasureIndex, mr.endMeasureIndex, 
									mr.startMeasure.concertKey, mr.startMeasure.isMajorKey, 
									updateDisplayedAccidentals);
		
		_updateKeySizeForStacks(mr);
	}
	
	///finds and stores the largest key signature size for each stack in the MeasureRegion
	void _updateKeySizeForStacks(MeasureRegion mr){
		if (_stacks == null){ _stacks = _score.getMeasureStacks(); }
		//update the max key size for every stack
		//if we set the outgoing key for the measures following our region, we should include them
		int lastIndex = (mr.endMeasureIndex < _stacks.length - 1)? mr.endMeasureIndex + 1 : mr.endMeasureIndex; 
		for (int i = mr.startMeasureIndex; i <= lastIndex; i++){
			var stack = _stacks[i];
			int maxKeySize = 0;
			//this will just be the subset of measures that are shown (the stacks only maintain a list of visible measures)
			var measures = stack.measures; 
			int numMeasures = measures.length;
			for (int j = 0; j < numMeasures; j++){
				//for each measure we see if the combined outgoing key + display key is the biggest in the stack
				int totalKeySize = PitchUtils.getTotalKeySize(measures[j].displayKey, measures[j].outgoingKey);
				if (totalKeySize > maxKeySize){
					maxKeySize = totalKeySize;
				}

			}
			stack.maxKeySize = maxKeySize;
		}
	}
	
	///getKeyMeasureRegions - returns MeasureRegion objects for a Part based on changes in concertKey
	List<MeasureRegion> _getKeyMeasureRegions(Part part){
		List<MeasureRegion> regions = [];
		
		var measures = part.staves[0].measures;
		
		Measure startMeasure = null;
		Measure measure;
		for (measure in measures) {
			if (measure.stack.newKey) {
				if (startMeasure != null /*&& measure.prev != null*/) {
					regions.add(new MeasureRegion(part, startMeasure, measure.prev));
				}
				startMeasure = measure;
			}
		}
		regions.add(new MeasureRegion(part, startMeasure, measure));
		
		return regions;
	}	
	
	//////////////////////////////////INTERNAL METHODS///////////////////////////////
	
	///sets the display, concert and outgoing keys for a single region of measures in a single part
	///optionally updates the displayed notes on accidentals
	void _setKeysForPartMeasureRegion(Part part, int startMeasureIndex, int endMeasureIndex,
	                                  int newConcertKey, bool isMajor, bool updateDisplayedAccidentals) {
		var staves = part.staves;
		for (int i = 0; i < staves.length; i++){
			var staff = staves[i];
	  		var measures = staff.measures;
	  		int j = 0;
	  		int displayedKey = 0;
		  	for (j = startMeasureIndex; j <= endMeasureIndex; j++){
		  		var cMeasure = measures[j];
		  		
		  		displayedKey = PitchUtils.getKeySigAlterationForTransposition(cMeasure.diatonicTransposition, 
		  									cMeasure.chromaticTransposition) + newConcertKey;
		  
		  		cMeasure.displayKey = displayedKey;
		  		cMeasure.concertKey = newConcertKey;
		  		cMeasure.isMajorKey = isMajor;
		  		//the outgoing key is 0 for all measures except the first (and the first only gets it if it isn't 
		  		//the first measure of the piece)
		  		cMeasure.outgoingKey = (j > startMeasureIndex || startMeasureIndex == 0)?  
		  								0 : measures[j - 1].displayKey;
		  
		  		if (updateDisplayedAccidentals){
		  			_noteManager.updateAccidentals(cMeasure);
		  			cMeasure.notesNeedRendering = true;
		  		}
		  	}
		  
		  	//at the end of each set of measures in a staff, we set the outgoing key for the following measure to 
		  	//be the display key of the last measure in our changed region
		  	if (j < measures.length){
		  		measures[j].outgoingKey = displayedKey;
		  	}
		}
	}


}



class MeasureRegion {
	Part part;
	Measure startMeasure;
	Measure endMeasure;
	
	int startMeasureIndex;
	int endMeasureIndex;
	
	
	MeasureRegion(this.part, Measure startMeasure, Measure endMeasure){
		this.startMeasure = startMeasure;
		this.endMeasure = endMeasure;
		
		if (startMeasure != null){
			startMeasureIndex = startMeasure.staff.measures.indexOf(startMeasure);
		}
		if (endMeasure != null){
			endMeasureIndex = endMeasure.staff.measures.indexOf(endMeasure);
		}
	}
}


class TransposeDirection {
	static const int NEAREST = 0;
	static const int UP = 1;
	static const int DOWN = 2;
}

class TranspositionDO {
	int diatonic;
	int chromatic;
	//List<int> perPartOctaveAdjustments;
	
	//TranspositionDO(this.diatonic, this.chromatic, [this.perPartOctaveAdjustments = null]);
	TranspositionDO(this.diatonic, this.chromatic);
}

class TranspositionRecord {
	TranspositionType type;

	//PART_OCTAVE transpositions
	Part part;
	int octaveDelta;

	//NOTE_OCTAVES transpositions
	List<NoteGroup> ngList;
	List<int> ngOctaveDeltas;

	//SCORE transpositions
	int diatonicShift;
	int chromaticShift;
	int playbackOctaveDelta;

}

enum TranspositionType {
	PART_OCTAVE,
	NOTE_OCTAVES,
	SCORE
}

class TranspositionStatsDO {
	/**class is currently unused*/

	int minPitch; //middle C / C4 == 60
	int maxPitch; //middle C / C4 == 60
	List<int> concertKeys;
	List<int> displayKeys;

	TranspositionStatsDO() {

	}

	static TranspositionStatsDO getStats(Part part) {
		int minPitch = 99999;
		int maxPitch = -99999;

		List<int> concertKeys = [];
		List<int> displayKeys = [];

		int lastConcertKey = 99999;
		int lastDisplayKey = -99999;

		for (var staff in part.staves) {
			for (var measure in staff.measures) {
				if (measure.concertKey != lastConcertKey) {
					lastConcertKey = measure.concertKey;
					concertKeys.add(lastConcertKey);
				}
				if (measure.displayKey != lastDisplayKey) {
					lastDisplayKey = measure.displayKey;
					displayKeys.add(lastDisplayKey);
				}
				for (var voice in measure.voices) {
					for (var ng in voice.noteGroups) {
						if (!ng.isRest) {
							var notes = ng.notes;
							if (notes[0].displayCents < minPitch) {
								minPitch = notes[0].displayCents;
							}
							if (notes[notes.length - 1].displayCents > maxPitch) {
								maxPitch = notes[notes.length - 1].displayCents;
							}
						}
					}
				}
			}
		}

		var tStatsDO = new TranspositionStatsDO();
		tStatsDO.concertKeys = concertKeys;
		tStatsDO.displayKeys = displayKeys;
		tStatsDO.minPitch = minPitch ~/ 100;
		tStatsDO.maxPitch = maxPitch ~/ 100;

		return tStatsDO;
	}
}