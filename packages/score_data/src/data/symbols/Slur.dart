part of score_data.data;

class Slur extends BaseDataObject {

	int _slurID = 0; //used to identify the slur with MusicXML - NOT UNIQUE

	bool _above = false; //true if the slur should appear above the notes
	NoteGroup _firstNote; //the note where the slur starts
	NoteGroup _endNote; //the note where the slur ends
	List<SlurSegment> _segments; //the SlurSegment objects that are drawn for this slur

	Slur() {
	}

	/**
	 * used to identify the slur with MusicXML - NOT UNIQUE
	 */
	int get slurID { return _slurID; }
	void set slurID(int value) { _slurID = value; }

	/**
	 * true if the slur should appear above the notes
	 */
	bool get above { return _above; }
	void set above(bool value) { _above = value; }

	/**
	 * the note where the slur starts
	 */
	NoteGroup get firstNote { return _firstNote; }
	void set firstNote(NoteGroup value) { _firstNote = value; }

	/**
	 * the note where the slur ends
	 */
	NoteGroup get endNote { return _endNote; }
	void set endNote(NoteGroup value) { _endNote = value; }

	/**
	 * the SlurSegment objects that are drawn for this slur
	 */
	List<SlurSegment> get segments { return _segments; }
	void set segments(List<SlurSegment> value) { _segments = value; }
}
