part of score_player_example;

class BasicPlayer extends AbstractPlayer {
	BasicPlayer({PlayerInitConfig config : null}):super(config: config){

	}

	@override
	void init(PlayerInitConfig config){
		config.notationVOffset = 40;
		config.showNoteNames = true;
		super.init(config);
	}

	@override
	AbstractControls createControls(){
		return new BasicControls(this);
	}

	@override
	AbstractBarControls createBarControls(){
		return null;
	}
}

class BasicControls extends AbstractControls {
	SimpleButton _playBtn;
	SimpleButton _upTempoBtn;
	SimpleButton _downTempoBtn;

	Bitmap _playBtnBmp;
	Bitmap _stopBtnBmp;

	TextField _tempoTF;

	int _tempoPercentage = 100; //100 is default

	num _unscaledWidth = 380;

	bool _micAccessRequested = false;

	static const String TEMPO_CHANGED = "tempoChanged";

	BasicControls(BasicPlayer playerManager):super(playerManager) {
	}

	@override
	void setWidth(num width){
		scaleX = scaleY = math.min(1.75, width / _unscaledWidth);
	}

	@override
	num getHeight(){
		return height + (5 * scaleY);
	}

	@override
	void setMode(int mode){
		if (mode == AbstractControls.DISABLED_MODE){
			_playBtn.mouseEnabled = false;
			_upTempoBtn.mouseEnabled = false;
			_downTempoBtn.mouseEnabled = false;
		}
		else if (mode == AbstractControls.STOPPED_MODE){
			_playBtn.mouseEnabled = true;
			_upTempoBtn.mouseEnabled = true;
			_downTempoBtn.mouseEnabled = true;

			_playBtn.upState = _playBtn.downState = _playBtn.overState =
				_playBtn.hitTestState = _playBtnBmp;
		}
		else if (mode == AbstractControls.PLAYING_MODE){
			_playBtn.mouseEnabled = true;
			_upTempoBtn.mouseEnabled = false;
			_downTempoBtn.mouseEnabled = false;

			_playBtn.upState = _playBtn.downState = _playBtn.overState =
				_playBtn.hitTestState = _stopBtnBmp;
		}
	}

	@override
	void draw(){
		var gbd = pm.resourceManager
			.getTextureAtlas("controls").getBitmapData;

		_playBtnBmp = new Bitmap(gbd("playBtn"));
		_stopBtnBmp = new Bitmap(gbd("stopBtn"));

		_playBtn = new SimpleButton(_playBtnBmp, _playBtnBmp, _playBtnBmp,
			_playBtnBmp);
		var upBmp = new Bitmap(gbd("upBtn"));
		_upTempoBtn = new SimpleButton(upBmp, upBmp, upBmp, upBmp);
		var downBmp = new Bitmap(gbd("downBtn"));
		_downTempoBtn = new SimpleButton(downBmp, downBmp, downBmp, downBmp);

		_tempoTF = new TextField('', new TextFormat('Arial', 24, 0x525174));
		_tempoTF.scaleX = _tempoTF.scaleY = 0.5;
		_tempoTF.autoSize = TextFieldAutoSize.LEFT;
		_tempoTF.mouseEnabled = false;

		_playBtn.x = 0;
		_playBtn.y = 0;
		_downTempoBtn.x = 50;
		_downTempoBtn.y = 3;
		_upTempoBtn.x = 100;
		_upTempoBtn.y = 3;

		_tempoTF.x = 95;
		_tempoTF.y = 23;
		_updateTempoDisplay();

		this.addChild(_playBtn);
		this.addChild(_upTempoBtn);
		this.addChild(_downTempoBtn);

		this.addChild(_tempoTF);
	}

	@override
	void addListeners(){
		_upTempoBtn.onMouseClick.listen(_onTempoUpBtnClick);
		_upTempoBtn.onTouchTap.listen(_onTempoUpBtnClick);
		_downTempoBtn.onMouseClick.listen(_onTempoDownBtnClick);
		_downTempoBtn.onTouchTap.listen(_onTempoDownBtnClick);
		_playBtn.onMouseClick.listen(_onPlayBtnClick);
		_playBtn.onTouchTap.listen(_onPlayBtnClick);
	}

	void _onTempoUpBtnClick(InputEvent e){
		_tempoPercentage += 10;
		if (_tempoPercentage > 400){ _tempoPercentage = 400; }
		_updateTempoDisplay();
	}

	void _onTempoDownBtnClick(InputEvent e){
		_tempoPercentage -= 10;
		if (_tempoPercentage < 10){ _tempoPercentage = 10; }
		_updateTempoDisplay();
	}

	void _updateTempoDisplay(){
		_tempoTF.text = 'Tempo: ${_tempoPercentage}%';
		num span = _upTempoBtn.x + _upTempoBtn.width - _downTempoBtn.x;
		_tempoTF.x =  _downTempoBtn.x + (span - _tempoTF.textWidth * 0.5) / 2;
	}

	void _onPlayBtnClick(InputEvent e){
		if (pm.isPlaying) pm.stop();
		else {
			if (!_micAccessRequested){
				pm.getMicrophonePermission().then((_){
					_micAccessRequested = true;
				});
				return;
			}
			//pm.play(false, 0, 0, null, null, AssessmentType.RHYTHM_KEYBOARD);
			pm.play(false, 0, 0, null, null, AssessmentType.PITCH);
		}
	}

	@override
	num get tempoRatio {
		return (_tempoPercentage / 100);
	}
}