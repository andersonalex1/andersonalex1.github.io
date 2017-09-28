part of score_render.stagexl.linear2;

class Linear2Score extends Sprite {
	Score _score;
	ScoreProperties _scoreProps;
	
	List<Linear2VisualNoteGroup> _visualNoteGroups;
	
	num _pixelsPerQNote = 100; //the follow distance in pixels awarded to a quarter note 
	num _firstNoteStartPos = 50; //the pixel position of the first note/rest from the beginning of the staff
	
	static const num DISTANCE_BETWEEN_PAGES = 50;
	
	Linear2Score(Score score) {
		
		_score = score;
		_scoreProps = score.scoreProperties;
		
		init();
	}
	
	void init() {
		//this.scaleX = _scoreProps.mmHeight / ScoreProperties.STANDARD_MM_HEIGHT;
		//this.scaleY = _scoreProps.mmHeight / ScoreProperties.STANDARD_MM_HEIGHT;
		
		_visualNoteGroups = [];
	}
	
	
	/**
	 * adds a single invisible pixel to each of the four corners of the score so that it can be resized properly
	 */
	void addWidthHeightMarkers() {
		//add a single pixel to upper left corner to enforce correct width
		this.graphics.beginPath();
		this.graphics.lineTo(0, 1);
		this.graphics.moveTo(this.width, 0);
		this.graphics.lineTo(this.width, 1);
		this.graphics.strokeColor(0x00000000, 1);
		this.graphics.closePath();
	}
	
	void addVisualNoteGroup(Linear2VisualNoteGroup vng){
		_visualNoteGroups.add(vng);
	}

	
	/**
	 * Gets all of the VisualNoteGroup objects in the score
	 */
	List<Linear2VisualNoteGroup> getVisualNoteGroups() {
		return _visualNoteGroups;
	}
	
	
	/**
	 * The ScoreProperties object from the Score
	 */
	ScoreProperties get scoreProps { return _scoreProps; }
	
	/**
	 * The Score object used to generate this VisualScore
	 */
	Score get score { return _score; }
	
	/**
	 * the follow distance in pixels awarded to a quarter note 
	 */
	num get pixelsPerQNote { return _pixelsPerQNote; }
	void set pixelsPerQNote(num value) { _pixelsPerQNote = value; }
	
	/**
	 * the pixel position of the first note/rest from the beginning of the staff
	 */
	num get firstNoteStartPos { return _firstNoteStartPos; }
	void set firstNoteStartPos(num value){ _firstNoteStartPos = value; }

}