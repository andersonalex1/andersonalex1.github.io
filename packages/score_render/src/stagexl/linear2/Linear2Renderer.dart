part of score_render.stagexl.linear2;

/**
 * ...
 * @author Tyler
 */
class Linear2Renderer {

	Score _score; //the Score object with data to render
	Linear2Score _visualScore; //the resulting rendered score
	Linear2ScoreRenderer _scoreRenderer; //creates VisualSystems

	List<Part> _parts; //the parts being displayed in the VisualScore

	Function _rendererReadyCallback; //called after textures have been loaded

	static const num DISTANCE_BETWEEN_PAGES = 50;
	
	Linear2Renderer(Function readyCallback) {
		_rendererReadyCallback = readyCallback;
		init();
	}
	
	void init() {
		MusicTextures.onCompleteFunction = _rendererReadyCallback;
		MusicTextures.createTextures();
	}

	/**
	 * Creates a VisualScore object from the passed in Score object
	 * @param	score the Score object that provides the source
	 * @param	partNames the list of parts you want rendered
	 * @return	a VisualScore object that can be displayed
	 */
	Linear2Score renderScore(Score score, [List<String> partNames = null]) {
		if (partNames != null){
			partNames = partNames.sublist(0); //we're going to modify this, so create a copy first
		}
		_score = score;
		_visualScore = new Linear2Score(score);

		//get the list of parts we want
		if (partNames == null){
			_parts = score.parts;
		}
		else {
			_parts = [];
			for (var part in score.parts){
				int index = partNames.indexOf(part.name);
				if (index != -1){
					_parts.add(part);
					partNames.removeAt(index);
				}
			}
		}

		//render each system and add it to a VisualPage

		//List<System> systems = score.getSystems(); //the systems to render
		_scoreRenderer = new Linear2ScoreRenderer(score.scoreProperties);
		_scoreRenderer.renderScore(_visualScore, _parts);


		_visualScore.mouseChildren = false;		

		//_visualScore.applyCache(-10, -50, _visualScore.width.toInt() + 15, _visualScore.height.toInt() + 101); 
		return _visualScore;
	}


	/**
	 * returns all VisualNoteGroup objects in the score (a means of accessing all notes in the song)
	 * @return Vector of VisualNoteGroup objects
	 */
	List<Linear2VisualNoteGroup> getVisualNoteGroups() {
		return _visualScore.getVisualNoteGroups();
	}

}

