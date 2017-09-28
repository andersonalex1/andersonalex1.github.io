part of score_data.data;

class ScoreProperties {
	String _rights;
	
	String _software;
	
	num _mmHeight;
	static const num STANDARD_MM_HEIGHT = 7.1967; //provides a reference point to scale other values against - measure this against the _scale property to get multiplication values
	num _tenths = 40.0;
	
	num _pageHeight;
	num _pageWidth;
	num _leftPageMargin;
	num _rightPageMargin;
	num _topPageMargin;
	num _bottomPageMargin;
	
	num _systemSpacing;
	num _topSystemDistance;
	num _leftSystemMargin;
	num _rightSystemMargin;
	
	num _staffSpacing;
	num _staffLineSpacing = 10.0; //custom value for the spacing between staff lines
	
	num _stemWidth;
	num _beamWidth;
	num _staffLineWidth;
	num _lightBarlineWidth;
	num _heavyBarlineWidth;
	num _legerLineWidth;
	num _repeatEndingWidth;
	num _hairpinLineWidth;
	num _enclosureWidth; //what's this? rehearsal letter box?
	num _tupletBracketWidth;
	
	num _graceNoteSize;
	num _cueNoteSize;
	num _noteheadWidth = 12.0; //custom value for the width of a quarter notehead
	
	num _clefDistanceFromBarline = 10.0; //custom value for distance clef appears inset from barline
	
	//music spacing values
	num _qNoteWidth; //the space (in tenths) that would ordinarily be applied to a quarter note
	num _keySigWidth; //the amount of space to allow for a single accidental
	num _timeSigWidth; //the amount of space to allow for a time signature
	num _clefWidth; //the amount of space to allow for a clef at the beginning of a system
	num _measureLeadIn; //the amount of space to have at the beginning of a measure before notes or other elements
	num _minMeasureWidth; //the minimum width of a measure

	static final num DEFAULT_PAGE_WIDTH = 1010.0;

	static final num DEFAULT_TEMPO = 90.0;

	ScoreProperties() {
		
	}
	
	ScoreProperties clone() {
		ScoreProperties scoreProps = new ScoreProperties();
		scoreProps.rights = _rights;
		scoreProps.mmHeight = _mmHeight;
		scoreProps.pageHeight = _pageHeight;
		scoreProps.pageWidth = _pageWidth;
		scoreProps.leftPageMargin = _leftPageMargin;
		scoreProps.rightPageMargin = _rightPageMargin;
		scoreProps.topPageMargin = _topPageMargin;
		scoreProps.bottomPageMargin = _bottomPageMargin;
		scoreProps.systemSpacing = _systemSpacing;
		scoreProps.topSystemDistance = _topSystemDistance;
		scoreProps.leftSystemMargin = _leftSystemMargin;
		scoreProps.rightSystemMargin = _rightSystemMargin;
		scoreProps.staffSpacing = _staffSpacing;
		scoreProps.staffLineSpacing = _staffLineSpacing;
		scoreProps.stemWidth = _stemWidth;
		scoreProps.beamWidth = _beamWidth;
		scoreProps.staffLineWidth = _staffLineWidth;
		scoreProps.lightBarlineWidth = _lightBarlineWidth;
		scoreProps.heavyBarlineWidth = _heavyBarlineWidth;
		scoreProps.legerLineWidth = _legerLineWidth;
		scoreProps.repeatEndingWidth = _repeatEndingWidth;
		scoreProps.hairpinLineWidth = _hairpinLineWidth;
		scoreProps.enclosureWidth = _enclosureWidth;
		scoreProps.tupletBracketWidth = _tupletBracketWidth;
		scoreProps.graceNoteSize = _graceNoteSize;
		scoreProps.cueNoteSize = _cueNoteSize;
		scoreProps.noteheadWidth = _noteheadWidth;
		scoreProps.clefDistanceFromBarline = _clefDistanceFromBarline;

		return scoreProps;
	}
	
	/**
	 * constructs a new ScoreProperties object with default values and returns it
	 * @return the new ScoreProperties object
	 */
	static ScoreProperties getNewScoreProperties() {
		ScoreProperties scoreProps = new ScoreProperties();
		scoreProps.rights = "";
		
		scoreProps.mmHeight = 8.5513;
		scoreProps.tenths = 40.0;
		
		scoreProps.pageHeight = 1307.0;
		scoreProps.pageWidth = DEFAULT_PAGE_WIDTH;
		//scoreProps.leftPageMargin = 119.0;
		scoreProps.leftPageMargin = 0.0;
		//scoreProps.rightPageMargin = 60.0;
		scoreProps.rightPageMargin = 0.0;
		scoreProps.topPageMargin = 74.0;
		scoreProps.bottomPageMargin = 74.0;
		
		scoreProps.systemSpacing = 71.0;
		scoreProps.topSystemDistance = 43.0;
		scoreProps.leftSystemMargin = 0.0;
		scoreProps.rightSystemMargin = 0.0;
		
		scoreProps.staffSpacing = 80.0;
		scoreProps.staffLineSpacing = 10.0; //custom value for the spacing between staff lines
		
		scoreProps.stemWidth = 0.7487;
		scoreProps.beamWidth = 5.0;
		scoreProps.staffLineWidth = 0.7487;
		scoreProps.lightBarlineWidth = 0.7487;
		scoreProps.heavyBarlineWidth = 5.0;
		scoreProps.legerLineWidth = 0.7487;
		scoreProps.repeatEndingWidth = 1.4583;
		scoreProps.hairpinLineWidth = 0.7487;
		scoreProps.enclosureWidth = 0.7487; //what's this? rehearsal letter box?
		scoreProps.tupletBracketWidth = 0.7487;
		
		scoreProps.graceNoteSize = 60.0;
		scoreProps.cueNoteSize = 60.0;
		scoreProps.noteheadWidth = 12.0; //custom value for the width of a quarter notehead
		
		scoreProps.clefDistanceFromBarline = 10.0; //custom value for distance clef appears inset from barline

		//music spacing values
		//compute the width of a quarter note in terms of "tenths" for the current score scale
		scoreProps.qNoteWidth = 7.4083 * (scoreProps.tenths / scoreProps.mmHeight) * (scoreProps.mmHeight / ScoreProperties.STANDARD_MM_HEIGHT); //clearer
		//scoreProps.qNoteWidth = 7.4083 * (scoreProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT); //shorter
		scoreProps.keySigWidth = 2.0 * (scoreProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT);
		scoreProps.timeSigWidth = 4 * (scoreProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT);
		scoreProps.clefWidth = 4.7 * (scoreProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT);
		scoreProps.measureLeadIn = 3 * (scoreProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT);
		scoreProps.minMeasureWidth = 0.0;
		
		return scoreProps;
	}
	
	void scale(num scale){		
		this.beamWidth *= scale;
		//this.bottomPageMargin *= scale;
		this.clefDistanceFromBarline *= scale;
		this.clefWidth *= scale;
		this.cueNoteSize *= scale;
		this.enclosureWidth *= scale;
		this.graceNoteSize *= scale;
		this.hairpinLineWidth *= scale;
		this.heavyBarlineWidth *= scale;
		this.keySigWidth *= scale;
		//this.leftPageMargin *= scale;
		//this.leftSystemMargin *= scale;
		this.legerLineWidth *= scale;
		this.lightBarlineWidth *= scale;
		this.measureLeadIn *= scale;
		this.minMeasureWidth *= scale;
		//this.mmHeight *= scale;
		this.noteheadWidth *= scale;
		//this.pageHeight *= scale;
		//this.pageWidth *= scale;
		this.qNoteWidth *= scale;
		this.repeatEndingWidth *= scale;
		//this.rightPageMargin *= scale;
		//this.rightSystemMargin *= scale;
		this.staffLineWidth *= scale;
		this.staffLineSpacing *= scale;
		this.staffSpacing *= scale;
		this.stemWidth *= scale;
		this.systemSpacing *= scale;
		//this.tenths *= scale;
		this.timeSigWidth *= scale;
		//this.topPageMargin *= scale;
		//this.topSystemDistance *= scale;
		this.tupletBracketWidth *= scale;
	}
	
	num get mmHeight { return _mmHeight; }		
	void set mmHeight(num value) { _mmHeight = value; }
	
	num get tenths { return _tenths; }		
	void set tenths(num value) { _tenths = value; }
	
	num get cueNoteSize { return _cueNoteSize; }		
	void set cueNoteSize(num value) {
		_cueNoteSize = (value > 0)? value : 60.0;
	}
	
	num get graceNoteSize { return _graceNoteSize; }		
	void set graceNoteSize(num value) {
		_graceNoteSize = (value > 0)? value : 60.0;
	}
	
	num get noteheadWidth { return _noteheadWidth; }		
	void set noteheadWidth(num value) { _noteheadWidth = value; }
	
	num get tupletBracketWidth { return _tupletBracketWidth; }		
	void set tupletBracketWidth(num value) {
		_tupletBracketWidth = (value > 0)? value : 1.0;
	}
	
	num get enclosureWidth { return _enclosureWidth; }		
	void set enclosureWidth(num value) {
		_enclosureWidth = (value > 0)? value : 1.0;
	}
	
	num get hairpinLineWidth { return _hairpinLineWidth; }		
	void set hairpinLineWidth(num value) {
		_hairpinLineWidth = (value > 0)? value : 1.0;
	}
	
	num get repeatEndingWidth { return _repeatEndingWidth; }		
	void set repeatEndingWidth(num value) {
		_repeatEndingWidth = (value > 0)? value : 1.0;
	}
	
	num get legerLineWidth { return _legerLineWidth; }		
	void set legerLineWidth(num value) {
		_legerLineWidth = (value > 0)? value : 1.875;
	}
	
	num get heavyBarlineWidth { return _heavyBarlineWidth; }		
	void set heavyBarlineWidth(num value) {
		_heavyBarlineWidth = (value > 0)? value : 5.0;
	}
	
	num get lightBarlineWidth { return _lightBarlineWidth; }		
	void set lightBarlineWidth(num value) {
		_lightBarlineWidth = (value > 0)? value : 1.875;
	}
	
	num get staffLineWidth { return _staffLineWidth; }		
	void set staffLineWidth(num value) {
		_staffLineWidth = (value > 0)? value : 1.0;
	}
	
	num get beamWidth { return _beamWidth; }		
	void set beamWidth(num value) {
		_beamWidth = (value > 0)? value : 5.0;
	}
	
	num get stemWidth { return _stemWidth; }		
	void set stemWidth(num value) {
		_stemWidth = (value > 0)? value : 1.0;
	}
	
	num get staffSpacing { return _staffSpacing; }		
	void set staffSpacing(num value) {
		_staffSpacing = value;
	}
	
	num get staffLineSpacing { return _staffLineSpacing; }//not taken from musicXML
	void set staffLineSpacing(num value) { _staffLineSpacing = value; }
	
	num get rightSystemMargin { return _rightSystemMargin; }		
	void set rightSystemMargin(num value) {
		_rightSystemMargin = value;
	}
	
	num get leftSystemMargin { return _leftSystemMargin; }		
	void set leftSystemMargin(num value) {
		_leftSystemMargin = value;
	}
	
	num get topSystemDistance { return _topSystemDistance; }		
	void set topSystemDistance(num value) {
		_topSystemDistance = value;
	}
	
	num get systemSpacing { return _systemSpacing; }		
	void set systemSpacing(num value) {
		_systemSpacing = value;
	}
	
	num get bottomPageMargin { return _bottomPageMargin; }		
	void set bottomPageMargin(num value) {
		_bottomPageMargin = value;
	}
	
	num get topPageMargin { return _topPageMargin; }		
	void set topPageMargin(num value) {
		_topPageMargin = value;
	}
	
	num get rightPageMargin { return _rightPageMargin; }		
	void set rightPageMargin(num value) {
		_rightPageMargin = value;
	}
	
	num get leftPageMargin { return _leftPageMargin; }		
	void set leftPageMargin(num value) {
		_leftPageMargin = value;
	}
	
	num get pageWidth { return _pageWidth; }		
	void set pageWidth(num value) {
		_pageWidth = value;
	}
	
	num get pageHeight { return _pageHeight; }		
	void set pageHeight(num value) {
		_pageHeight = value;
	}
	
	String get rights { return _rights; }		
	void set rights(String value) {
		_rights = value;
	}
	
	String get software => _software;
	void set software(String value){ _software = value; }
	
	num get clefDistanceFromBarline { return _clefDistanceFromBarline; }		
	void set clefDistanceFromBarline(num value) { _clefDistanceFromBarline = value; }


	/**
	 * width granted for a quarter note in music spacing
	 */
	num get qNoteWidth { return _qNoteWidth; }
	void set qNoteWidth(num value) { _qNoteWidth = value;	}

	/**
	 * width granted for a single accidental in a key signature for music spacing
	 */
	num get keySigWidth { return _keySigWidth; }
	void set keySigWidth(num value) { _keySigWidth = value; }

	/**
	 * width granted for a time signature in music spacing
	 */
	num get timeSigWidth { return _timeSigWidth; }
	void set timeSigWidth(num value) { _timeSigWidth = value;	}

	/**
	 * width granted for a normal sized clef in music spacing
	 */
	num get clefWidth { return _clefWidth; }
	void set clefWidth(num value) { _clefWidth = value; }

	/**
	 * width of space before notes begin in a measure for music spacing
	 */
	num get measureLeadIn { return _measureLeadIn; }
	void set measureLeadIn(num value) { _measureLeadIn = value; }

	/**
	 * minimum allowed measure width for music spacing
	 */
	num get minMeasureWidth { return _minMeasureWidth; }
	void set minMeasureWidth(num value) { _minMeasureWidth = value; }
}