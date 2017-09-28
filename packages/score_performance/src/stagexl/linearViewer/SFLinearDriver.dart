part of score_performance.stagexl;

class SFLinearDriver {
	
	AudioContext _context;
	SFLoader _sfLoader;
	SFPerformanceNoteMaker _performanceNoteMaker;
	SFPlayer _sfPlayer;
	
	Score _score;
	MusicXmlParser2 _parser;
	ScoreFormatter _scoreFormatter;
	Linear2Renderer _renderer;
	
	LinearViewer _linearViewer;
	
	num _scoreViewerWidth = 0;
	num _scoreViewerHeight = 0;
	
	List<String> _displayedParts;
	
	int _numInitializedComponents = 0; //the driver must load some files asynchronously to be ready - this keeps track.
	
	Function _initDriverCallback;
	Function _playbackCompleteCallback;
	
	SFLinearDriver(String sf2AudioUrl, String sf2XmlUrl, Function readyCallback){
		_initDriverCallback = readyCallback;
		
		_init(sf2AudioUrl, sf2XmlUrl);
	}
	
	void _init(String sf2AudioUrl, String sf2XmlUrl){
		if (AudioContext == null){
			throw 'No web audio support!';
		}
		if (SFPlayer.audioContext == null){
			
			SFPlayer.audioContext = new AudioContext();
	    	_sfLoader = new SFLoader();
	    	_sfLoader.loadSoundFont(sf2AudioUrl, sf2XmlUrl, _checkDriverReady);
	    	
	    	_renderer = new Linear2Renderer(_checkDriverReady);
		}
		AudioManager.context = SFPlayer.audioContext;
	}
	
	Future parseScore(String musicXmlString, [bool computeMaxKeySizeForRendering = true, bool overrideScoreProps = false,
					ScoreProperties scoreProps = null, bool keepParserObject = false]){
		var parser = new MusicXmlParser2();
		var completer = new Completer();
		parser.parseXML(musicXmlString, computeMaxKeySizeForRendering, overrideScoreProps, scoreProps).then((Score score){
			if (keepParserObject){
    			_parser = parser;
    		}
    		completer.complete(score);
		});
		return completer.future;
	}
	
	void destroyParser(){
		_parser = null;
	}
	
	LinearViewer renderNotation(Score score, num width, num height, [List<String> partNames = null]){
		
		_score = score;
		
		_scoreFormatter = new ScoreFormatter(score);
		
		_scoreViewerWidth = width;
		_scoreViewerHeight = height;
		_linearViewer = _renderScore(partNames);

		return _linearViewer;
	}
	
	//void prepareAudio(num tempoRatio, [bool playSoundFontNotes = true, num metronomeVolume = 1.0, 
    //					bool asyncPrep = false, Function readyCallback = null]){
	void prepareAudio(num tempoRatio, [bool playSoundFontNotes = true, num metronomeVolume = 1.0]){
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
		
		//create the notes and add them to the player
		_performanceNoteMaker.addNotesInParts(_score.parts, tempoRatio, playSoundFontNotes, metronomeVolume);
		_sfPlayer.clearNotes();
		//_sfPlayer.prepareAudio(_performanceNoteMaker.performanceNotes, readyCallback, asyncPrep);
		_sfPlayer.prepareAudio(_performanceNoteMaker.performanceNotes);
	}
	
	void play(Function playbackCompleteCallback){
		//if (_sfPlayer == null || _sfPlayer.isPlaying || !_sfPlayer.audioReady){
		if (_sfPlayer == null || _sfPlayer.isPlaying){
			return;
		}
		_playbackCompleteCallback = playbackCompleteCallback;
		_sfPlayer.play(_onPlaybackComplete);
		_linearViewer.play(_performanceNoteMaker.sampleTimeStamps, 0, SFPlayer.processMSInterval / 1000, _context);
		
	}
	
	void stop(){
		if (_sfPlayer != null){
			_sfPlayer.stop();
			_linearViewer.stop();
		}
	}
	
	void _onPlaybackComplete(){
		stop(); //causes second call to _sfPlayer.stop() - should be okay
		if (_playbackCompleteCallback != null){
			_playbackCompleteCallback();
		}
	}
	
	
	/**
	 * renders the music notation, creating and returning a ScoreViewer object
	 * @param partName the part to render - if blank (""), the whole score is rendered
	 * @return a ScoreViewer object containing the rendered notation
	 */
	LinearViewer _renderScore([List<String> partNames = null]) {

		_formatMusic(partNames);
		var linearScore = _renderer.renderScore(_score, partNames);
		_displayedParts = partNames;

		return (new LinearViewer(linearScore, _scoreViewerWidth));

	}
	
	
	/**
	 * formats the music for the requested parts
	 * @param	parts the parts to format - if null, all parts are included in the formatting
	 */
	void _formatMusic(List<String> parts) {
		_scoreFormatter.setPartList(parts);
		_scoreFormatter.formatScore2(true);
	}
	
	void _checkDriverReady(){
		_numInitializedComponents++;
		if (_numInitializedComponents == 2){ 
			_initDriverCallback();
		}
	}
	
	Score get score { return _score; }
	
	MusicXmlParser2 get parser { return _parser; }
	
	SFLoader get sfLoader { return _sfLoader; }
	
}