part of score_data.data;

class NotationObject extends BaseDataObject {
	
	bool _visible = false;
	num _hPos;
	num _vPos;
	
	NotationObject() {
		
	}
	
	bool get visible { return _visible; }		
	void set visible(bool value) { _visible = value; }
	
	num get hPos { return _hPos; }		
	void set hPos(num value) { _hPos = value; }
	
	num get vPos { return _vPos; }		
	void set vPos(num value) { _vPos = value; }
	
}
