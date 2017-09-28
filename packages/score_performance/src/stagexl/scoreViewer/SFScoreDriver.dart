part of score_performance.stagexl;

class SFScoreDriver {

	SFDriverDrawManager _drawManager;

	SFLoader _sfLoader;
	SFPerformanceNoteMaker _performanceNoteMaker;
	SFPlayer _sfPlayer;

	MicManager _micManager;
	
	Score _score;
	MusicXmlParser2 _parser;
	BitmapMusicRenderer _renderer;
	ScoreViewer _scoreViewer;

	bool _isPlaying = false;
	Assessor _assessor;
	InstrumentDO _instrument;
	Function _playbackCompleteCallback;

	//the driver must load some files asynchronously to be ready - this keeps track.
	int _numInitializedComponents = 0;
	Function _initDriverCallback;

	
	SFScoreDriver(String sf2AudioUrl, String sf2XmlUrl, Function readyCallback,
			{InstrumentDO instrument : null }){
		_initDriverCallback = readyCallback;
		
		_init(sf2AudioUrl, sf2XmlUrl, instrument);
	}
	
	void _init(String sf2AudioUrl, String sf2XmlUrl, InstrumentDO instrument){
		_drawManager = new SFDriverDrawManager(this);

//		if (AudioContext == null){
//			throw 'No web audio support!';
//		}
		if (SFPlayer.audioContext == null){
			
			SFPlayer.audioContext = new AudioContext();
			
	    	_sfLoader = new SFLoader();
	    	_sfLoader.loadSoundFont(sf2AudioUrl, sf2XmlUrl, _checkDriverReady);
	    	
	    	_renderer = new BitmapMusicRenderer(_checkDriverReady);
		}
		AudioManager.context = SFPlayer.audioContext;

		_micManager = new MicManager(AudioManager.context);

		if (instrument == null) instrument = InstrumentUtils.instruments[0];
		setInstrument(instrument);
	}

	///attempts to enable microphone, if one is available. User is prompted
	///to give permission the first session.
	Future enableMicrophone(){
		return _micManager.initMicAndGetPermission();
	}

	void unloadScore(){
		if (_score == null){
			return;
		}
		destroyParser();
	}
	
	Future parseScore(String musicXmlString, [
			bool computeMaxKeySizeForRendering = true,
			bool overrideScoreProps = false,
			ScoreProperties scoreProps = null,
			bool keepParserObject = false]){
		var completer = new Completer();
		//var parser = new MusicXMLParser();
		var parser = new MusicXmlParser2();
		parser.parseXML(musicXmlString, computeMaxKeySizeForRendering,
				overrideScoreProps, scoreProps).then((Score score){
			if (keepParserObject){
    			_parser = parser;
    		}
    		completer.complete(score);
		}).catchError((e){
			completer.completeError(e);
		});
		return completer.future;
	}
	
	void destroyParser(){
		_parser = null;
	}
	
	ScoreViewer renderNotation(Score score, num width, num height, [List<String> partNames = null, 
								int measuresPerSystem = 0, bool clearSystemIndents = false]){
		_score = score;

		return _drawManager.renderNotation(width, height, partNames, measuresPerSystem,
				clearSystemIndents);
	}
	
	/**
	 * re-renders the score and adds the new VisualScore to the existing ScoreViewer
	 */
	void resetNotation([num width = 0, num height = 0, int measuresPerSystem = 0,
			List<String> parts = null]){
		_drawManager.resetNotation(width, height, measuresPerSystem, parts);
	}
	
	/**
	 * resizes the scoreViewer visible area - if values are left null, 
	 * existing width and/or height is used
	 */
	void resizeScoreViewer({num width, num height}){
		_drawManager.resizeScoreViewer(width: width, height: height);
	}
	
	void play(Function playbackCompleteCallback, {
			num tempoRatio : 1.0,
			bool playSoundFontNotes : true,
			num metronomeVolume : 1.0,
			NoteGroup startNG : null,
			num endQNoteTime : null,
			int countoffBeats : null,
			num countoffSeconds : 2.0,
			bool playRepeats: false,
			AssessmentType assessmentType : AssessmentType.NONE,
			InstrumentDO instDO : null}){

		if (_sfPlayer != null && _sfPlayer.isPlaying){
			return;
		}
		
		_prepareAudio(tempoRatio, playSoundFontNotes, metronomeVolume, startNG, endQNoteTime, 
				countoffBeats, countoffSeconds, playRepeats);

		if (instDO != null){
			setInstrument(instDO);
		}
		_prepareAssessment(assessmentType);
		
		_playbackCompleteCallback = playbackCompleteCallback;
		_isPlaying = true;
		_sfPlayer.play(_onPlaybackComplete);
		List<num> beatList = _performanceNoteMaker.beatQNotePositions;
		List<num> countoffBeatList = _performanceNoteMaker.countoffBeatQNotePositions;
		_scoreViewer.play(_performanceNoteMaker.sampleTimeStamps, beatList, countoffBeatList, 
						0/*SFPlayer.processMSInterval / 1000*/, 
						startNG, endQNoteTime);
		
		if (_assessor != null) _assessor.start();
		
	}
	
	void stop(){
		if (_sfPlayer != null){
			_sfPlayer.stop();
			_scoreViewer.stop();
			if (_assessor != null){
				_assessor.stop();
			}
		}
		_isPlaying = false;
	}

	void setInstrument(InstrumentDO instDO){
		if (instDO != null){
			_instrument = instDO;
		}
	}
	
	void clearAssessmentVisuals(){
		if (_assessor != null){
			_assessor.clearAssessmentVisuals();
		}
	}
	
	void startBeatTrackPlayback(Function playbackCompleteCallback,
			{bool playSoundFontNotes : true, int countoffBeats : null,
			AssessmentType assessmentType : AssessmentType.NONE}){
		
		//make sure everything is initialized
		if (_sfLoader == null || _score == null){
			throw 'must call both initSFEngine and renderNotation before playback.';
		}
		if (_sfPlayer == null){ _sfPlayer = new SFPlayer();	}
		
		_prepareAssessment(assessmentType);
		
		_playbackCompleteCallback = playbackCompleteCallback;
		
		if (_assessor != null) _assessor.start();
	}
	
	void _onPlaybackComplete(){
		stop(); //causes second call to _sfPlayer.stop() - should be okay
		if (_playbackCompleteCallback != null){
			_playbackCompleteCallback();
		}
	}
	
	void _prepareAudio(num tempoRatio, bool playSoundFontNotes, num metronomeVolume, 
						NoteGroup startNG, num endQNoteTime,
						int countoffBeats, num countoffSeconds, bool playRepeats){
		//make sure everything is initialized
		if (_sfLoader == null || _score == null){
			throw 'must call both initSFEngine and renderNotation before playback.';
		}
		if (_performanceNoteMaker == null){
			_performanceNoteMaker = new SFPerformanceNoteMaker(_sfLoader);
		}
		if (_sfPlayer == null){
			_sfPlayer = new SFPlayer();
		}
		
		//calculate the number of countoff beats
		if (countoffBeats == null){
			//countoffBeats overrides countoffSeconds
			if (countoffSeconds != null){
				countoffBeats = _getCountoffBeatsForSeconds(countoffSeconds,
					startNG, tempoRatio);
			}
			else {
				countoffBeats = 0;
			}
		}
		
		List<num> playbackPath;
		if (playRepeats){
			if (_score.playbackPath == null){
				_score.updatePlaybackPath();
			}
			playbackPath = _score.playbackPath;
		}
		
		//create the notes and add them to the player
		_performanceNoteMaker.addNotesInParts(_score.parts, tempoRatio,
			playSoundFontNotes, metronomeVolume, startNG, endQNoteTime,
			countoffBeats, playbackPath);
		_sfPlayer.clearNotes();
		_sfPlayer.prepareAudio(_performanceNoteMaker.performanceNotes);
	}
	
	int _getCountoffBeatsForSeconds(num seconds, NoteGroup startNG, num tempoRatio){
		if (startNG == null){
			startNG = _score.parts[0].staves[0].measures[0].voices[0].noteGroups[0];
		}
		var stack = startNG.voice.measure.stack;
		
		TempoMarker tm;
		var tmList = stack.tempoMarkers;
		if (tmList != null){
			for (int i = tmList.length - 1; i >= 0; i--){
				if (tmList[i].qNoteTime <= startNG.qNoteTime){
					tm = tmList[i];
				}
			}
		}
		num tempo = (tm != null)? tm.tempo : 90;
		num actualTempo = tempo * tempoRatio;
		
		var startMeasure = startNG.voice.measure;
		int beatType = startMeasure.beatType;
		num qNotesPerCountoffBeat;
      	if (beatType % 8 == 0 && actualTempo >= SFPerformanceNoteMaker.COMPOUND_METER_TEMPO_CUTOFF) {
      		//compound meter - counting 1 beat for every 3
      		qNotesPerCountoffBeat = 3 * (4 / beatType);
      	}
      	else {
      		qNotesPerCountoffBeat = 4 / beatType;
      	}
      	
      	// numBeats * qNotesPerCountoffBeat * (60 / actualTempo) = numSeconds
      	num numBeats = seconds / (qNotesPerCountoffBeat * (60 / actualTempo));
      	return(numBeats.ceil());
	}
	
	void _prepareAssessment(AssessmentType assessType){
		if (assessType == AssessmentType.NONE){
			_assessor = null;
		}
		else if (assessType == AssessmentType.RHYTHM_KEYBOARD){
			_assessor = new RhythmAssessor(_scoreViewer, _sfPlayer, _sfLoader);
		}
		else if (assessType == AssessmentType.PITCH &&
				_micManager.micPermissionGranted){
			_assessor = new PitchAssessor(_scoreViewer);
			(_assessor as PitchAssessor).setInstrument(_instrument);
		}
	}
	
	

	
	void _checkDriverReady(){
		_numInitializedComponents++;
		if (_numInitializedComponents == 2){
			_initDriverCallback();
		}
	}
	
	Score get score { return _score; }
	
	//MusicXMLParser get parser { return _parser; }
	MusicXmlParser2 get parser { return _parser; }
    	
    SFLoader get sfLoader { return _sfLoader; }
    
    ScoreViewer get scoreViewer => _scoreViewer;
    
    bool get isPlaying => _isPlaying;

	InstrumentDO get instrument => _instrument;

	///true if a microphone is available and user has granted permission
	bool get isMicEnabled => _micManager.micPermissionGranted;
}

class SFDriverDrawManager {

	SFScoreDriver _driver;

	ScoreFormatter _scoreFormatter;

	num _scoreViewerWidth = 0;
	num _scoreViewerHeight = 0;

	List<String> _displayedParts;

	SFDriverDrawManager(this._driver){

	}

	/**
	 * renders a new score for the first time
	 */
	ScoreViewer renderNotation(num width, num height, [List<String> partNames = null,
			int measuresPerSystem = 0, bool clearSystemIndents = false]){

		if (clearSystemIndents){
			_clearSystemIndents();
		}

		_scoreFormatter = null;

		_renderMusic(width, height, measuresPerSystem, partNames);
		return _driver._scoreViewer;
	}

	/**
	 * re-renders the score and adds the new VisualScore to the existing ScoreViewer
	 */
	void resetNotation([num width = 0, num height = 0, int measuresPerSystem = 0,
				List<String> partNames = null]){

		if (width == 0) width = _scoreViewerWidth;
		if (height == 0) height = _scoreViewerHeight;

		if (_driver._scoreViewer != null) {
			_driver._scoreViewer.vScore.prepareForRemoval();
		}

		if (partNames == null) partNames = _displayedParts;

		_renderMusic(width, height, measuresPerSystem, partNames);
	}

	/**
	 * resizes the scoreViewer visible area - if values are left null,
	 * existing width and/or height is used
	 */
	void resizeScoreViewer({num width, num height}){
		if (width != null){ _scoreViewerWidth = width; }
		if (height != null){ _scoreViewerHeight = height; }
		if (_driver._scoreViewer != null){
			_driver._scoreViewer.setWidthAndHeight(_scoreViewerWidth, _scoreViewerHeight);
		}
	}

	void _renderMusic(num width, num height, int measuresPerSystem,
		List<String> partNames){
		_markMeasuresForRendering();

		///////////NEW/////////
		var score = _driver.score;
		num pageWidth = _calculatePageWidth(width);
		score.setPageSize(pageWidth, score.scoreProperties.pageHeight);
		///////////////////////

		//create the VisualScore
		_formatMusic(partNames, measuresPerSystem);
		var vScore = _driver._renderer.renderScore(_driver._score, partNames);
		_displayedParts = partNames;

		//create/update the ScoreViewer
		_scoreViewerWidth = width;
		_scoreViewerHeight = height;

		if (_driver.scoreViewer != null){
			_driver.scoreViewer.setScore(vScore);
			_driver.scoreViewer.setWidthAndHeight(width, height);
		}
		else {
			_driver._scoreViewer = new ScoreViewer(vScore, _scoreViewerWidth,
				_scoreViewerHeight);
		}
	}

	void _markMeasuresForRendering() {
		//mark all of the measures as needing re-rendering
		var stacks = _driver._score.getMeasureStacks();
		for (int i = 0; i < stacks.length; i++){
			var stack = stacks[i];
			var measures = stack.measures;
			for (int j = 0; j < measures.length; j++){
				measures[j].notesNeedRendering = true;
			}
		}
	}

	num _calculatePageWidth(num displayWidth){

		num defaultPageWidth = ScoreProperties.DEFAULT_PAGE_WIDTH;

		if (displayWidth < 600){
			return defaultPageWidth * (displayWidth / 900);
		}
		else {
			num defPageWidth = math.min(displayWidth - 600 + 900, 1200);
			return defaultPageWidth * (displayWidth / defPageWidth);
		}
	}

	void _clearSystemIndents(){
		var systems = _driver._score.getSystems();
		for (var system in systems){
			system.indent = 0;
		}
	}


	/**
	 * formats the music for the requested parts
	 * @param	parts the parts to format - if null, all parts are included in the formatting
	 */
	void _formatMusic(List<String> parts, [int measuresPerSystem = 0]) {
		if (_scoreFormatter == null){
			_scoreFormatter = new ScoreFormatter(_driver._score);
		}
		_scoreFormatter.setPartList(parts);
		_scoreFormatter.formatScore2(true, measuresPerSystem);
	}

}