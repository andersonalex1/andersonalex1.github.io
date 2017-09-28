part of score_render.stagexl.bitmap_renderer;

class VisualScore extends Sprite {
	Score _score;
	ScoreProperties _scoreProps;
	List<VisualPage> _visualPages;
	
	//NoteLabeler _noteLabeler; //displays note name tool tips on notes upon mouseover
	
	static const num DISTANCE_BETWEEN_PAGES = 50;
	
	VisualScore(Score score) {
		
		_score = score;
		_scoreProps = score.scoreProperties;
		init();
	}
	
	void init() {
		this.scaleX = _scoreProps.mmHeight / ScoreProperties.STANDARD_MM_HEIGHT;
		this.scaleY = _scoreProps.mmHeight / ScoreProperties.STANDARD_MM_HEIGHT;
		//print(this.scaleX);
	}
	
	
	/**
	 * adds a single invisible pixel to each of the four corners of the score so that it can be resized properly
	 */
	void addWidthHeightMarkers() {
		//add a single pixel to upper left corner to enforce correct width
		this.graphics.beginPath();
		this.graphics.lineTo(0, 1);
		this.graphics.moveTo(_scoreProps.pageWidth, 0);
		this.graphics.lineTo(_scoreProps.pageWidth, 1);
		this.graphics.strokeColor(0x00000000, 1);
		this.graphics.closePath();
	}

	/**
	 * Gets all of the VisualSystem objects in the VisualScore
	 * @return
	 */
	List<VisualSystem> getVisualSystems() {
		List<VisualSystem> vSystems = [];
		for (var page in _visualPages) {
			List<VisualSystem> systems = page.visualSystems;
			for (var system in systems) {
				vSystems.add(system);
			}
		}

		return vSystems;
	}
	
	/**
	 * Gets all of the VisualNoteGroup objects in the score
	 */
	List<VisualNoteGroup> getVisualNoteGroups() {
		List<VisualNoteGroup> vNoteGroups = new List<VisualNoteGroup>();
		for (var page in _visualPages) {
			List<VisualSystem> systems = page.visualSystems;
			for (var system in systems) {
				List<VisualNoteGroup> noteGroups = system.visNoteGroups;
				for (var vng in noteGroups) {
					vNoteGroups.add(vng);
				}
			}
		}
		
		return vNoteGroups;
	}
	
	/**
	 * gets the VisualSystem object that lies under the past in Point
	 * @param point a Point object the with coordinates of the point to check against each system in the score
	 * @return a VisualSystem if one is found, otherwise null
	 */
	VisualSystem getVisualSystemUnderPoint(Point point) {
		var vSystems = getVisualSystems();
		int numSystems = vSystems.length;
		for (int i = 0; i < numSystems; i++) {
			var visSystem = vSystems[i];
			if (visSystem.scoreX <= point.x && visSystem.scoreX + visSystem.width > point.x && 
					visSystem.scoreY <= point.y && visSystem.scoreY + visSystem.height > point.y) {
				return visSystem;
			}
		}
		return null;
	}
	
	/**
	 * adds mouse over note name labels to the notes
	 */
//	void addNoteNameLabels() {
//		_noteLabeler = new NoteLabeler(this);
//	}
	
	/**
	 * removes mouse over note name labels
	 */
//	void removeNoteNameLabels() {
//		_noteLabeler.kill();
//		_noteLabeler = null;
//	}
	
	/**
	 * performs cleanup tasks
	 */
	void prepareForRemoval() {
//		if (_noteLabeler != null) {
//			_noteLabeler.kill();
//		}
	}
	
	/**
	 * The visual pages that are children of this VisualScore
	 */
	List<VisualPage> get visualPages { return _visualPages; }
	void set visualPages(List<VisualPage> value) { _visualPages = value; }
	
	/**
	 * The ScoreProperties object from the Score
	 */
	ScoreProperties get scoreProps { return _scoreProps; }
	
	/**
	 * The Score object used to generate this VisualScore
	 */
	Score get score { return _score; }

}