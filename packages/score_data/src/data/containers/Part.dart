part of score_data.data;

class Part extends BaseDataObject {

	String _partID;
	String _name;
	String _abbreviation;

	//private var _divisionsPerQuarterNote:int;
	
	List<Staff> _staves = [];
	
	int _diatonicTransposition = 0; //number of diatonic steps that this part appears above concert pitch (- values for appearing below)
	int _chromaticTransposition = 0; //number of chromatic steps that this part appears above concert pitch (- values for appearing below)

	bool _visible = false; //true if this part is being rendered - affects whether NoteGroups are included in MeasureStacks
	//number of chromatic steps that this part sounds above concert pitch (- values for sounding below)

	//playback settings
	int _midiBank = 0;
	int _midiPreset = 0;
	int _midiChannel = 0;
	bool _muted = false;
	num _volume = 0.15;
	num _pan = 0.5;
	List _percussionMap;

	List<int> _assessmentInstruments = []; //list of assessment instruments assigned to this part

	bool _preventTransposition = false;

	///This is an optional override for controlling the playback pitch of all
	///notes in the Part. When transposing parts there are times we want the
	///changes in displayed pitch and part transposition to have less of an
	///effect on playback. This value can be used by the playback engine to
	///compensate the playback.
	int _playbackOctaveDelta = 0;

	Part(String partID, String name, String abbreviation) {
		_partID = partID;
		_name = name;
		_abbreviation = abbreviation;
	}
	
	void addStaff(Staff staff) {
		_staves.add(staff);
		staff.partRef = this;
	}
	
	/**
	 * gets all of the Measure objects in this Part containing entries between the start and end times
	 */
	List<Measure> getMeasuresByTime(num qNoteStartTime, [num qNoteEndTime = null]) {
		List<Measure> allMeasures = [];
		if (qNoteEndTime == null){
			qNoteEndTime = _staves[0].measures.last.stack.endTime;
		}

		int numStaves = _staves.length;
		for (int i = 0; i < numStaves; i++){
			List<Measure> measures = _staves[i].measures;
			int numMeasures = measures.length;
			for (int j = 0; j < numMeasures; j++){
				Measure measure = measures[j];
				if (measure.stack.endTime <= qNoteStartTime){
					continue;
				}
				else if (measure.stack.startTime > qNoteEndTime){
					break;
				}
				allMeasures.add(measure);
			}
		}

		return allMeasures;
	}

	/**
	 * gets all of the NoteGroup objects in this Part between the start and end times
	 */
	List<NoteGroup> getNoteGroupsByTime(num qNoteStartTime, [num qNoteEndTime = null]){
		if (qNoteEndTime == null){
			qNoteEndTime = _staves[0].measures.last.stack.endTime;
		}
		
		var measures = getMeasuresByTime(qNoteStartTime, qNoteEndTime);
		List<NoteGroup> allNoteGroups = [];

		int numMeasures = measures.length;
		for (int i = 0; i < numMeasures; i++){				
			List<Voice> voices = measures[i].voices;
			for (int j = 0; j < voices.length; j++){
				List<NoteGroup> noteGroups = voices[j].noteGroups;
				int numNoteGroups = noteGroups.length;
				for (int k = 0; k < numNoteGroups; k++){
					if ((i > 0 && i < numMeasures - 1) ||
							(noteGroups[k].qNoteTime >= qNoteStartTime &&
							 noteGroups[k].qNoteTime < qNoteEndTime)){
						allNoteGroups.add(noteGroups[k]);
					}
				}
			}
		}


		return allNoteGroups;
	}

	/**
	 * returns a List<NoteGroup> with all NoteGroup objects that are not rests
	 * from a single staff and voice (noteGroupsExcludingRests property differs
	 * as it returns all NoteGroups without rests for all staves and voices)
	 */
	List<NoteGroup> getNoteGroupsWithoutRests([int staffIndex = 0,
			int voiceIndex = 0]) {

		//notes without rests and without notes that continue or end ties
		List<NoteGroup> ngList = [];
		var measures = _staves[staffIndex].measures;
		for (var measure in measures) {
			var noteGroups = measure.voices[voiceIndex].noteGroups;
			for (var ng in noteGroups) {
				if (!ng.isRest) {
					ngList.add(ng);
				}
			}
		}

		return ngList;
	}

	/**
	 * returns a List<NoteGroup> with all NoteGroup objects that are neither
	 * rests nor the target of ties (NG's that begin ties are included)
	 */
	List<NoteGroup> getNoteGroupsWithoutRestsOrTieIntos([int staffIndex = 0,
			int voiceIndex = 0]) {

		List<NoteGroup> ngList = []; //notes without rests and without notes that continue or end ties
		var measures = _staves[staffIndex].measures;
		for (var measure in measures) {
			var noteGroups = measure.voices[voiceIndex].noteGroups;
			for (var ng in noteGroups) {
				if (!ng.isRest && ng.visibleNotes[0].tieState != TieState.CONTINUE &&
					ng.visibleNotes[0].tieState != TieState.STOP) {
					ngList.add(ng);
				}
			}
		}

		return ngList;
	}

	NoteGroup getFirstNote([int staffIndex = 0, int voiceIndex = 0]){
		return _staves[staffIndex].measures[0].voices[voiceIndex].noteGroups[0];
	}
	
	/**
	 * sets number of diatonic and chromatic steps that this part appears above concert pitch 
	 * (- values for appearing below)
	 * for sounding pitch, the effect is reversed (apparing above concert pitch means sounding below)
	 * @updateMeasures - Measure.diatonicTransposition should usually be kept in sync with Part - this does it.
	 */
	void setTransposition(int diatonic, int chromatic, [bool updateMeasures = true]){
		_diatonicTransposition = diatonic;
		_chromaticTransposition = chromatic;
		if (updateMeasures){
			int numStaves = _staves.length;
			for (int i = 0; i < numStaves; i++){
				List<Measure> measures = _staves[i].measures;
				int numMeasures = measures.length;
				for (int j = 0; j < numMeasures; j++){
					var measure = measures[j];
					measure.diatonicTransposition = diatonic;
					measure.chromaticTransposition = chromatic;
				}
			}
		}
	}
	
	
	List<Staff> get staves { return _staves; }
	

	/**
	 * ID for this Part
	 */
	String get partID { return _partID; }
	
	String get name { return _name; }
	void set name(String value) { _name = value; }
	
	String get abbreviation { return _abbreviation; }		
	void set abbreviation(String value) { _abbreviation = value; }
	
	/**
	 * number of diatonic steps that this part appears above concert pitch (- values for appearing below)
	 * for sounding pitch, the effect is reversed (appearing above concert pitch means sounding below)
	 */
	int get diatonicTransposition { return _diatonicTransposition; }		
	//void set diatonicTransposition(int value) { _diatonicTransposition = value; }
	
	/**
	 * number of chromatic steps that this part appears above concert pitch (- values for appearing below)
	 * for sounding pitch, the effect is reversed (appearing above concert pitch means sounding below)
	 */
	int get chromaticTransposition { return _chromaticTransposition; }		
	//void set chromaticTransposition(int value) { _chromaticTransposition = value; }

	/**
	 * true if this part is being rendered - affects whether NoteGroups and
	 * measures are included in MeasureStacks
	 */
	bool get visible {	return _visible; }
	void set visible(bool value) { _visible = value; }


	/**
	 * gets all of the Measure objects in this Part
	 */
	List<Measure> get measures {
		List<Measure> allMeasures = [];

		int numStaves = _staves.length;
		for (int i = 0; i < numStaves; i++){
			List<Measure> measures = _staves[i].measures;
			int numMeasures = measures.length;
			for (int j = 0; j < numMeasures; j++){
				allMeasures.add(measures[j]);
			}
		}

		return allMeasures;
	}

	/**
	 * gets all of the NoteGroup objects in this Part
	 */
	List<NoteGroup> get noteGroups {
		List<NoteGroup> allNoteGroups = [];

		int numStaves = _staves.length;
		for (int i = 0; i < numStaves; i++){
			List<Measure> measures = _staves[i].measures;
			int numMeasures = measures.length;
			for (int j = 0; j < numMeasures; j++){
				List<Voice> voices = measures[j].voices;
				for (int k = 0; k < voices.length; k++){
					List<NoteGroup> noteGroups = voices[k].noteGroups;
					int numNoteGroups = noteGroups.length;
					for (int m = 0; m < numNoteGroups; m++){
						allNoteGroups.add(noteGroups[m]);
					}
				}
			}
		}

		return allNoteGroups;
	}
	
	/**
	 * gets all of the NoteGroup objects in this Part
	 */
	List<NoteGroup> get noteGroupsExcludingRests {
		List<NoteGroup> allNoteGroups = [];
		//int ngIndex;

		int numStaves = _staves.length;
		for (int i = 0; i < numStaves; i++){
			List<Measure> measures = _staves[i].measures;
			int numMeasures = measures.length;
			for (int j = 0; j < numMeasures; j++){
				List<Voice> voices = measures[j].voices;
				for (int k = 0; k < voices.length; k++){
					List<NoteGroup> noteGroups = voices[k].noteGroups;
					int numNoteGroups = noteGroups.length;
					for (int m = 0; m < numNoteGroups; m++) {
						if (!noteGroups[m].isRest) {
							allNoteGroups.add(noteGroups[m]);
							//allNoteGroups[ngIndex] = noteGroups[m];
							//ngIndex++;
						}
					}
				}
			}
		}

		return allNoteGroups;
	}

	/**
	 * MIDI Bank number for the playback sound
	 */
	int get midiBank { return _midiBank; }
	void set midiBank(int value) { _midiBank = value; }

	/**
	 * MIDI Preset number for the playback sound
	 */
	int get midiPreset { return _midiPreset; }
	void set midiPreset(int value) { _midiPreset = value; }


	/**
	 * MIDI Channel number for the playback sound
	 */
	int get midiChannel { return _midiChannel; }
	void set midiChannel(int value) { _midiChannel = value; }

	/**
	 * An array of playback notes for a non-pitched percussion part (will be null if part isn't non-pitched percussion)
	 * The index serves as the display pitch, and the value at that index is the note that should be played instead. Indexes for
	 * unmapped display notes have null values associated with them. The 0 index can be used to serve as a default value.
	 */
	List get percussionMap { return _percussionMap; }
	void set percussionMap(List value) { _percussionMap = value; }

	/**
	 * true if playback is muted for this staff
	 */
	bool get muted { return _muted; }
	void set muted(bool value) { _muted = value; }

	/**
	 * a number between 0 and 1 representing the maximum volume the part can play at (assuming max dynamic)
	 */
	num get volume { return _volume; }
	void set volume(num value) { _volume = value; }

	/**
	 * a number between 0 (left) and 1 (right) for the pan position of the playback
	 */
	num get pan { return _pan; }
	void set pan(num value) { _pan = value; }

	/**
	 * list of assessment instruments assigned to this part
	 */
	List<int> get assessmentInstruments { return _assessmentInstruments; }
	void set assessmentInstruments(List<int> value) { _assessmentInstruments = value; }

	bool get preventTransposition { return _preventTransposition; }
	void set preventTransposition(bool value) { _preventTransposition = value; }

	///This is an optional override for controlling the playback pitch of all
	///notes in the Part. When transposing parts there are times we want the
	///changes in displayed pitch and part transposition to have less of an
	///effect on playback. This value can be used by the playback engine to
	///compensate the playback.
	int get playbackOctaveDelta => _playbackOctaveDelta;
	void set playbackOctaveDelta (int value) { _playbackOctaveDelta = value; }

}
