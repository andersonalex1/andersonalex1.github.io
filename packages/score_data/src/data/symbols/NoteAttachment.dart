part of score_data.data;

class NoteAttachment extends NotationObject {

	NoteGroup _noteGroup;
	bool _isAbove = false;
	num _height = 0.0;
	num _width = 0.0;
	bool _outsideStaff = false;
	
	NoteAttachment() {
	}

	NoteGroup get noteGroup { return _noteGroup; }
	void set noteGroup(NoteGroup value) { _noteGroup = value; }

	bool get isAbove { return _isAbove; }
	void set isAbove(bool value) { _isAbove = value; }

	/**
	 * the height of the attachment, in staffline spaces
	 */
	num get height { return _height; }
	void set height(num value) { _height = value; }

	/**
	 * the width of the attachment, in staffline spaces
	 */
	num get width { return _width; }
	void set width(num value) { _width = value; }

	bool get outsideStaff { return _outsideStaff; }
	void set outsideStaff(bool value) { _outsideStaff = value; }
}
