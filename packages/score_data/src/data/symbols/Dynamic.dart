part of score_data.data;

class Dynamic extends MeasureAttachment {
	
	num _volume = 1.0;
	String _type;
	
	Dynamic() {
		
	}
	
	/**
	 * A value between 0 and 1 indicating how this marking should affect the volume
	 */
	num get volume { return _volume; }		
	void set volume(num value) { _volume = value; }
	
	/**
	 * Matches a constant from the DynamicType class
	 */
	String get type { return _type; }		
	void set type(String value) { _type = value; }
	
}
