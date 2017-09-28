part of score_data.data;

class Tuplet extends BaseDataObject {

	int _tupletID = 0; //an identifier value for the tuplet - useful when dealing with nested tuplets
	NoteGroup _firstNote; //the first note in the tuplet.
	NoteGroup _endNote; //the last note in the tuplet.
	int _numerator = 0; //the number of notes of _numeratorDuration value that fit in the tuplet (for 3 in the space of 2, this is the 3)
	int _denominator = 0; //the number of notes of _denominatorDuration value that represent the real duration the tuplet takes up (for 3 in the space of 2, this is the 2)
	int _numeratorDuration = 0; //the duration of the type of note X as in X in the space of Y
	int _denominatorDuration = 0; //the duration of the type of note Y as in X in the space of Y
	bool _above = false; //the tuplet should be placed above
	
	bool _showBracket = false;
	num _vPos = 0;

	//int _superTuplet:Tuplet; //if this is a nested tuplet, this refers to the Tuplet it is nested inside most immediately
	//int _subTuplets:Vector.<Tuplet> = new Vector.<Tuplet>(); //if this tuplet contains other tuplets, this holds the list of them
	
	Tuplet() {
		
	}
	
	
	int get tupletID { return _tupletID; }
	void set tupletID(int value) { _tupletID = value; }

	NoteGroup get firstNote {	return _firstNote; }
	void set firstNote(NoteGroup value) { _firstNote = value; }

	NoteGroup get endNote { return _endNote; }
	void set endNote(NoteGroup value) { _endNote = value; }

	int get numerator { return _numerator; }
	void set numerator(int value) { _numerator = value; }

	int get denominator { return _denominator; }
	void set denominator(int value) { _denominator = value; }

	int get numeratorDuration { return _numeratorDuration; }
	void set numeratorDuration(int value) { _numeratorDuration = value; }

	int get denominatorDuration { return _denominatorDuration; }
	void set denominatorDuration(int value) { _denominatorDuration = value; }

	bool get above { return _above; }
	void set above(bool value) { _above = value;	}


	bool get showBracket { return _showBracket; }
	void set showBracket(bool value) { _showBracket = value; }

	num get vPos { return _vPos; }
	void set vPos(num value) { _vPos = value; }
}
