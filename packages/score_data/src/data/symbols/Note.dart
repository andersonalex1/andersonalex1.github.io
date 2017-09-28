part of score_data.data;

class Note extends NotationObject {
	
	String _pitchName = "C4"; //doesn't include alteration
	int _alteration = 0; //0 is no alteration, 1 is a half step up, -1 a half step down, etc. Absolute (not relative to display key)
	int _displayCents = 0; //includes alteration - displayed pitch, not concert pitch (So trumpet D4 is 6200)
	int _playbackCents = 0; //used for drum channels
	int _accidental = AccidentalType.NONE; //absolute accidental, regardless of key signature (aligns with alteration)
	bool _showAccidental = false;
	num _accidentalPos; //the horizontal position of the accidental in respect to the NoteGroup (not Note)
	String _tieState = TieState.NONE;
	int _legerLines = 0; //the number of leger lines - negative numbers mean lines above, positive numbers mean lines below, 0 means no leger lines
	int _stepsFromTopStaffLine = 0; //the number of steps from the top staff line - each line or space is a step - negative values imply above the staff

	bool _prevVisible = null; //stores previous value of _visible
	
	NoteGroup _noteGroup; //the parent NoteGroup for this Note
	
	Note() {
		this._visible = true; //avoid using setter to not set _prevVisible
	}

	///reverts the visibility of the NG to its last state. Calling multiple
	///times will have no additional effect (not a complete undo history).
	void revertVisibility(){
		if (_prevVisible != null){
			_visible = _prevVisible;
			_prevVisible = null;
		}
	}
	
	String get tieState { return _tieState; }		
	void set tieState(String value) { _tieState = value; }

	bool get isTieTarget => (_tieState == TieState.CONTINUE ||
		_tieState == TieState.STOP);
	
	int get accidental { return _accidental; }		
	void set accidental(int value) {	_accidental = value; }
	
	bool get showAccidental { return _showAccidental; }
	void set showAccidental(bool value) { _showAccidental = value; }

	/**
	 * the horizontal position of the accidental in respect to the NoteGroup (not Note)
	 */
	num get accidentalPos { return _accidentalPos; }
	void set accidentalPos(num value) { _accidentalPos = value; }
	
	String get pitchName { return _pitchName; }		
	void set pitchName(String value) { _pitchName = value; }
	
	int get alteration { return _alteration; }		
	void set alteration(int value) { _alteration = value; }
	
	int get displayCents { return _displayCents; }		
	void set displayCents(int value) {	_displayCents = value;	}
	
	/**
	 * used for drum channels to denote a different playback pitch than displayed pitch
	 */
	int get playbackCents { return _playbackCents; }		
	void set playbackCents(int value) { _playbackCents = value; }
	
	int get legerLines { return _legerLines; }		
	void set legerLines(int value) { _legerLines = value; }
	
	int get stepsFromTopStaffLine { return _stepsFromTopStaffLine; }		
	void set stepsFromTopStaffLine(int value) {	_stepsFromTopStaffLine = value;	}

	@override
	void set visible(bool value) {
		_prevVisible = value;
		_visible = value; 
	}
	
	/**
	 * the parent NoteGroup for this Note
	 */
	NoteGroup get noteGroup { return _noteGroup; }
	void set noteGroup(NoteGroup value) { _noteGroup = value; }
	
	
}
