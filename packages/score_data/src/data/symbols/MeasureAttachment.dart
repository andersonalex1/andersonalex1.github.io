part of score_data.data;

class MeasureAttachment extends NotationObject {

	num _qNoteTime;
	Measure _measure;
	bool _isAbove = false;
	num _height;
	num _width;

	MeasureAttachment() {
	}

	/**
	 * the time in the score that this object is attached (and potentially takes effect)
	 */
	num get qNoteTime { return _qNoteTime; }
	void set qNoteTime(num value) { _qNoteTime = value; }
	
	/**
	 * the Measure this object is attached to
	 */
	Measure get measure { return _measure; }		
	void set measure(Measure value) { _measure = value; }
	
	/**
	 * true if this attachment goes above the measure
	 */
	bool get isAbove { return _isAbove; }	
	void set isAbove(bool value) { _isAbove = value; }

	/**
	 * the height of the attachment - used for spacing calculations
	 */
	num get height { return _height; }
	void set height(num value) { _height = value; }

	/**
	 * the width of the attachment - used for spacing calculations
	 */
	num get width { return _width; }
	void set width(num value) { _width = value; }
}

