part of score_data.data;

class Measure extends BaseDataObject {

	List<Voice> _voices = []; //voices/layers

	//key sig
	int _diatonicTransposition = 0; //the number of diatonic steps the transposed pitches appear above concert pitch
	int _chromaticTransposition = 0; //the number of chromatic steps the transposed pitches appear above concert pitch
	int _concertKey = 0; //the untransposed key for this measure
	int _displayKey = 0; //key value that is displayed (includes transposition) - 0 = C, -1 = 1 flat, 1 = 1 sharp
	int _outgoingKey = 0; //the display key signature from the previous measure - only present if the measure follows a measure that was in a different key
	bool _isMajorKey = false; //true if the key signature is major, false if it's minor
	bool _showKey = false; //true if the key signature should be rendered for this measure

	//time sig
	int _numBeats = 4; //time sig num beats
	int _beatType = 4; //time sig beat type
	int _displayNumBeats; //if not null, this value should be used for the rendering display value
	int _displayBeatType; //if not null, this value should be used for the rendering display value
	List<num> _beatGroups = [0,1,2,3]; //ex. [0, 1, 2, 3] for 4/4 or [0, 1.5] for 6/8. Lists the counts (dpqTimes) that the main beats in the measure fall on
	bool _showTime = false; //true if the time signature should be rendered for this measure

	//clef
	List<Clef> _clefs = []; //holds Clef objects for this measure

	//parent references
	MeasureStack _stack; //the MeasureStack object this measure belongs to
	Staff _staff; //the Staff object this measure belongs to
	
	List<MeasureAttachment> _attachments = []; //a list of the MeasureAttachment objects attached to this measure

	bool _notesNeedRendering = true; //if true, the NoteGroup objects should be re-rendered for this measure during the next render
	
	Measure() {
		
	}
	
	/**
	 * gets the Voice object with the number matching the value passed in. If it doesn't exist,
	 * a new Voice object is created and returned
	 * @param	voiceNumber the number of the voice, typically taken from the musicXML
	 * @return	a Voice object
	 */
	Voice getVoiceByNumber(int voiceNumber) {
		for (var voice in _voices) {
			if (voice.number == voiceNumber) {
				return voice;
			}
		}
		Voice newVoice = new Voice(voiceNumber);
		newVoice.measure = this;
		_voices.add(newVoice);
		return newVoice;
	}

	/**
	 * the untransposed key for this measure - positive value indicates sharps, negative indicates flats
	 */
	int get concertKey { return _concertKey; }
	void set concertKey(int value) { _concertKey = value; }

	/**
	 * indicates the number of accidentals displayed for the key signature (includes transposition) - positive value indicates sharps, negative indicates flats
	 */
	int get displayKey { return _displayKey; }
	void set displayKey(int value) { _displayKey = value;	}

	/**
	 * the display key signature from the previous measure - only present if the measure follows a measure that was in a different key
	 */
	int get outgoingKey {	return _outgoingKey; }
	void set outgoingKey(int value) { _outgoingKey = value; }

	/**
	 * the number of diatonic steps the transposed pitches appear above concert pitch
	 */
	int get diatonicTransposition { return _diatonicTransposition; }
	void set diatonicTransposition(int value) { _diatonicTransposition = value; }

	/**
	 * the number of chromatic steps the transposed pitches appear above concert pitch
	 */
	int get chromaticTransposition { return _chromaticTransposition; }
	void set chromaticTransposition(int value) { _chromaticTransposition = value; }


	/**
	 * true if the key signature is major, false if it's minor
	 */
	bool get isMajorKey { return _isMajorKey; }
	void set isMajorKey(bool value) { _isMajorKey = value; }

	
	int get numBeats { return _numBeats; }		
	void set numBeats(int value) { _numBeats = value; }
	
	int get beatType { return _beatType; }		
	void set beatType(int value) { _beatType = value; }
	
	///if not null, this value will be used for rendering display
	int get displayNumBeats => _displayNumBeats;
	void set displayNumBeats(int value) { _displayNumBeats = value; }
	
	///if not null, this value will be used for rendering diplay 
	int get displayBeatType => _displayBeatType;
	void set displayBeatType(int value) { _displayBeatType = value; }
	
	/**
	 * ex. [0, 1, 2, 3] for 4/4 or [0, 1.5] for 6/8. Lists the counts (dpqTimes) that the main beats in the measure fall on
	 */
	List<num> get beatGroups { return _beatGroups; }	
	void set beatGroups(List<num> value) { _beatGroups = value;	}


	/**
	 * holds Clef objects for this measure
	 */
	List<Clef> get clefs { return _clefs; }
	void set clefs(List<Clef> value) { _clefs = value; }
	
	List<Voice> get voices { return _voices; }
	
	///if true, the time sig will be rendered and will affect spacing
	bool get showTime { return _showTime; }		
	void set showTime(bool value) { _showTime = value; }
	
	bool get showKey { return _showKey; }		
	void set showKey(bool value) { _showKey = value; }

	
	MeasureStack get stack { return _stack; }		
	void set stack(MeasureStack value) { _stack = value; }
	
	Staff get staff { return _staff; }		
	void set staff(Staff value){ _staff = value; }
	
	/**
	 * a list of the MeasureAttachment objects attached to this measure
	 */
	List<MeasureAttachment> get attachments { return _attachments; }		
	void set attachments(List<MeasureAttachment> value) { _attachments = value; }
	
	/**
	 * calculates the total note duration (how full the measure is). 
	 * A full bar would be 4 * (numBeats / beatType) DPQ.
	 */
	num get totalNoteDuration {
		NoteGroup lastNG = _voices[0].noteGroups[_voices[0].noteGroups.length - 1]; //the last NoteGroup
		return lastNG.qNoteTime + lastNG.qNoteDuration;
	}

	/**
	 * if true, the NoteGroup objects should be re-rendered for this measure during the next render
	 */
	bool get notesNeedRendering { return _notesNeedRendering; }
	void set notesNeedRendering(bool value) {
		_notesNeedRendering = value;
		if (value == true){ //mark the property in our Stack and System as well (unless we're changing to false - we can't account for all of the other measures)
			if (this.stack != null){
				this.stack.needsRendering = true;
				/*if (this.stack.systemRef){ //handling this in MeasureStack
					this.stack.systemRef.needsRendering = true;
				}*/
			}
		}
	}

	/**
	 * returns the measure that follows this one - not stored as a property, but rather searched for dynamically
	 */
	Measure get next {
		List<Measure> measures = _staff.measures;
		int numMeasures = measures.length;
		for (int i = 0; i < numMeasures; i++){
			if (measures[i] == this){
				return (i < numMeasures - 1)? measures[i + 1] : null;
			}
		}
		return null;
	}

	/**
	 * returns the measure that precedes this one - not stored as a property, but rather searched for dynamically
	 */
	Measure get prev {
		List<Measure> measures = _staff.measures;
		int numMeasures = measures.length;
		for (int i = numMeasures - 1; i >= 0; i--){
			if (measures[i] == this){
				return (i > 0)? measures[i - 1] : null;
			}
		}
		return null;
	}

	/**
	 * returns the measure that is below this one in the stack - not stored as a property, but rather searched for dynamically
	 */
	Measure get below {
		List<Measure> measures = _stack.measures;
		int numMeasures = measures.length;
		for (int i = 0; i < numMeasures; i++){
			if (measures[i] == this){
				return (i < numMeasures - 1)? measures[i + 1] : null;
			}
		}
		return null;
	}

	/**
	 * returns the measure that is above this one in the stack - not stored as a property, but rather searched for dynamically
	 */
	Measure get above {
		List<Measure> measures = _stack.measures;
		int numMeasures = measures.length;
		for (int i = numMeasures - 1; i >= 0; i--){
			if (measures[i] == this){
				return (i > 0)? measures[i - 1] : null;
			}
		}
		return null;
	}
	
	

}
