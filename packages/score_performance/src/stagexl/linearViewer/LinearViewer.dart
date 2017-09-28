part of score_performance.stagexl;

class LinearViewer extends Sprite {	
	Linear2Score _linearScore;
	//List<Bitmap> _bitmapFrames;
	//Sprite _bitmapsContainer; //contains Bitmap renderings of the score
	Shape _cursor;
	
	num _cursorPosition = 100;
	
	num _verticalOffset = 50;
	
	num _viewerWidth = 600;
	
	
	List<SampleTimeStampDO> _timeStamps;
	SampleTimeStampDO _lastTimeStamp;
	SampleTimeStampDO _nextTimeStamp;
	num _currentQNoteToSecondsRatio;
	
	List<Linear2VisualNoteGroup> _vngList;
	int _vngIndex = 0;
	
	num _passedTime = 0;
	num _leadInSeconds = 0;
	num _audioStartDelay = 0.5;
	
	bool _isPlaying = false;
	
	num _lastNoteVisibilityUpdateTime;
	
	EventStreamSubscription<EnterFrameEvent> _enterFrameSubscription;
	
	AudioContext _context;
	num _contextStartTime;
	bool _adjustedTime = false;
	
	TextField testTF;
	int clicks = 0;
	
	LinearViewer(Linear2Score linearScore, [num viewerWidth = 600]){
		_linearScore = linearScore;
		_viewerWidth = viewerWidth;
		
		_init();
	}
	
	void _init() {
		_cursor = new Shape();
		
		_cursor.graphics.beginPath();
		_cursor.graphics.moveTo(0, 0);
		_cursor.graphics.lineTo(0, _linearScore.height);
		_cursor.graphics.strokeColor(0x5500FF00, 20, JointStyle.ROUND, CapsStyle.SQUARE);
		_cursor.graphics.closePath();
		
		_cursor.x = _cursorPosition;
		_cursor.y = _verticalOffset - 10;
		
		this.mask = new Mask.rectangle(0, -10, _viewerWidth, _linearScore.height + _verticalOffset + 50);
		
		//_bitmapsContainer = new Sprite();
		//_buildScoreBitmaps();
		//_bitmapsContainer.x = _cursorPosition - _linearScore.firstNoteStartPos;
		//this.addChild(_bitmapsContainer);
		//_updateDisplayedBitmaps();
		_linearScore.x = _cursorPosition - _linearScore.firstNoteStartPos;
		_linearScore.y = _verticalOffset;
		this.addChild(_linearScore);
		this.addChild(_cursor);
		
		testTF = new TextField();
		this.addChild(testTF);
		
		//Multitouch.inputMode = MultitouchInputMode.NONE;
		//_linearScore.mouseEnabled = true;
		//_linearScore.mouseChildren = true;
		//_linearScore.addEventListener(TouchEvent.TOUCH_TAP, _onTap);
		//_linearScore.addEventListener(TouchEvent.TOUCH_BEGIN, _onTouchDown);
		//_linearScore.addEventListener(TouchEvent.TOUCH_END, _onTouchUp);
		//_linearScore.addEventListener(MouseEvent.CLICK, _onClick);
		//_linearScore.addEventListener(MouseEvent.MOUSE_DOWN, _onMouseDown);
		//_linearScore.addEventListener(MouseEvent.MOUSE_UP, _onMouseUp);
	}
	
//	void _onTap(TouchEvent e){
//		clicks++;
//		testTF.text = (clicks.toString());
//		print(clicks);
//	}
//	
//	void _onClick(MouseEvent e){
//		clicks++;
//        testTF.text = (clicks.toString());
//        print(clicks);
//	}
//	
//	void _onMouseDown(MouseEvent e){
//		_linearScore.startDrag();
//	}
//	
//	void _onMouseUp(MouseEvent e){
//		_linearScore.stopDrag();
//	}
//	
//	void _onTouchDown(TouchEvent e){
//    	_linearScore.startDrag();
//	}
//	
//	void _onTouchUp(TouchEvent e){
//		_linearScore.stopDrag();
//	}
	
	void play(List<SampleTimeStampDO> timeStamps, [num leadInSeconds = 0, num audioStartDelaySeconds = 0.5, 
				AudioContext context = null]) {
		if (timeStamps == null || timeStamps.length < 1){ throw "No time stamps!"; }
		
		_context = context;
		if (_context != null){
			_contextStartTime = (_context.currentTime.isNaN)? 0 : _context.currentTime;
			_adjustedTime = false;
		}
		
		_audioStartDelay = audioStartDelaySeconds;
		_timeStamps = timeStamps;
		
		_lastTimeStamp = new SampleTimeStampDO(0, 0);
		_nextTimeStamp = timeStamps[0];
		_lastTimeStamp.tempo = _nextTimeStamp.tempo;
		_currentQNoteToSecondsRatio = _lastTimeStamp.tempo / 60;
		
        _passedTime = 0;
        _leadInSeconds = leadInSeconds;
		
		//get the list of VisualNoteGroups
        _vngList = _linearScore.getVisualNoteGroups();
        _vngList.sort((Linear2VisualNoteGroup vng1, Linear2VisualNoteGroup vng2) => 
							(vng1.noteGroup.qNoteTime <= vng2.noteGroup.qNoteTime)? -1 : 1);
		_vngIndex = 0;
		
		
		
		_startScrolling();
		
	}
	
	
	
	void stop(){
		_stopPlayback();
	}
	
	void _startScrolling(){
		_lastNoteVisibilityUpdateTime = -10;
		_enterFrameSubscription = this.onEnterFrame.listen(_onEnterFrame);
		
		_isPlaying = true;
	}
	
	void _onEnterFrame(EnterFrameEvent e){
		_passedTime += e.passedTime;
		
		//use the AudioContext to correct our time once near the beginning
		if (!_adjustedTime && _passedTime > 0.5 && _context != null){
			if ((_passedTime - (_context.currentTime - _contextStartTime)).abs() > 0.05){
				print('adjusted time');
				_passedTime = _context.currentTime - _contextStartTime;
			}
			_adjustedTime = true;
		}
		num currentTime = _passedTime - _leadInSeconds - _audioStartDelay;
		
		
		while (_nextTimeStamp != null && _nextTimeStamp.msTime / 1000 <= currentTime) {
			_lastTimeStamp = _nextTimeStamp;
			_nextTimeStamp = _lastTimeStamp.nextSampleTimeStampDO;
			_currentQNoteToSecondsRatio = (_lastTimeStamp.tempo / 60);
		}
		
		num qNoteTime = _lastTimeStamp.qNoteTime + (_currentQNoteToSecondsRatio * (currentTime - (_lastTimeStamp.msTime / 1000)));
		
		//adjust the scroll position
		_linearScore.x = _cursorPosition - _linearScore.firstNoteStartPos - qNoteTime * _linearScore.pixelsPerQNote;
		_linearScore.x += 10; //fudge cursor positioning
		//_bitmapsContainer.x = _cursorPosition - _linearScore.firstNoteStartPos - qNoteTime * _linearScore.pixelsPerQNote;
		//_bitmapsContainer.x += 10; //fudge cursor positioning
		//_updateDisplayedBitmaps();
		
		while (_vngIndex < _vngList.length && _vngList[_vngIndex].noteGroup.qNoteTime < qNoteTime){
			var vng = _vngList[_vngIndex];
			
			//send notification we reached this note
			var svEvent = new LinearViewerEvent(LinearViewerEvent.NOTE_REACHED);
			svEvent.visualNoteGroup = vng;
			dispatchEvent(svEvent);
			//_notePlayedCallback(vng.noteGroup.notes[0].cents);
			
			_vngIndex++;
		}
		
		
		//hide notes that aren't visible right now
		if (_passedTime - _lastNoteVisibilityUpdateTime > 1.0){
			num aheadWindow = _viewerWidth + (1.5 * _linearScore.pixelsPerQNote * _currentQNoteToSecondsRatio);
			for (int i = 0; i < _vngList.length; i++){
    			var vng = _vngList[i];
    			if (vng.x + _linearScore.x < 0 || vng.x + _linearScore.x > aheadWindow){
    				vng.visible = false;
    			}
    			else {
    				vng.visible = true;
    			}
    		}
			_lastNoteVisibilityUpdateTime = _passedTime;
        }
		
		
		if (_vngIndex >= _vngList.length && qNoteTime > _vngList.last.noteGroup.qNoteTime + _vngList.last.noteGroup.qNoteDuration){
			_stopPlayback();
		}
    }
	
	
	void _stopPlayback(){
		if (_isPlaying){
	        _enterFrameSubscription.cancel();
	        _isPlaying = false;
		}
	}
	
//	void _buildScoreBitmaps(){
//		_bitmapFrames = [];
//		int hPos = 0;
//		int frameWidth = 1000;
//		int frameHeight = _linearScore.height.toInt() + _verticalOffset + 1;
//		var sourceBD = new BitmapData(_linearScore.width.toInt() + 1, frameHeight, false, 0xFFFFFFFF);
//		sourceBD.draw(_linearScore, new Matrix(1, 0, 0, 1, 0, _verticalOffset));
//		while (hPos < _linearScore.width){
//			int actualFrameWidth = (_linearScore.width - hPos > frameWidth)? frameWidth : (_linearScore.width - hPos).toInt() + 1;
//			var bd = new BitmapData.fromBitmapData(sourceBD, new Rectangle(hPos, 0, actualFrameWidth, frameHeight + 50));
//			var bitmap = new Bitmap(bd);
//			bitmap.x = hPos;
//			_bitmapFrames.add(bitmap);
//			hPos += frameWidth;
//		}
//		
//	}
	
//	void _updateDisplayedBitmaps(){
//		int numDisplayedBitmaps = 0;
//		for (var bmp in _bitmapFrames){
//			if (bmp.x + bmp.width + _bitmapsContainer.x > 0 && bmp.x + _bitmapsContainer.x < _viewerWidth + 100){
//				//should be showing
//				if (bmp.parent != _bitmapsContainer){
//					_bitmapsContainer.addChild(bmp);
//				}
//				numDisplayedBitmaps++;
//				if (numDisplayedBitmaps == 2){
//					break;
//				}
//			}
//			else {
//				//shouldn't be showing
//				if (bmp.parent == _bitmapsContainer){
//					_bitmapsContainer.removeChild(bmp);
//				}
//			}
//		}
//	}
	
	num get viewerWidth { return _viewerWidth; }
	void set viewerWidth (num value) { 
		_viewerWidth = value;
		this.mask = new Mask.rectangle(0, -10, _viewerWidth, _linearScore.height + _verticalOffset + 50);
	}
	
	
	Linear2Score get score { return _linearScore; }
}

class LinearViewerEvent extends Event {
	
	Linear2VisualNoteGroup visualNoteGroup;
	
	static const String NOTE_REACHED = "noteReached";
	
	LinearViewerEvent(String type):super(type){
		
	}
}