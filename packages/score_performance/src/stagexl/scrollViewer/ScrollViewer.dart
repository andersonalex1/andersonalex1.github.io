part of score_performance.stagexl;

class ScrollViewer extends Sprite {
	LinearNoteViewer _noteViewer;
	Shape _cursor;
	
	num _cursorPosition = 100;
	
	num _viewerWidth = 600;
	
	
	List<SampleTimeStampDO> _timeStamps;
	SampleTimeStampDO _lastTimeStamp;
	SampleTimeStampDO _nextTimeStamp;
	num _currentQNoteToSecondsRatio;
	
	List<LinearVisualNote> _vnList;
	int _vngIndex = 0;
	
	num _passedTime = 0;
	num _leadInSeconds = 0;
	
	bool _isPlaying = false;
	
	EventStreamSubscription<EnterFrameEvent> _enterFrameSubscription;
	
	
	ScrollViewer(LinearNoteViewer noteViewer, [num viewerWidth = 600]){
		_noteViewer = noteViewer;
		_viewerWidth = viewerWidth;
		
		_init();
	}
	
	void _init() {
		_cursor = new Shape();
		
		_cursor.graphics.beginPath();
		_cursor.graphics.moveTo(0, 0);
		_cursor.graphics.lineTo(0, _noteViewer.height);
		_cursor.graphics.strokeColor(0x5500FF00, 20, JointStyle.ROUND, CapsStyle.SQUARE);
		_cursor.graphics.closePath();
		
		_cursor.x = _cursorPosition;
		
		
		this.mask = new Mask.rectangle(0, 0, _viewerWidth, _noteViewer.height);
		
		this.addChild(_noteViewer);
		this.addChild(_cursor);
		
	}
	
	void play(List<SampleTimeStampDO> timeStamps, [num leadInSeconds = 0]) {
		if (timeStamps == null || timeStamps.length < 1){ throw "No time stamps!"; }
		
		_timeStamps = timeStamps;
		
		_lastTimeStamp = new SampleTimeStampDO(0, 0);
		_nextTimeStamp = timeStamps[0];
		_lastTimeStamp.tempo = _nextTimeStamp.tempo;
		_currentQNoteToSecondsRatio = _lastTimeStamp.tempo / 60;
		
        _passedTime = 0;
        _leadInSeconds = leadInSeconds;
		
		//get the list of VisualNoteGroups
		_vnList = _noteViewer.vnList;
		_vnList.sort((LinearVisualNote vn1, LinearVisualNote vn2) => 
						(vn1.noteGroup.qNoteTime <= vn2.noteGroup.qNoteTime)? -1 : 1);
		_vngIndex = 0;
		
		
		
		_startScrolling();
		
	}
	
	
	
	void stop(){
		_stopPlayback();
	}
	
	void _startScrolling(){
		//context.callMethod('playSong', [_jsNoteInfoList]);
		_enterFrameSubscription = this.onEnterFrame.listen(_onEnterFrame);
		
		_isPlaying = true;
	}
	
	void _onEnterFrame(EnterFrameEvent e){
		_passedTime += e.passedTime;
		num currentTime = _passedTime - _leadInSeconds;
		
		
		while (_nextTimeStamp != null && _nextTimeStamp.msTime / 1000 <= currentTime) {
			_lastTimeStamp = _nextTimeStamp;
			_nextTimeStamp = _lastTimeStamp.nextSampleTimeStampDO;
			_currentQNoteToSecondsRatio = (_lastTimeStamp.tempo / 60);
		}
		
		num qNoteTime = _lastTimeStamp.qNoteTime + (_currentQNoteToSecondsRatio * (currentTime - (_lastTimeStamp.msTime / 1000)));
		
		//adjust the scroll position
		_noteViewer.x = _cursorPosition - _noteViewer.firstNoteStartOffset - qNoteTime * _noteViewer.pixelsPerQNote;
		_noteViewer.x += 10; //fudge cursor positioning
		
		while (_vngIndex < _vnList.length && _vnList[_vngIndex].noteGroup.qNoteTime < qNoteTime){
			var vng = _vnList[_vngIndex];
			
			//send notification we reached this note
			var svEvent = new ScrollViewerEvent(ScrollViewerEvent.NOTE_REACHED);
			svEvent.visualNote = vng;
			dispatchEvent(svEvent);
			//_notePlayedCallback(vng.noteGroup.notes[0].cents);
			
			_vngIndex++;
		}
		
		if (_vngIndex >= _vnList.length && qNoteTime > _vnList.last.noteGroup.qNoteTime + _vnList.last.noteGroup.qNoteDuration){
			_stopPlayback();
		}
    }
	
	
	void _stopPlayback(){
		if (_isPlaying){
	        _enterFrameSubscription.cancel();
	        _isPlaying = false;
		}
	}
	
	num get viewerWidth { return _viewerWidth; }
}

class ScrollViewerEvent extends Event {

	LinearVisualNote visualNote;
	
	static const String NOTE_REACHED = "noteReached";
	
	ScrollViewerEvent(String type):super(type){
		
	}
}