
part of score_data.data;


class NoteGroupContainer extends BaseDataObject {

	num _qNoteStartTime; //the start time from the beginning of the piece, in qNotes.
	int _durUnitStartTime = 0; //start duration unit time of the container within the containing measure or tuplet
	int _durUnitEndTime = 0; //end duration unit time of the container within the containing measure or tuplet

	NoteGroupContainer _parentNGC; //the container, if any, that holds this NoteGroupContainer

	//either this
	NoteGroup _noteGroup; //the container contains only a single NoteGroup

	//or these if the container holds a series of notes that lie within a tuplet
	List<NoteGroupContainer> _ngcList;
	Tuplet _tuplet;

	NoteGroupContainer() {

	}

	num get qNoteStartTime { return _qNoteStartTime; }
	void set qNoteStartTime(num value) { _qNoteStartTime = value; }

	int get durUnitStartTime { return _durUnitStartTime; }
	void set durUnitStartTime(int value) { _durUnitStartTime = value; }

	int get durUnitEndTime { return _durUnitEndTime; }
	void set durUnitEndTime(int value) { _durUnitEndTime = value; }

	NoteGroupContainer get parentNGC { return _parentNGC;	}
	void set parentNGC(NoteGroupContainer value) { _parentNGC = value; }

	NoteGroup get noteGroup { return _noteGroup; }
	void set noteGroup(NoteGroup value) { _noteGroup = value; }

	List<NoteGroupContainer> get ngcList { return _ngcList; }
	void set ngcList(List<NoteGroupContainer> value) { _ngcList = value;	}

	Tuplet get tuplet { return _tuplet; }
	void set tuplet(Tuplet value) {	_tuplet = value; }



}

