part of sf2.audio;

class AudioBufferLoader {
	//OfflineAudioContext _context;
	AudioContext _context;
	List<String> _urlList;
	Function _callback;
	
	List<AudioBuffer> _bufferList;
	int _loadCount = 0;
	
	HttpRequest _request;
	
	StreamController<String> _audioLoadProgressController =
		new StreamController.broadcast();
	
	StreamSubscription<ProgressEvent> _progressListener;
	
	AudioBufferLoader(List<String> urlList, Function callback,
			AudioContext context){
		//_context = new OfflineAudioContext(1, 2967271, 44100);
		_context = context;
		_urlList = urlList;
		_callback = callback;
		
		_bufferList = [];
	}
	
	void load(){
		for (int i = 0; i < _urlList.length; i++){
			_loadBuffer(_urlList[i], i);
		}
	}
	
	void _loadBuffer(String url, int index){
		_audioLoadProgressController.add("downloading audio...");
		_request = new HttpRequest();
		_request.open("GET", url, async: true);
		_request.responseType = "arraybuffer";
		
		_request.onLoad.listen(_onBufferLoaded);
		_progressListener = _request.onProgress.listen(_onProgress);
		
		_request.send();
	}
	
	void _onProgress(ProgressEvent e){
		//print(e.loaded / e.total);
		_audioLoadProgressController.add("audio download ${(100 *
			e.loaded / e.total).toStringAsFixed(1)}% complete...");
	}
	
	void _onBufferLoaded(Event e){
		_progressListener.cancel();
		_audioLoadProgressController.add("audio downloaded... extracting...");
		_context.decodeAudioData(_request.response).then((AudioBuffer buffer) {
			_bufferList.add(buffer);
			_loadCount++;
			if (_loadCount == _urlList.length){
				//_audioLoadProgressController.add("audio extracted");
				_callback(_bufferList);
				_cleanup();
			}
		}).catchError((e){
			print(e);
		});
	}
	
	void _cleanup(){
		_bufferList = null;
	}
	
	Stream<String> get audioLoadProgress {
		return _audioLoadProgressController.stream;
	}

}

