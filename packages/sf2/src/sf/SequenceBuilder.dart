part of sf2.sf;

class SequenceBuilder {
	Preset _preset;
	
	List<PerformanceNoteDO> _sequence;
	
	SequenceBuilder() {
		
		init();
	}
	
	/**
	 * removes all notes from the sequence
	 */
	void clearSequence() {
		_sequence = [];
	}
	
	

	/// adds a note to the performance. Access the complete list of notes in the
	/// sequence property.
	/// @param	midiNote 0-127 - 60 is middle C
	/// @param	startTime start time, in samples
	/// @param	duration duration, in samples
	/// @param	amplitude a value from 0 to 1 representing base volume level
	/// @param	pan a value from 0 to 1 representing pan (0 is all the way to
	/// the left, 1 is all the way to the right)
	void addNoteToSequence(int midiNote, int startTime, int duration, num amplitude, num pan) {
		var pNoteDO = PerformanceNoteDO.createPerformanceNote(midiNote,
			startTime, duration, amplitude, pan, _preset);
		if (pNoteDO != null){
			_sequence.add(pNoteDO);
		}
		
	}
	
	
	
	void init() {
		_sequence = [];
	}
	
	
	/**
	 * the notes to be performed - give these to the player/performer object
	 */
	List<PerformanceNoteDO> get sequence {
		_sequence.sort((pn1, pn2) =>
			(pn1.sampleStartTime <= pn2.sampleStartTime)? -1 : 1);
		return _sequence; 
	}

	/// the Preset object that contains the zones and Instrument you want to use
	/// to build the sequence
	Preset get preset { return _preset; }
	void set preset(Preset value) { _preset = value; }
}