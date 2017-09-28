part of score_data.data;

class Lyric extends NotationObject {
	
	String _syllablePosition;
	String _text;
	int _verse = 0;
	
	Lyric(String syllablePosition, String text, int verse, num hPos, num vPos) {
		_syllablePosition = syllablePosition;
		_text = text;
		_verse = verse;
		this.hPos = hPos;
		this.vPos = vPos;
	}
	
	/*public function clone():Lyric {
		var lyric:Lyric = new Lyric(_syllablePosition, _text, _verse, _hPos, _vPos);
		lyric.visible = _visible;
		
		return lyric;
	}*/
	
	String get syllablePosition { return _syllablePosition; }		
	void set syllablePosition(String value) { _syllablePosition = value; }
	
	String get text {	return _text; }		
	void set text(String value) { _text = value; }
	
	int get verse { return _verse; }	
	void set verse(int value) {	_verse = value;	}
	
}
