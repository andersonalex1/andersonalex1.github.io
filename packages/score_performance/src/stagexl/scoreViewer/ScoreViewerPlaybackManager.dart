part of score_performance.stagexl;

class ScoreViewerPlaybackManager {
	ScoreViewer _scoreViewer;
	ScoreViewerViewManager _vm;
	VisualScore _vScore;
	List<VisualNoteGroup> _vngList;
	
	//the last cursor viable VNG we passed (invisible notes aren't included unless
	//they are the first note in the measure)
	VisualNoteGroup _lastReachedVNG; 
	
	Shape _cursor;
	
	int _vngIndex = 0;
    VisualSystem _lastSystem; //the last system reached
    
    VisualNoteGroup _lastVNGInRegion; //the last VNG in the playback region
    bool _useScrolling;
    
    List<num> _beatList; //a list of qNote positions of the beats
    int _beatIndex;
    List<num> _countoffBeatList; //a list of qNote positions of the beats
    int _countoffBeatIndex;
    bool _firstNoteReached; //set to true when the first note/beat in the playback is reached 
    
    List<SampleTimeStampDO> _timeStamps;
	SampleTimeStampDO _lastTimeStamp;
	SampleTimeStampDO _nextTimeStamp;
	num _currentQNoteToSecondsRatio;
	
	num _passedTime = 0;
   	num _audioStartDelay = 0.5;
   	
   	num _qNoteTime = 0;
	
	bool _isPlaying = false;
	
	EventStreamSubscription<EnterFrameEvent> _enterFrameSubscription;
    	
	num _contextStartTime;
	
	ScoreViewerPlaybackManager(this._scoreViewer, this._vm){
		
	}
	
	void setNewScore(VisualScore vScore, List<VisualNoteGroup> vngList){
		_vScore = vScore;
		_vngList = vngList;
		_drawCursor();
		
		if (_isPlaying){
			_vScore.addChild(_cursor);
		}
	}
	
	void _drawCursor(){
		//create the cursor
		_cursor = new Shape();
		_cursor.graphics.beginPath();
		_cursor.graphics.moveTo(0, 0);
		//_cursor.graphics.lineTo(0, _vScore.visualPages[0].visualSystems[0].height);
		_cursor.graphics.lineTo(0, _vScore.scoreProps.staffLineSpacing * 6);
		_cursor.graphics.strokeColor(0x5500FF00, 20, JointStyle.ROUND, CapsStyle.SQUARE);
		_cursor.graphics.closePath();
		_cursor.y = -1 * _vScore.scoreProps.staffLineSpacing;
	}
	
	void play(List<SampleTimeStampDO> timeStamps, List<num> beatList,
			List<num> countoffBeatList, [num audioStartDelaySeconds = 0.5,
	        NoteGroup startNG = null, num endQNoteTime = null]) {
		
		if (_vScore == null){ throw "must call setNewScore before using!"; }
		
		if (timeStamps == null || timeStamps.length < 1){ throw "No time stamps!"; }
		
		_vm.notifyPlaybackStateChange(true);
		
		_prepareTracking(timeStamps, beatList, countoffBeatList,
			audioStartDelaySeconds, startNG, endQNoteTime);
		
		//prepare scroll behavior
		_prepareScrolling();
		
		//start tracking/scrolling
		_enterFrameSubscription = _scoreViewer.onEnterFrame.listen(_onEnterFrame);
        		
        _isPlaying = true;
	}
	
	void stop(){
		_stopPlayback();
	}
	
	void _prepareTracking(List<SampleTimeStampDO> timeStamps,
		List<num> beatList,	List<num> countoffBeatList,
		num audioStartDelaySeconds,	NoteGroup startNG, num endQNoteTime){
		
		var context = AudioManager.context;
		if (context != null){
			_contextStartTime = (context.currentTime.isNaN)? 0 : context.currentTime;
		}
		
		_timeStamps = timeStamps;
		_lastTimeStamp = _timeStamps[0]; //replaced 3 commented lines with these
		_nextTimeStamp = _timeStamps[1];
		
		_currentQNoteToSecondsRatio = _lastTimeStamp.tempo / 60;
		
		_audioStartDelay = audioStartDelaySeconds;
		_passedTime = 0;
		
		_beatList = _sortAndRemoveDuplicates(beatList.sublist(0));
		_countoffBeatList = countoffBeatList;
		
		_beatIndex = 0;
		_countoffBeatIndex = 0;
		_firstNoteReached = false;
		
		_vngIndex = _initializeCursorAndView(startNG);
		_lastReachedVNG = null;
		
		//find the last VNG in the playback region
		if (endQNoteTime == null){
			_lastVNGInRegion = _vngList.last;
		}
		else {
			for (int i = _vngList.length - 1; i >= 0; i--){
				if (_vngList[i].noteGroup.qNoteTime < endQNoteTime){
					_lastVNGInRegion = _vngList[i];
					break;
				}
			}
		}
	}
	
	void _prepareScrolling(){
		//we'll only use scrolling if the last note isn't in view from the start. This
		//should create a more consistent experience than stopping scrolling once the last note
		//comes into view. Either scrolling will happen during a play session or it won't.
		_useScrolling = !_vm.isNoteInView(_lastVNGInRegion);
		if (!_useScrolling){
			//if a repeat figure takes us backwards, we have
			//to have scrolling.
			var ts = _timeStamps[0];
			while (ts.nextSampleTimeStampDO != null){
				if (ts.nextSampleTimeStampDO.qNoteTime < ts.qNoteEndTime){
					_useScrolling = true;
					break;
				}
				ts = ts.nextSampleTimeStampDO;
			}
		}
	}
	
	int _initializeCursorAndView(NoteGroup startNG){
		int i;
		VisualNoteGroup vng;
		if (startNG == null){ 
			vng = _vngList.first;
			i = 0;
		}
		else {
    		for (i = 0; i < _vngList.length; i++){
    			if (_vngList[i].noteGroup == startNG){
    				vng = _vngList[i];
    				break;
    			}
    		}
		}
		if (vng == null) { 
			//should never enter this - it would mean the NG passed in isn't in the vngList
			vng = _vngList.first;
			i = 0;
		}
		
		_lastSystem = vng.vSystemRef;
		_vScore.addChild(_cursor);
		//_lastSystem.addChild(_cursor);
		_vm.scrollToSystem(_lastSystem, 0);
		_moveCursorToNotePosition(vng);
		
		return i; //return the start vngIndex
	}
	
	void _onEnterFrame(EnterFrameEvent e){
		_passedTime += e.passedTime;
		
		num currentTime = _getCurrentTime(); //currentTime in seconds
		_qNoteTime = _getQNoteTime(currentTime); //current qNote position

		//adjust the cursor and scroll position
		_updateCursorAndScrollPos();
		
		_updateCountoffDisplay();
		
		_displayRepeatPreview(currentTime);
		
		if (_vngIndex >= _vngList.length && _qNoteTime > _vngList.last.noteGroup.qNoteTime +
					_vngList.last.noteGroup.qNoteDuration){
			_stopPlayback();
		}
    }
	
	num _getCurrentTime(){
		num currentTime;
		var context = AudioManager.context;
		if (context != null){
			currentTime = context.currentTime - _contextStartTime - _audioStartDelay;
		}
		else {
			currentTime = _passedTime - _audioStartDelay;
		}
		return currentTime; //in seconds
	}
	
	num _getQNoteTime(num currentTime){
		while (_nextTimeStamp != null && _nextTimeStamp.msTime / 1000 <= currentTime) {
			num qNoteTime = _lastTimeStamp.qNoteTime + (_currentQNoteToSecondsRatio *
							(currentTime - (_lastTimeStamp.msTime / 1000)));
			if (_nextTimeStamp.qNoteTime < qNoteTime){
				//print(_nextTimeStamp.qNoteTime.toString() + "  " + qNoteTime.toString());
				//update the _vngIndex if necessary. If we jumped backwards,
				//we need to backup the _vngIndex
				_vngIndex = 0;
				num newStampQNoteTime = _nextTimeStamp.qNoteTime;
				while(_vngIndex < _vngList.length &&
						_vngList[_vngIndex].noteGroup.qNoteTime < newStampQNoteTime){
					_vngIndex++;
				}
				_beatIndex = 0;
				while (_beatIndex < _beatList.length && _beatList[_beatIndex] < newStampQNoteTime){
					_beatIndex++;
				}
//				print('$_vngIndex   $_beatIndex');
				_vm.removeSystemPreview(true);
			}
			_lastTimeStamp = _nextTimeStamp;
			_nextTimeStamp = _lastTimeStamp.nextSampleTimeStampDO;
			_currentQNoteToSecondsRatio = (_lastTimeStamp.tempo / 60);
			
			
			
		}
		
		num qNoteTime = _lastTimeStamp.qNoteTime + (_currentQNoteToSecondsRatio *
							(currentTime - (_lastTimeStamp.msTime / 1000)));
		return qNoteTime;
	}
	
	void _updateCursorAndScrollPos(){
		if (!_firstNoteReached){
			if (_qNoteTime < _beatList[0]){
				//don't attach the cursor to notes before playback begins
				return;
			}
			_firstNoteReached = true;
		}
		
		//get the most recently passed VNG
		VisualNoteGroup mostRecentVNG;
		while (_vngIndex < _vngList.length &&
				_vngList[_vngIndex].noteGroup.qNoteTime <= _qNoteTime){
			var vng = _vngList[_vngIndex];
			bool skipNote = false;
			if (!vng.noteGroup.visible && vng.noteGroup.qNoteTime >
					vng.noteGroup.voice.measure.stack.startTime){
				//we skip notes that are invisible as long as they aren't the
				// first note of a measure
				skipNote = true;
			}
			
			if (!skipNote){
				mostRecentVNG = vng;
				_lastReachedVNG = vng;
				
				//check if we've moved to a new system, and if so, scroll and
				// move cursor
				var vSystem = mostRecentVNG.vSystemRef;
				if (vSystem != _lastSystem){
					//vSystem.addChild(_cursor);
					if (_useScrolling){
						_vm.scrollToSystem(vSystem, 0.5);
					}
					_lastSystem = vSystem;
				}
			}
			
			//send notification we reached this note
			var svEvent = new ScoreViewerEvent(ScoreViewerEvent.NOTE_REACHED);
			svEvent.visualNoteGroup = vng;
			svEvent.qNoteTime = vng.noteGroup.qNoteTime;
			svEvent.contextTime = AudioManager.context.currentTime;
			svEvent.tempo = _lastTimeStamp.tempo;
			_scoreViewer._dispatchClientEvent(svEvent);
			
			_vngIndex++;
			
		}
		
		//get the most recently passed beat
		num mostRecentBeat = null;
		while (_beatIndex < _beatList.length && _beatList[_beatIndex] <= _qNoteTime){
			mostRecentBeat = _beatList[_beatIndex];
			
			//send notification we reached this beat
			var svEvent = new ScoreViewerEvent(ScoreViewerEvent.BEAT_REACHED);
			svEvent.qNoteTime = mostRecentBeat;
			svEvent.contextTime = AudioManager.context.currentTime;
			svEvent.tempo = _lastTimeStamp.tempo;
			_scoreViewer._dispatchClientEvent(svEvent);
			
			_beatIndex++;
		}
		
		//now move the cursor to most recent note or beat.		
		if (mostRecentVNG != null && 
				(mostRecentBeat == null || mostRecentVNG.noteGroup.qNoteTime >= mostRecentBeat) && 
				!_isMeasureWholeRest(mostRecentVNG.noteGroup)){
			
			//move to most recent note
			_moveCursorToNotePosition(mostRecentVNG);
			//print('note: ${mostRecentVNG.noteGroup.qNoteDuration}  ${mostRecentVNG.noteGroup.qNoteTime}');
		}
		else if (mostRecentBeat != null){
			//move cursor to beat position
			//NoteGroup prevNG = (_vngIndex > 0)? _vngList[_vngIndex - 1].noteGroup : null;
			NoteGroup prevNG = (_lastReachedVNG != null)? _lastReachedVNG.noteGroup : null;
			if (prevNG == null){ //null should be impossible, because notes get priority over beats
				return;
			}
			
			//find the next visible note
			NoteGroup nextNG = prevNG.next;
			if (nextNG != null && nextNG.visible == false){
				nextNG = null;
			}
//			while (nextNG != null && nextNG.voice.measure == prevNG.voice.measure && nextNG.visible == false){
//				nextNG = nextNG.next;
//			}
//			if (nextNG != null && !nextNG.visible){
//				nextNG = null;
//			}
			//if (prevNG != null)? prevNG.next : null;
			
			num startHPos;
			num distance;
			num endQNoteTime;
			//num prevNoteXPos = _vngList[_vngIndex - 1].x;
			num prevNoteXPos = _lastReachedVNG.x;
			
			//num sysPageOffset = (_lastSystem.x + _lastSystem.pageRef.x) * _vScore.scaleX;
			num sysPageOffset = 0;
			if (nextNG != null && nextNG.voice.measure == prevNG.voice.measure) {
				//next note is in the same measure - cursor is placed between the notes
				startHPos = sysPageOffset + prevNoteXPos - 5;
				distance = nextNG.hPos - prevNG.hPos;
				endQNoteTime = nextNG.qNoteTime;
				//print('nextNGBeat: ${prevNG.qNoteDuration}  ${prevNG.qNoteTime}  ${nextNG.qNoteDuration}  ${nextNG.qNoteTime}');
			}
			else if (_isMeasureWholeRest(prevNG)) {
								
				//for whole rests, we track from the beginning of the measure
				var stack = prevNG.voice.measure.stack;
				distance = (stack.newSystem)? stack.width - stack.indentAsSystemLeader : stack.width - stack.indent;
				startHPos = sysPageOffset + prevNoteXPos - prevNG.hPos;
				startHPos += (stack.newSystem)? stack.indentAsSystemLeader : stack.indent;
				endQNoteTime = stack.endTime;
				
			}
			else {
				//next note is in the next measure - cursor is placed between prevNG and end of current measure
				var stack = prevNG.voice.measure.stack;
				startHPos = sysPageOffset + prevNoteXPos - 5;
				distance = stack.width - prevNG.hPos;
				endQNoteTime = stack.endTime;
				//print('nextMeasBeat: ${prevNG.qNoteDuration}  ${prevNG.qNoteTime}  $endQNoteTime');
			}
			
			//_cursor.x = startHPos + (distance * ((qNoteTime - prevNG.qNoteTime) / (endQNoteTime - prevNG.qNoteTime)));
			_cursor.x = _lastSystem.x + startHPos + 
						(distance * ((_qNoteTime - prevNG.qNoteTime) / (endQNoteTime - prevNG.qNoteTime)));
			_cursor.y = _lastSystem.scoreY - 1 * _vScore.scoreProps.staffLineSpacing;
			//_cursor.parent.refreshCache();
		}
	}
	
	void _updateCountoffDisplay(){
		if (_countoffBeatIndex < _countoffBeatList.length && 
				_qNoteTime >= _countoffBeatList[_countoffBeatIndex]){
			_vm.updateVisualCountoff(_countoffBeatList.length - _countoffBeatIndex);
			_countoffBeatIndex++;
		}
	}
	
	void _moveCursorToNotePosition(VisualNoteGroup vng){
		//_cursor.x = vng.x + 0.5 * _vScore.scoreProps.noteheadWidth;
		_cursor.x = vng.vSystemRef.x + vng.x + 0.5 * _vScore.scoreProps.noteheadWidth;
		_cursor.y = vng.vSystemRef.scoreY - 1 * _vScore.scoreProps.staffLineSpacing;
		//_cursor.parent.refreshCache();
	}
	
	void _displayRepeatPreview(num currentTime){
		//if the next timeStamp indicates a return to a previous system, we display a preview
		//print('${_lastSystem.visNoteGroups.last.noteGroup.qNoteTime}  ${_lastTimeStamp.qNoteEndTime}');
		if (_nextTimeStamp != null && _nextTimeStamp.qNoteTime < _qNoteTime && _useScrolling &&
				_vm._systemPreviewBmp == null && currentTime + 3.0 >= _nextTimeStamp.msTime / 1000 && 
				_lastSystem.visNoteGroups[0].noteGroup.qNoteTime > _nextTimeStamp.qNoteTime &&
				_lastSystem.visNoteGroups.last.noteGroup.qNoteTime + 
				_lastSystem.visNoteGroups.last.noteGroup.qNoteDuration >= _lastTimeStamp.qNoteEndTime){
			
			
			//find the system we will be jumping back to
			for (int i = 0; i < _vngList.length; i++){
				if (_vngList[i].noteGroup.qNoteTime >= _nextTimeStamp.qNoteTime){
					var vsys = _vngList[i].vSystemRef;
					_vm.showSystemPreview(vsys);
					break;
				}
			}
		}
	}
	
	void _stopPlayback(){
		if (_isPlaying){
	        _enterFrameSubscription.cancel();
	        _isPlaying = false;
	        _vm.notifyPlaybackStateChange(false);
	        //_vm.stopCurrentScrollTween(); //this can make things feel jerky, though it works fine
	        //var vSys = _cursor.parent;
	        _cursor.parent.removeChild(_cursor);
	        //vSys.refreshCache();
		}
	}
	
	bool _isMeasureWholeRest(NoteGroup ng){
		return ng.isRest && 
			ng.durationType == DurationType.WHOLE &&
			ng.voice.noteGroups.length == 1;
	}
	
	List<num> _sortAndRemoveDuplicates(List<num> list){
		list.sort((num num1, num num2){
			return (num1 <= num2)? -1 : 1;
		});
		List<num> newList = [];
		num lastNum;
		for (int i = 0; i < list.length; i++){
			num newNum = list[i];
			if (newNum != lastNum){
				newList.add(newNum);
			}
			lastNum = newNum;
		}
		return newList;
	}
	
	num get qNoteTime => _qNoteTime;
	
	num get tempo => _lastTimeStamp?.tempo;
}

enum TimeTrackMode {
	AUDIO_CONTEXT,
	BEAT_HITS
}