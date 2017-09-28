part of score_performance.stagexl;

class SFScrollDriver {
	
	AudioContext _context;
	SFLoader _sfLoader;
	SFPerformanceNoteMaker _performanceNoteMaker;
	SFPlayer _sfPlayer;
	
	Score _score;

	LinearNoteViewer _noteViewer;
	ScrollViewer _scrollViewer;
	
	num _scrollViewerWidth = 0;
	//num _scrollViewerHeight = 0;
	
	int _numInitializedComponents = 0; //the driver must load some files asynchronously to be ready - this keeps track.
	
	Function _initDriverCallback;
	Function _playbackCompleteCallback;
	
	SFScrollDriver(String sf2AudioUrl, String sf2XmlUrl, Function readyCallback){
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
	    	
	    	_noteViewer = new LinearNoteViewer(_checkDriverReady);
		}
		AudioManager.context = SFPlayer.audioContext;
	}
	
	Future parseScore(String musicXmlString, [bool computeMaxKeySizeForRendering = true, bool overrideScoreProps = false]){
		var completer = new Completer();
		var parser = new MusicXmlParser2();
		parser.parseXML(musicXmlString, computeMaxKeySizeForRendering, overrideScoreProps).then((Score score){
			completer.complete(score);
		});
		return completer.future;
	}
	
	ScrollViewer renderNotation(Score score, num width, num height, [Part part = null]){
		_score = score;
		
		_scrollViewerWidth = width;
		//_scrollViewerHeight = height;
		_noteViewer.displayNotes((part == null)? _score.parts[0] : part);
		_scrollViewer = new ScrollViewer(_noteViewer, _scrollViewerWidth);

		return _scrollViewer;
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
		_scrollViewer.play(_performanceNoteMaker.sampleTimeStamps, 0);
		
	}
	
	void stop(){
		if (_sfPlayer != null){
			_sfPlayer.stop();
			_scrollViewer.stop();
		}
	}
	
	void _onPlaybackComplete(){
		stop(); //causes second call to _sfPlayer.stop() - should be okay
		if (_playbackCompleteCallback != null){
			_playbackCompleteCallback();
		}
	}
	
	
	void _checkDriverReady(){
		_numInitializedComponents++;
		if (_numInitializedComponents == 2){ 
			_initDriverCallback();
		}
	}
	
	Score get score { return _score; }
}