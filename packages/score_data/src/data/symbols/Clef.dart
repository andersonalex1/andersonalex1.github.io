part of score_data.data;

class Clef extends NotationObject {

	String _type;
	num _qNoteTime;
	bool _isNew = false;
	bool _show = false;
	bool _smallSize = true;

	Clef() {
	}

	/**
	 * a String matching a constant from the ClefType class
	 */
	String get type { return _type; }
	void set type(String value) { _type = value; }

	/**
	 * the time that this clef starts taking effect, from the beginning of the piece in terms of quarter notes
	 */
	num get qNoteTime { return _qNoteTime; }
	void set qNoteTime(num value) { _qNoteTime = value; }

	/**
	 * a reference to the NoteGroup this clef should precede, if any. If this is null, the clef is placed at the beginning of the measure.
	 */
	/*public function get ngRef():NoteGroup { return _ngRef; }
	public function set ngRef(value:NoteGroup):void { _ngRef = value; }*/

	/**
	 * true if the clef is new (previous music was in a different clef, or there was no previous music
	 */
	bool get isNew { return _isNew; }
	void set isNew(bool value) { _isNew = value; }

	/**
	 * true if the clef should be rendered and counted in spacing
	 */
	bool get show { return _show; }
	void set show(bool value){ _show = value; }

	/**
	 * true if the clef should be displayed at reduced size (system start clefs are full size, but others are usually reduced)
	 */
	bool get smallSize { return _smallSize; }
	void set smallSize(bool value) { _smallSize = value; }


}
