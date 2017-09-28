part of audio_input.mic;

class MicManager {
	AudioContext _context;
	
	bool _micPermissionGranted = false;
	
	StreamController<Float32List> _micDataController = new StreamController.broadcast();
	
	html.MediaStream _stream; //main connection to the mic input - retain so we keep permission
	
	//audio event subscription and related nodes 
	StreamSubscription<AudioProcessingEvent> _audioProcessingEventSubscription;
	MediaStreamAudioSourceNode _inputNode;
	ScriptProcessorNode _spNode;

	static MicManager _ref;

    MicManager([AudioContext context = null]) {
	    if (_ref == null) _ref = this;
	    else {
	    	throw 'Singleton already created - use MicManager.getInstance() '
		    'instead.';
	    }
	    _context = context;
    }

	static MicManager getInstance([AudioContext context]){
		if (_ref == null) new MicManager(context);
		return _ref;
	}
    
    Future initMicAndGetPermission() async {
    	if (_micPermissionGranted) return;

    	if (_context == null){
			throw "AudioContext must be set first!";
		}
    	

    	try {
    		/*var md = html.window.navigator.mediaDevices;
    		_stream = await md.getUserMedia({'audio': true});*/

		    _stream = await html.window.navigator.getUserMedia(audio: true);
		    print('mic ready');
			_micPermissionGranted = true;
	    }
	    catch(e){
    		//prints NavigatorUserMediaError if no mic device
    		print(e.toString() + " ...maybe make sure mic is enabled.");
	    }
    }


    void startCapture(){
    	if (_context == null){
    		throw "AudioContext must be set first!";
    	}
    	
		_inputNode = _context.createMediaStreamSource(_stream);
    	//many buffer sizes work fine - tested w/ 4096, 1024, 256.
		//_spNode = _context.createScriptProcessor(4096, 1, 1);
		_spNode = _context.createScriptProcessor(1024, 1, 1);
		_audioProcessingEventSubscription = _spNode.onAudioProcess.listen((audioProcessEvent){
			var data = audioProcessEvent.inputBuffer.getChannelData(0);
			if (data.length < 1){
				return;
			}
			else {
				_micDataController.add(data);
			}
		});
		
		_inputNode.connectNode(_spNode);
		_spNode.connectNode(_context.destination);
    }
    
    void stopCapture(){
    	_spNode.disconnect(0);
    	_inputNode.disconnect(0);
    	_audioProcessingEventSubscription.cancel();
    }
    
    Stream<Float32List> get onMicData => _micDataController.stream;
    
    AudioContext get audioContext => _context;
     void set audioContext (AudioContext value) { _context = value; }
     
     bool get micPermissionGranted => _micPermissionGranted;
}