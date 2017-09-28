part of score_data.data;

class Stem extends NotationObject {
	
	num _endPosition; //the end position of the stem, drawn from the vPos
	String _direction = StemDirection.NO_STEM; //"noStem", "up", or "down"
	
	Stem() {
		
	}
	
	num get endPosition { return _endPosition; }		
	void set endPosition(num value) { _endPosition = value; }
	
	String get direction { return _direction;	}		
	void set direction(String value) { _direction = value; }
	
}
