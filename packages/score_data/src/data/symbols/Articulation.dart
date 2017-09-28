part of score_data.data;

class Articulation extends NoteAttachment {
	
	int _type = 0;
	
	Articulation() {
	
	}

	void getWidthHeight() {
		if (_type == ArticulationType.STACCATO){
			width = 0.0;
			height = 0.0;
		}
		else {
			width = 1.0;
			height = 1.0;
		}
	}

	/**
	 * an integer matching a constant from the ArticulationType class
	 */
	int get type { return _type; }
	void set type(int value) { _type = value; }

	
}

