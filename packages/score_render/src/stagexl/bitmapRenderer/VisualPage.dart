part of score_render.stagexl.bitmap_renderer;

class VisualPage extends Sprite {
	num _currentVSystemPos;
	ScoreProperties _scoreProps;
	List<VisualSystem> _visualSystems;
	
	VisualPage(ScoreProperties scoreProps) {
		_scoreProps = scoreProps;
		
		_currentVSystemPos = 0;
		_visualSystems = [];
	}
	
	void addSystem(VisualSystem visualSystem) {
		visualSystem.x = _scoreProps.leftPageMargin;
		visualSystem.y = _currentVSystemPos;
		
		this.addChild(visualSystem);
		
		visualSystem.pageRef = this;
		
		//_currentVSystemPos += _scoreProps.systemSpacing + visualSystem.height;
		_currentVSystemPos += 50.0 + visualSystem.height;
		//visualSystem.opaqueBackground = Math.random() * 0xFFFFFF;
		
		_visualSystems.add(visualSystem);
	}

	/**
	 * removes all VisualSystems from the page
	 */
	void removeAllSystems() {
		for (var vSystem in _visualSystems){
			this.removeChild(vSystem);
		}
		_visualSystems = [];
		_currentVSystemPos = 0;
	}

	/**
	 * Replaces one VisualSystem with another
	 * @param originalVSystem the VisualSystem you want to replace
	 * @param newVSystem the VisualSystem you want to replace it with
	 */
	void replaceSystem(VisualSystem originalVSystem, VisualSystem newVSystem) {
		newVSystem.x = originalVSystem.x;
		newVSystem.y = originalVSystem.y;

		this.removeChild(originalVSystem);
		this.addChild(newVSystem);

		newVSystem.pageRef = this;

		for (int i = 0; i < _visualSystems.length; i++){
			if (_visualSystems[i] == originalVSystem){
				_visualSystems[i] = newVSystem;
				break;
			}
		}
	}
	

	List<VisualSystem> get visualSystems { return _visualSystems; }
	
}