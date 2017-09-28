part of score_data.data;

class TempoMarker extends BaseDataObject {

	num _tempo; //a bpm tempo value
	num _qNoteTime; //the time that this tempo takes effect (in terms of quarter notes from song beginning)

	TempoMarker() {
	}

	/**
	 * a bpm tempo value
	 */
	num get tempo { return _tempo; }
	void set tempo(num value) { _tempo = value; }

	/**
	 * the time that this tempo takes effect (in terms of quarter notes from song beginning)
	 */
	num get qNoteTime { return _qNoteTime; }
	void set qNoteTime(num value) { _qNoteTime = value; }
}
