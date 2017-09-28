part of score_player;

abstract class AbstractPlayer extends Sprite {
	PlayerInitConfig _config;

	ResourceManager _resourceManager;
	_PlaybackManager _pbm;
	_LayoutManager _lm;

// ignore: unused_field
	BarControls _barPlayControls;
	AbstractControls controls;

	Completer _songLoadCompleter;

	SFScoreDriver _driver;
	Score score;
	ScoreViewer _scoreViewer;
	ScoreManager scoreManager;
	Arranger arranger;

	InstrumentDO instrument;

	AbstractPlayer({PlayerInitConfig config : null}){

		init(config?? new PlayerInitConfig());
	}

	void init(PlayerInitConfig config){
		_config = config;

		scoreManager = new ScoreManager();
		if (_config.useArranger) arranger = new Arranger(scoreManager);

		notifyStatus("Loading graphics...");
		String root = _config.resourceRoot;
		MusicTextures.pathPrefix = root;
		_resourceManager = new ResourceManager();
		for (var key in _config.atlases.keys){
			_resourceManager.addTextureAtlas(key, root + _config.atlases[key]);
		}
		_resourceManager.load().then((_){
			//textures loaded
			_lm = new _LayoutManager(this);
			_pbm = new _PlaybackManager(this);
			_pbm.addEventListener(_PlaybackManager.PLAYBACK_MANAGER_READY, (_){
				dispatchEvent(new PlayerEvent(PlayerEvent.PLAYER_INIT));
			});

			_lm._width = _config.playerWidth;
			_lm._height = _config.playerHeight;
			setInstrument(_config.instrument);
			_lm.showFingerings = _config.showFingerings;
			_lm.showNoteNames = _config.showNoteNames;
			_lm.notationVOffset = _config.notationVOffset;
		});
	}

	void resizeDisplay(num setWidth, num setHeight){
		_lm.resizeDisplay(setWidth, setHeight);
	}

	///forces the player to close (the user may have clicked back button)
	void closeSong(){
		if (_pbm.isPlaying){
			stop();
		}

		_killScore();
	}


	Future loadSong(String musicXMLString, {int partIndex: 0}){

		//create the score, render it, and add it to the display
		notifyStatus("Rendering music...");

		_driver.parseScore(musicXMLString, true, true).then((Score score){
			this.score = score;
			//break up the final processing with async calls to reduce call stack
			Timer.run((){
				scoreManager.score = score;
				currentPart = (partIndex < score.parts.length)
					? score.parts[partIndex]
					: score.parts[0];

				editParsedScore();

				Timer.run((){
					//render the score
					_lm._renderScore();

					Timer.run((){
						dispatchEvent(new PlayerEvent(PlayerEvent.SONG_LOADED));
						_songLoadCompleter.complete();
					});

				});

			});


		}).catchError((e){
			_songLoadCompleter.completeError(e);
		});

		_songLoadCompleter = new Completer();
		return _songLoadCompleter.future;
	}

	///starts playback
	void play([bool loop = false, num tempo = 0, num tempoIncrement = 0,
			NoteGroup startNG = null, NoteGroup endNG = null,
			AssessmentType assessmentType = AssessmentType.NONE]){
		_pbm._play(loop, tempo, tempoIncrement, startNG, endNG, assessmentType);
	}

	///stops playback
	void stop(){
		_pbm._stop();
	}

	///scrolls to the last note playback was started from
	void scrollToStartNote(){
		if (_pbm._playbackDO != null)
			_lm._scrollToNote(_pbm._playbackDO.startNG);
		else
			_lm._scrollToNote(null);
	}

	///attempts to enable microphone, if one is available. User is prompted
	///to give permission the first session.
	Future getMicrophonePermission(){
		return _driver.enableMicrophone();
	}

	/**
	 * Creates and returns the UI controls for the player. The controls extend
	 * AbstractControls, which requires at least the implementation of a stop
	 * button and tempo control.
	 */
	AbstractControls createControls(){
		throw "createControls() must be overridden";
	}

	///Creates and returns controls that are placed directly on the score
	///above a measure. This is optional. To remove this, override this method
	///with no implementation (and no super call). Defaults to BarPlayControls
	///instance.
	AbstractBarControls createBarControls(){
		return new BarControls(this);
	}


	/**
	 * sets the current instrument for assessment and fingering display.
	 * @reRender if true, the display will be immediately reRendered
	 * @showFingerings determines if fingerings will be shown (if available).
	 * If null, the current fingering display setting will not be changed.
	 */
	void setInstrument(InstrumentDO inst){
		instrument = inst;
		_lm.showFingerings = _lm.showFingerings; //update instrument fingerings
	}

	/**
	 * Override this method to make any changes to the parsed Score object
	 * before it is rendered. Examples might be transposing the score,
	 * applying range checking, etc.
	 */
	void editParsedScore(){
		setPartPlaybackPresets();
	}

	///sets the midi presets for each part. Override in subclasses for custom
	///handling.
	void setPartPlaybackPresets(){
		for (var part in score.parts){
			if (part.midiChannel != 10){
				part.midiPreset = 0;
			}
		}
	}

	///sets up parts in a stereo field and boosts volume of current part.
	///Override this in subclasses for custom handling.
	void setPartVolumesAndPan(){
		int numParts = score.parts.length;
		for (int i = 0; i < numParts; i++){
			var part = score.parts[i];
			//part.volume *= (part == currentPart)? 2.5 : 1.5;
			part.volume = ((part == currentPart)? 0.4 : 0.3) + (0.2 / numParts);
			part.pan = (numParts > 1)? 0.3 + 0.4 * (i / (numParts - 1)) : 0.5;
		}
	}

	/**
	 * re-renders the score
	 */
	void redisplayScore(){
		_lm._redisplayScore();
	}

	/**
	 * provides String messages of status changes during loading, etc. Override
	 * in subclasses to handle as needed.
	 */
	void notifyStatus(String status){
		print(status);
	}

	/**
	 * handles cleanup tasks when a Score is being unloaded
	 */
	void _killScore(){
		dispatchEvent(new PlayerEvent(PlayerEvent.SONG_CLOSING));

		_lm._handleScoreRemoval();
		_pbm._handleScoreRemoval();
	}

	Part get currentPart => _lm.currentPart;
	void set currentPart(Part value){
		_lm.currentPart = value;
		setPartVolumesAndPan();
	}

	bool get showNoteNames => _lm.showNoteNames;
	void set showNoteNames(bool value){ _lm.showNoteNames = value; }

	bool get showFingerings => _lm.showFingerings;
	void set showFingerings(bool value){ _lm.showFingerings = value; }

	ResourceManager get resourceManager => _resourceManager;

	bool get isPlaying => _pbm.isPlaying;
}

class _PlaybackManager extends EventDispatcher {
	AbstractPlayer _pm;

	StreamSubscription<String> _sfLoadProgressListener;

	_PlaybackDO _playbackDO;

	static final String PLAYBACK_MANAGER_READY = "playbackManagerReady";

	_PlaybackManager(AbstractPlayer playerManager){
		_pm = playerManager;
		_init();
	}

	void _init(){
		_pm.notifyStatus("Initializing sound engine...");

		var root = _pm._config.resourceRoot;
		//_pm._driver = new SFScoreDriver('${root}sf/sf2-2.mp3',
		//      '${root}sf/sf2_v2.json', (){
		_pm._driver = new SFScoreDriver('${root}sf/sf2.wav',
				'${root}sf/sf2_v2.json', (){
			_sfLoadProgressListener.cancel();

			dispatchEvent(new Event(PLAYBACK_MANAGER_READY));
		});


		_sfLoadProgressListener =
			_pm._driver.sfLoader.progressStream.listen(_onSFLoadProgress);
	}

	void _onSFLoadProgress(String message){
		_pm.notifyStatus("Initializing sound engine... $message");
	}

	void _play([bool loop = false, num tempo = 0, num tempoIncrement = 0,
			NoteGroup startNG = null, NoteGroup endNG = null,
			AssessmentType assessmentType = AssessmentType.NONE]){

		if (_pm.score == null) return;

		_playbackDO = new _PlaybackDO();
		_playbackDO.loop = loop;
		_playbackDO.startNG = startNG?? _pm.score.parts[0]
			.getFirstNote();
		_playbackDO.endNG = endNG;
		_playbackDO.assessmentType = assessmentType;
		//use the specified tempo if it isn't 0.
		_playbackDO.tempo = (tempo > 0)? tempo : _pm.controls.tempoRatio;
		_playbackDO.tempoIncrement = tempoIncrement;

		_startPlayback();

		_pm.dispatchEvent(new PlayerEvent(PlayerEvent.PLAYBACK_STARTED));
	}

	void _stop(){
		if (isPlaying) {
			_pm._driver.stop();
			_finishPlayback();
		}
	}

	void _startPlayback() {
		var pdo = _playbackDO;

		if (pdo.playbackFinished) {
			return;
		}

		bool playRepeats = (pdo.loop == false);

		num endQNoteTime = null;
		if (pdo.endNG != null){
			endQNoteTime = pdo.endNG.qNoteTime + pdo.endNG.qNoteDuration;
			if (pdo.endNG.next != null){
				//add the beginning of the next note to the playback region
				//(first note of following measure)
				endQNoteTime += math.min(pdo.endNG.next.qNoteDuration, 0.1);
			}
		}
		_pm._driver.clearAssessmentVisuals();
		_pm._driver.play(_onPlaybackComplete, tempoRatio: pdo.tempo,
			metronomeVolume: 0.0, startNG: pdo.startNG,
			endQNoteTime: endQNoteTime,	countoffSeconds: pdo.countoffSeconds,
			playSoundFontNotes: true, playRepeats: playRepeats,
			assessmentType: pdo.assessmentType);
	}

	void _onPlaybackComplete() {
		if (_playbackDO.loop) {
			if (_playbackDO.tempoIncrement > 0) {
				_playbackDO.tempo += _playbackDO.tempoIncrement;
				if (_playbackDO.tempo > 1.0) {
					_playbackDO.tempo = 1.0;
				}
			}

			_pm._lm._scrollToNote(_playbackDO.startNG);
			int msPerBeat = (1000 *
				(60 / _playbackDO.startNG.playbackTempo)).toInt();
			_playbackDO.countoffSeconds = 0.9;
			const int naturalDelay = 600;
			int pauseDuration = msPerBeat - naturalDelay;
			if (pauseDuration < 0) pauseDuration = 0;

			new Timer(new Duration(milliseconds: pauseDuration),
				()=>_startPlayback());
		}
		else {
			_finishPlayback();
		}
	}

	void _finishPlayback() {
		_playbackDO.playbackFinished = true;
		_pm.dispatchEvent(new PlayerEvent(PlayerEvent.PLAYBACK_FINISHED));
	}

	void _handleScoreRemoval() {

	}

	bool get isPlaying => (_playbackDO != null &&
		!_playbackDO.playbackFinished);
}

class _PlaybackDO {

	bool loop;
	NoteGroup startNG;
	NoteGroup endNG;
	num countoffSeconds = 2.0;
	AssessmentType assessmentType;

	///the tempo increment should be applied each time through a loop
	num tempoIncrement = 0;

	///a tempo ratio (1.0 is full speed). The default tempo of 0 means that
	///this tempo value should be ignored.
	num tempo = 0;

	bool playbackFinished = false;
}

class _LayoutManager extends EventDispatcher {
	AbstractPlayer _pm;

	Part _currentPart;

	num _width;
	num _height;

	//fingerings will be shown for supported instruments
	FingeringDisplayManager _fingeringDM;

	bool _showNoteNames;

	static final String SCORE_RENDERED = "scoreRendered";

	_LayoutManager(AbstractPlayer playerManager){
		_pm = playerManager;
		_init();
	}

	void _init(){
		//create and add the buttons
		_pm.controls = _pm.createControls();
		_pm.addChild(_pm.controls);

		_pm._barPlayControls = _pm.createBarControls();

		_fingeringDM = new FingeringDisplayManager(_pm, _pm._resourceManager);
	}

	void _scrollToNote(NoteGroup ng){
		var sv = _pm._scoreViewer;
		if (sv != null) {
			var system = (ng == null)
				? _pm.score.pages[0].systems[0]
				: ng.voice.measure.stack.systemRef;
			sv.scrollToSystem(system, 0.0);
		}
	}

	void resizeDisplay(num width, num height){
		_width = width;
		_height = height;
		if (_pm._scoreViewer != null && _pm._scoreViewer.parent == _pm){
			_redisplayScore();
		}
	}

	void _renderScore(){
		//called for first render of score only
		var sv = _pm._scoreViewer;
		if (sv != null && sv.parent == _pm){
			_pm.removeChild(sv);
		}

		var parts = _getPartsToDisplay();
		var viewerRect = _calculatePositions();

		sv = _pm._driver.renderNotation(_pm.score, viewerRect.width,
			viewerRect.height, parts, 0, true);
		_pm._scoreViewer = sv;
		sv.x = viewerRect.left;
		sv.y = viewerRect.top;
		_pm.addChild(sv);

		_fingeringDM.setNewScore(sv);

		_notifySongRendered();
	}

	void _redisplayScore() {
		//reformats and displays the score
		List<String> parts = _getPartsToDisplay();
		var viewerRect = _calculatePositions();
		_pm._driver.resetNotation(viewerRect.width, viewerRect.height,
			0, parts);
		_pm._scoreViewer.x = viewerRect.left;
		_pm._scoreViewer.y = viewerRect.top;

		_fingeringDM.setNewScore(_pm._scoreViewer);

		_notifySongRendered();
	}

	Rectangle _calculatePositions(){
		//update the size of the controls for the new width/height and
		//then get position/size info for the ScoreViewer

		_pm.controls.setWidth(width);
		num controlsHeight = _pm.controls.getHeight();
		_fingeringDM.setPosition(0, controlsHeight,
			height - controlsHeight, width);

		num notationHPos = 10 + _fingeringDM.displayWidth;
		num notationVPos = controlsHeight;
		var viewerRect = new Rectangle(notationHPos, notationVPos,
			width - notationHPos, height - notationVPos);

		return viewerRect;
	}

	void _notifySongRendered(){
		var e = new PlayerEvent(PlayerEvent.SONG_RENDERED);
		e.scoreViewer = _pm._scoreViewer;
		_pm.dispatchEvent(e);
	}

	/**
	 * Returns a list of the names of the parts to display when the score is
	 * rendered. Override in subclasses.
	 */
	List<String> _getPartsToDisplay(){
		return (_currentPart != null)? [_currentPart.name] : null;
	}

	void _handleScoreRemoval() {
		var sv = _pm._scoreViewer;
		if (sv != null && sv.parent == _pm){
			_pm.removeChild(sv);
		}
		_currentPart = null;
	}

	Part get currentPart => _currentPart;
	void set currentPart(Part value){
		_currentPart = value;
		showNoteNames = _showNoteNames;
	}

	bool get showFingerings => _fingeringDM._showFingerings;
	void set showFingerings(bool value){
		_fingeringDM.setInstrument(_pm.instrument, value);
	}

	bool get showNoteNames => _showNoteNames;
	void set showNoteNames(bool value){
		_showNoteNames = value;
		if (_currentPart != null){
			if (value){
				_pm.scoreManager.showNoteNames(_currentPart.staves[0]);
			}
			else {
				_pm.scoreManager.showLyrics();
			}
		}
	}

	void set notationVOffset(num value){
		BitmapMusicRenderer.firstPageVerticalOffset = value;
	}

	///gets the total width allowed for the player, including controls,
	///fingerings, and notation
	num get width {
		if (_width != null){
			return _width;
		}
		return (_pm.stage != null)? _pm.stage.stageWidth : 400;
	}

	///gets the total height allowed for the player, including controls,
	///fingerings, and notation.
	num get height {
		if (_height != null){
			return _height;
		}
		return (_pm.stage != null)? _pm.stage.stageHeight : 300;
	}
}

class PlayerEvent extends Event {

	ScoreViewer scoreViewer;

	///dispatched when Player has been completely loaded and is ready to open
	///a song.
	static final String PLAYER_INIT = "playerInit";
	///dispatched each time a song is rendered/re-rendered
	static final String SONG_RENDERED = "songRendered";
	///dispatched the first time a song is loaded, after it is rendered
	static final String SONG_LOADED = "songLoaded";
	///dispatched when playback is started
	static final String PLAYBACK_STARTED = "playbackStarted";
	///dispatched when playback is completely finished, including all loops
	static final String PLAYBACK_FINISHED = "playbackFinished";
	///dispatched when song is being closed (player may still exist)
	static final String SONG_CLOSING = "songClosing";

	PlayerEvent(String type, [bool bubbles = false]):super(type, bubbles);
}

class PlayerInitConfig {
	bool showFingerings = true;
	bool showNoteNames = false;
	InstrumentDO instrument = InstrumentUtils.instruments[0];
	num notationVOffset = 70;

	///the Arranger class provides functionality for arranging songs beyond
	///simple transposition. Range checking, note hiding, etc.
	bool useArranger = false;

	///total width/height of player, including notation and controls
	///if playerWidth/playerHeight are null, stageWidth/stageHeight are used.
	num playerWidth = null;
	num playerHeight = null;

	///the starting path that resources should be loaded from. This MUST end
	///with a final / if not left as "".
	String resourceRoot = "";

	///add any other atlasID/path combos needed. The recorder key must be
	///kept, but the path should be updated as needed. Note: use the
	///resourceRoot property to append a prefix to these paths
	Map<String, String> atlases = {
		"recorder" : "images/atlases/recorder1.json",
		"controls" : "images/atlases/player_controls.json"
	};
}