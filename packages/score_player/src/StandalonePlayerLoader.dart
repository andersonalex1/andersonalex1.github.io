part of score_player;

///acts as a standalone application that can be instantiated.
///reads query parameters to open a songXML
///initializes stageXL and player
class StandalonePlayerLoader {
	PlayerLoaderOptions _options;
	PlayerInitFunction _playerInitFunction;

	AbstractPlayer _player;

	Stage _stage;
	RenderLoop _renderLoop;
	Sprite _container;

	Timer _resizeTimer;

	StandalonePlayerLoader(this._playerInitFunction,
			{PlayerLoaderOptions options : null}){

		_options = options;
		_init();
	}

	void _init(){
		if (_options == null) _options = new PlayerLoaderOptions();

		_createStage();
		_initPlayer();
	}

	void _createStage(){
		html.CanvasElement canvas = html.querySelector('#${_options.canvasID}');

		StageOptions options = new StageOptions();
		options.inputEventMode = InputEventMode.MouseAndTouch;
		options.renderEngine = RenderEngine.Canvas2D;
		_stage = new Stage(canvas, options: options);
		_stage.scaleMode = StageScaleMode.NO_SCALE;
		_stage.align = StageAlign.TOP_LEFT;
		_renderLoop = new RenderLoop();
		_renderLoop.addStage(_stage);

		_container = new Sprite();
		_container.x = 0;
		_container.y = 0;

		_stage.addChild(_container);
	}

	void _initPlayer(){
		_player = _playerInitFunction();
		_container.addChild(_player);
		_player.addEventListener(PlayerEvent.PLAYER_INIT, _onPlayerReady);
	}

	Future _onPlayerReady(PlayerEvent e) async {
		_player.x = 5;
		_player.y = 5;
		_player.resizeDisplay(_stage.stageWidth - 10, _stage.stageHeight - 5);
		_stage.onResize.listen(_onWindowResize);

		_loadSong();
	}

	Future _loadSong() async {
		String url = _getJSParam(_options.songUrlParam);
		if (url == null) url = _options.defaultSongUrl; //can still be null
		if (url != null) url = _options.resourceRoot + url;
		var musicXmlString = await MusicXmlUtils.getMusicXmlStringFromUrl(url);
		if (musicXmlString != null){
			_player.loadSong(musicXmlString);
		}
		else {
			print('problem loading file, url: ${url?? "null"}' );
		}
	}

	Object _getJSParam(String paramName){
		return Uri.base.queryParameters[paramName];
	}

	void _onWindowResize(Event e){
		if (_resizeTimer != null && _resizeTimer.isActive){
			_resizeTimer.cancel();
		}

		_resizeTimer = new Timer(new Duration(milliseconds: 500), (){
			_player.resizeDisplay(_stage.stageWidth - 10,
				_stage.stageHeight - 5);
		});
	}
}

typedef AbstractPlayer PlayerInitFunction();

class PlayerLoaderOptions {
	///id attribute for the canvas tag in the HTML
	String canvasID = "stageCanvas";

	///name of the query string param that points to the musicXML file
	String songUrlParam = "songUrl";

	///can be used to load a default musicXML file if query string doesn't point
	///to one.
	String defaultSongUrl;

	///the starting path that resources should be loaded from. This MUST end
	///with a final / if not left as "".
	String resourceRoot = "";
}