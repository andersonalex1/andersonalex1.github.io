part of score_player;

class BarControls extends AbstractBarControls {

	SimpleButton playBtn;
	SimpleButton repeatBtn;
	SimpleButton halfSpeedBtn;

	static const num TEMPO_INCREMENT = 0.05;
	
	BarControls(AbstractPlayer playerManager): super(playerManager){

	}

	@override
	void draw(){
		super.draw();

		var gbd = pm.resourceManager.getTextureAtlas("controls").getBitmapData;
		var playBmp = new Bitmap(gbd("playBtn"));
		playBtn = new SimpleButton(playBmp, playBmp, playBmp, playBmp);
		var repeatBmp = new Bitmap(gbd("loopBtn"));
		repeatBtn = new SimpleButton(repeatBmp, repeatBmp, repeatBmp, repeatBmp);
    	var halfBmp = new Bitmap(gbd("halfSpeedBtn"));
    	halfSpeedBtn = new SimpleButton(halfBmp, halfBmp, halfBmp, halfBmp);
    	
    	playBtn.x = 10;
    	playBtn.y = 0;
    	repeatBtn.x = 60;
    	repeatBtn.y = 0;
    	halfSpeedBtn.x = 110;
    	halfSpeedBtn.y = 0;
    	
		//all buttons should be added to super classes buttonContainer
		buttonContainer.addChild(playBtn);
		buttonContainer.addChild(repeatBtn);
		buttonContainer.addChild(halfSpeedBtn);
		buttonContainer.scaleX = buttonContainer.scaleY = 1.4;
	}

	@override
	void toggleEnabled(bool enabled){
		super.toggleEnabled(enabled);

		playBtn.visible = enabled;
		repeatBtn.visible = enabled;
		halfSpeedBtn.visible = enabled;

		_removeButtonListeners();
		if (enabled) _addButtonListeners();
	}

	void _onPlayBtnClick(InputEvent e) {
		pm.play(false, 0, 0, getStartNote(), null);
	}

	void _onRepeatBtnClick(InputEvent e) {
		_getNumLoopMeasures().then((int numLoopMeasures){
			if (numLoopMeasures == -1) return;

			pm.play(true, 0, 0, getStartNote(), getEndNote(numLoopMeasures));
		});
	}

	void _onHalfSpeedBtnClick(InputEvent e) {
		_getNumLoopMeasures().then((int numLoopMeasures){
			if (numLoopMeasures == -1) return;

			pm.play(true, 0.5, TEMPO_INCREMENT, getStartNote(),
				getEndNote(numLoopMeasures));
		});

	}

	Future<int> _getNumLoopMeasures(){
		var completer = new Completer();
		List<String> choices = [];
		for (int i = 0; i < 16; i++){
			choices.add((i + 1).toString() + ((i > 0)? " bars" : " bar"));
		}
		new DivList(stage, 200, 200, 'Repeat...', choices).show()
			.then((int index){
			if (index == -1){
				completer.complete(-1);
			}
			else {
				completer.complete(index + 1);
			}
		});
		return completer.future;
	}

	void _stopPropagationHandler(InputEvent e){
		e.stopImmediatePropagation();
	}

	void _addButtonListeners() {
		playBtn.addEventListener(MouseEvent.CLICK, _onPlayBtnClick);
		playBtn.addEventListener(TouchEvent.TOUCH_TAP, _onPlayBtnClick);
		repeatBtn.addEventListener(MouseEvent.CLICK, _onRepeatBtnClick);
		repeatBtn.addEventListener(TouchEvent.TOUCH_TAP, _onRepeatBtnClick);
		halfSpeedBtn.addEventListener(MouseEvent.CLICK, _onHalfSpeedBtnClick);
		halfSpeedBtn.addEventListener(TouchEvent.TOUCH_TAP, _onHalfSpeedBtnClick);

		playBtn.addEventListener(MouseEvent.MOUSE_DOWN, _stopPropagationHandler);
		playBtn.addEventListener(TouchEvent.TOUCH_BEGIN, _stopPropagationHandler);
		repeatBtn.addEventListener(MouseEvent.MOUSE_DOWN, _stopPropagationHandler);
		repeatBtn.addEventListener(TouchEvent.TOUCH_BEGIN, _stopPropagationHandler);
		halfSpeedBtn.addEventListener(MouseEvent.MOUSE_DOWN, _stopPropagationHandler);
		halfSpeedBtn.addEventListener(TouchEvent.TOUCH_BEGIN, _stopPropagationHandler);
	}

	void _removeButtonListeners() {
		playBtn.removeEventListener(MouseEvent.CLICK, _onPlayBtnClick);
		playBtn.removeEventListener(TouchEvent.TOUCH_TAP, _onPlayBtnClick);
		repeatBtn.removeEventListener(MouseEvent.CLICK, _onRepeatBtnClick);
		repeatBtn.removeEventListener(TouchEvent.TOUCH_TAP, _onRepeatBtnClick);
		halfSpeedBtn.removeEventListener(MouseEvent.CLICK, _onHalfSpeedBtnClick);
		halfSpeedBtn.removeEventListener(TouchEvent.TOUCH_TAP, _onHalfSpeedBtnClick);

		playBtn.removeEventListener(MouseEvent.MOUSE_DOWN, _stopPropagationHandler);
		playBtn.removeEventListener(TouchEvent.TOUCH_BEGIN, _stopPropagationHandler);
		repeatBtn.removeEventListener(MouseEvent.MOUSE_DOWN, _stopPropagationHandler);
		repeatBtn.removeEventListener(TouchEvent.TOUCH_BEGIN, _stopPropagationHandler);
		halfSpeedBtn.removeEventListener(MouseEvent.MOUSE_DOWN, _stopPropagationHandler);
		halfSpeedBtn.removeEventListener(TouchEvent.TOUCH_BEGIN, _stopPropagationHandler);
	}
}
