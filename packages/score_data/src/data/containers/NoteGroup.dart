part of score_data.data;

class NoteGroup extends BaseDataObject {

	List<Note> _notes = []; //the notes that make up this NoteGroup
	
	num _hPos = 0; //horizontal position of this NoteGroup. Variations of individual notes within this group are defined in the Note class
	
	String _stemDirection = StemDirection.NO_STEM; //"noStem", "up", or "down"
	num _stemStartPos; //the vertical position of the start of the stem (at the notehead) measured from the top staff line - negative values are above the top staff line
	num _stemEndPos = 0; //the vertical position of the end of the stem measured from the top staff line. Negative values are above the top staff line.
	num _stemHPos = 0; //the horizontal position of the stem
	
	Stem _stem;
	
	int _duration = 1024; //duration in duration unit values - 1024 is a quarter note. This value DOES NOT have the tuplet ratio applied to it, so it must be converted for actual length
	num _qNoteDuration = 1.0; //duration in terms of qNotes.
	num _qNoteTime = 0.0; //the start time of this note expressed in terms of the total DPQ that have passed up to this point divided by the DPQ of the part. This is an absolute measurement that disregards different DPQ values for different parts
	int _durationType = DurationType.QUARTER; //"quarter", "eighth", etc. - the shape of the note - does NOT differentiate things like "triplet"
	int _numDots = 0; //number of augmentation dots
	
	bool _isGrace = false; //true if it's a grace note
	NoteGroup attachmentNG; //for gracenotes, the NoteGroup this gracenote precedes and is attached to for processing purposes
	
	List<String> _beamStates = []; //an array of strings conforming to constants from nEngine.data.symbols.BeamState - the order should match outer beam, second beam, third beam, etc.
	int _maxBeams = 0; //the number of beams this note could potentially support (0 for a quarter or bigger, 1 for an eighth, 2 for a 16th note, etc.)

	int _numAccidentalLevels = 0; //the number of accidental level positions needed for this chord (for spacing purposes)

	bool _isRest = false; //true if it's a rest
	num _restVPos = 0; //the vertical position of the rest (if it's a rest)
	
	List<Tuplet> _tuplets; //contains all Tuplet objects that affect this note

	List<Slur> _slurs; //contains all Slur objects that start or stop on this note

	Clef _clef; //if this note is the first note after the start of a mid-measure clef, this holds a reference to that Clef - needed for spacing calculation
	
	Lyric _lyric; //a Lyric object, set only if this NoteGroup has a lyric
	
	bool _clipStart = false; //true if this note starts a clip
	bool _clipEnd = false; //true if this note ends a clip
	
	num _idealHPos = 0; //the position this note would occupy within its measure if the measure was given its ideal amount of spacing
	
	Voice _voice; //the voice this NoteGroup belongs to
	NoteGroupContainer _ngcRef; //the NoteGroupContainer this NoteGroup belongs to
	
	int _playbackStartTime = 0; //the playback start time for this note, in samples, from the beginning of the piece.
	num _playbackTempo; //the current tempo at the time of this note
	
	List<Articulation> _articulations; //a list of Articulation objects attached to this NoteGroup

	bool _visible = true; //true if this noteGroup should be displayed
	bool _prevVisible = null; //stores the previous visibility state of the NoteGroup
	
	NoteGroup _cachedNextNG;
	NoteGroup _cachedPrevNG;
	
	List<Note> _visibleNotesCache; //a list of the Notes which are visible - should be updated when notes are changed
	
	NoteGroup() {
		
	}

	/**
	 * adds the Note to the NoteGroup at the last position - this does NOT sort the Note by pitch (use insertNote() for that).
	 * @param note the Note object to add
	 */
	void addNote(Note note) {
		_notes.add(note);
		note.noteGroup = this;
	}

	/**
	 * adds the Note to the NoteGroup in its order by pitch - lowest to highest
	 * @param note the Note object to add/insert
	 */
	void insertNote(Note note) {
		//place the new note in order of pitch - lowest pitches first
		int numNotes = _notes.length;
		int i = 0;
		for (i = 0; i < numNotes; i++){
			if (_notes[i].stepsFromTopStaffLine < note.stepsFromTopStaffLine){
				break;
			}
		}
		_notes.insert(i, note);
		note.noteGroup = this;
	}

	/**
	 * removes the Note from the NoteGroup
	 * @param note the Note object to remove
	 */
	void removeNote(Note note) {
		int numNotes = _notes.length;
		for (int i = 0; i < numNotes; i++){
			if (_notes[i] == note){
				_notes.removeAt(i);
				if (note.noteGroup == this){
					note.noteGroup = null;
				}
				break;
			}
		}
	}
	
	/**
	 * sorts the notes by pitch so that the lowest note is first in the list
	 */
	void sortNotesByPitch() {
		_notes.sort((Note n1, Note n2) {
			return (n1.displayCents <= n2.displayCents)? -1 : 1;
		});
	}
	
	void clearNextPrevNGCaches(){
		_cachedNextNG = null;
		_cachedPrevNG = null;
	}
	
	void clearVisibleNotesCache(){
		_visibleNotesCache = null;
	}

	///reverts the visibility of the NG to its last state. Calling multiple
	///times will have no additional effect (not a complete undo history).
	void revertVisibility(){
		if (_prevVisible != null){
			_visible = _prevVisible;
			_prevVisible = null;
		}
	}
	
	List<Note> get notes { return _notes; }
	
	///Gets the list of notes, in bottom to top order, that are currently visible
	///When changing notes' visibility property, be sure to call clearVisibleNotesCache();
	List<Note> get visibleNotes {
		if (_visibleNotesCache != null){ 
			return _visibleNotesCache; 
		}
		if (_isRest){ 
			_visibleNotesCache = null;
			return null; 
		}
		_visibleNotesCache = [];
		for (var note in _notes){
			if (note.visible){
				_visibleNotesCache.add(note);
			}
		}
		return _visibleNotesCache;
	}
	
	bool get isRest { return _isRest; }
	void set isRest(bool value) { _isRest = value; }
	
	num get restVPos { return _restVPos; }		
	void set restVPos(num value) { _restVPos = value; }
	
	int get numDots { return _numDots; }		
	void set numDots(int value) { _numDots = value;	}
	
	int get durationType { return _durationType; }
	void set durationType(int value) { 
		_durationType = value;
		
		//set the potential number of beams this note supports (according to its duration type)
		if (value == DurationType.EIGHTH) {
			_maxBeams = 1;
		}
		else if (value == DurationType.SIXTEENTH) {
			_maxBeams = 2;
		}
		else if (value == DurationType.THIRTY_SECOND) {
			_maxBeams = 3;
		}
		else if (value == DurationType.SIXTY_FOURTH) {
			_maxBeams = 4;
		}
		else {
			_maxBeams = 0;
		}
	}

	/**
	 * duration in duration unit values - 1024 is a quarter note. This value DOES NOT have the tuplet ratio applied to it, so it must be converted for actual length
	 */
	int get duration { return _duration; }
	void set duration(int value) { _duration = value; }

	/**
	 * /duration in terms of qNotes.
	 */
	num get qNoteDuration { return _qNoteDuration;	}
	void set qNoteDuration(num value) { _qNoteDuration = value; }

	
	num get qNoteTime { return _qNoteTime; }
	void set qNoteTime(num value) { _qNoteTime = value; }
	
	bool get isGrace { return _isGrace; }		
	void set isGrace(bool value) { _isGrace = value; }
	
	Stem get stem { return _stem; }
	void set stem(Stem value) { _stem = value; }

	/**
	 * the vertical position of the start of the stem (at the notehead) measured from the top staff line - negative values are below the top staff line
	 */
	num get stemStartPos { return _stemStartPos; }
	void set stemStartPos(num value) { _stemStartPos = value; }
	
	num get stemEndPos { return _stemEndPos; }
	void set stemEndPos(num value) {	_stemEndPos = value; }

	/**
	 * the horizontal position of the stem
	 */
	num get stemHPos { return _stemHPos; }
	void set stemHPos(num value) { _stemHPos = value; }
	
	String get stemDirection { return _stemDirection; }
	void set stemDirection(String value) { _stemDirection = value; }

	List<String> get beamStates { return _beamStates; }
	void set beamStates(List<String> value) { _beamStates = value; }

	/**
	 * the number of beams this note could potentially support (0 for a quarter or bigger, 1 for an eighth, 2 for a 16th note, etc.)
	 */
	int get maxBeams { return _maxBeams; }
	void set maxBeams(int value) { _maxBeams = value; }


	/**
	 * the number of accidental level positions needed for this chord (for spacing purposes)
	 */
	int get numAccidentalLevels { return _numAccidentalLevels;}
	void set numAccidentalLevels(int value) { _numAccidentalLevels = value; }
	
	num get hPos { return _hPos; }
	void set hPos(num value) { _hPos = value; }
	
	List<Tuplet> get tuplets {	return _tuplets; }
	void set tuplets(List<Tuplet> value) { _tuplets = value; }

	/**
	 * contains all Slur objects that start or stop on this note
	 */
	List<Slur> get slurs { return _slurs; }
	void set slurs(List<Slur> value) { _slurs = value; }

	/**
	 * if this note is the first note after the start of a mid-measure clef, this holds a reference to that Clef - needed for spacing calculation
	 */
	Clef get clef { return _clef; }
	void set clef(Clef value) { _clef = value; }
	
	Lyric get lyric {	return _lyric; }		
	void set lyric(Lyric value) { _lyric = value; }
	
	bool get clipStart { return _clipStart; }	
	void set clipStart(bool value) {	_clipStart = value;	}
	
	bool get clipEnd { return _clipEnd; }	
	void set clipEnd(bool value) { _clipEnd = value;	}
	
	num get idealHPos { return _idealHPos;	}	
	void set idealHPos(num value) { _idealHPos = value; }
	
	Voice get voice { return _voice; }		
	void set voice(Voice value) { _voice = value; }

	/**
	 * the NoteGroupContainer this NoteGroup belongs to
	 */
	NoteGroupContainer get ngcRef { return _ngcRef; }
	void set ngcRef(NoteGroupContainer value) { _ngcRef = value; }


	/**
	 * returns the NoteGroup that follows this one in the same voice - not stored as a property, but rather searched for dynamically
	 */
	NoteGroup get next {
		if (_cachedNextNG != null){
			return _cachedNextNG;
		}
		List<NoteGroup> noteGroups = _voice.noteGroups;
		int numNoteGroups = noteGroups.length;
		for (int i = 0; i < numNoteGroups; i++){
			if (noteGroups[i] == this){
				if (i < numNoteGroups - 1){
					_cachedNextNG = noteGroups[i + 1];
					return _cachedNextNG;
				}
			}
		}

		//our NoteGroup must have been the last one in the measure - get the first note in the same voice in a following measure
		int voiceNum = _voice.number;
		Measure nextMeasure = _voice.measure.next;
		while (nextMeasure != null){
			//int numVoicesInNextMeasure = nextMeasure.voices.length;
			List<Voice> voices = nextMeasure.voices;
			for (var nextVoice in voices){
				if (nextVoice.number == voiceNum){
					if (nextVoice.noteGroups.length > 0){
						_cachedNextNG = nextVoice.noteGroups[0];
						return _cachedNextNG;
					}
				}
			}

			nextMeasure = nextMeasure.next;
		}

		return null;
	}

	/**
	 * returns the NoteGroup that precedes this one in the same voice - not stored as a property, but rather searched for dynamically
	 */
	NoteGroup get prev {
		if (_cachedPrevNG != null){
			return _cachedPrevNG;
		}
		List<NoteGroup> noteGroups = _voice.noteGroups;
		int numNoteGroups = noteGroups.length;
		for (int i = numNoteGroups - 1; i >= 0; i--){
			if (noteGroups[i] == this){
				if (i > 0){
					_cachedPrevNG = noteGroups[i - 1];
					return _cachedPrevNG;
				}
			}
		}

		//our NoteGroup must have been the first one in the measure - get the last note in the same voice in a previous measure
		int voiceNum = _voice.number;
		Measure prevMeasure = _voice.measure.prev;
		while (prevMeasure != null){
			//int numVoicesInNextMeasure = prevMeasure.voices.length;
			List<Voice> voices = prevMeasure.voices;
			for (var prevVoice in voices){
				if (prevVoice.number == voiceNum){
					if (prevVoice.noteGroups.length > 0){
						_cachedPrevNG = prevVoice.noteGroups[prevVoice.noteGroups.length - 1];
						return _cachedPrevNG;
					}
				}
			}

			prevMeasure = _voice.measure.prev;
		}

		return null;
	}
	
	/**
	 * the playback start time for this note, in samples, from the beginning of the piece.
	 */
	int get playbackStartTime { return _playbackStartTime; }		
	void set playbackStartTime(int value) { _playbackStartTime = value; }
	
	/**
	 * the current tempo at the time of this note
	 */
	num get playbackTempo { return _playbackTempo; }		
	void set playbackTempo(num value) { _playbackTempo = value; }


	/**
	 * a list of Articulation objects attached to this NoteGroup. Null if no articulations are attached.
	 */
	List<Articulation> get articulations { return _articulations; }
	void set articulations(List<Articulation> value) { _articulations = value; }
	
	/**
	 * true if this notegroup should be displayed and accounted for in formatting
	 */
	bool get visible => _visible;
	void set visible(bool value) {
		_prevVisible = _visible;
		_visible = value;
	}
  
}
