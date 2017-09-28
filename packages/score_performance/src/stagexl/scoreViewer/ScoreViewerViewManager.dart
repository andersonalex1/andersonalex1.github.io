part of score_performance.stagexl;

class ScoreViewerViewManager {
	
	ScoreViewer _scoreViewer;
	VisualScore _vScore;
	
	num _viewerWidth = 500;
	num _viewerHeight = 400;
	static const num EDGE_BUFFER = 2.0; //gap between scoreViewer edge and visualScore

	List<VisualSystem> _vSystems;
	//bool _systemsNotYetCached = false;

	Bitmap _systemPreviewBmp;
	
	bool _enabled = false;
	
	Point _startPos;
	
	bool _scrollOccurred = false; //true if a scroll action occurred for the last mouse/touch down
	static const num MIN_DISTANCE_FOR_SCROLL = 5; //the smallest scroll distance that counts as a scroll (used to distinguish clicks vs drags)
	
	bool _mouseDownReceived = false;
	
	Tween _scrollTween;
	
	Sprite _countoffDisplay;
	Tween _countoffFadeTween;
	
	///////////////////scroll wheel calculation values//////////////////
	int _lastScrollWheelTime = 0;
	//int _totalScrollTime = 0;
	//int _numScrollTimeReadings = 0;
	
	//num _totalScrollDelta = 3000; //_numScrollDeltaReadings * 60
	//int _numScrollDeltaReadings = 50;
	static int _numScrollDeltaReadings;
	////////////////////////////////////////////////////////////////////
	
	EventStreamSubscription<MouseEvent> _mouseDownListener;
	EventStreamSubscription<TouchEvent> _touchStartListener;
	EventStreamSubscription<MouseEvent> _mouseUpListener;
    EventStreamSubscription<TouchEvent> _touchEndListener;
    EventStreamSubscription<MouseEvent> _mouseWheelListener;
	
    ScoreViewerViewManager(this._scoreViewer){
		_init();
	}
    
    void setNewScore(VisualScore visualScore, [num viewerWidth = -1, num viewerHeight = -1]){
    	if (_vScore != null && _vScore.parent == _scoreViewer){
    		_scoreViewer.removeChild(_vScore);
    	}
    	
		_vScore = visualScore;
		_vSystems = _vScore.getVisualSystems();
		//_systemsNotYetCached = true;
        
        if (viewerWidth == -1) viewerWidth = _viewerWidth;
        if (viewerHeight == -1) viewerHeight = _viewerHeight;
        setWidthAndHeight(viewerWidth, viewerHeight);
        _scoreViewer.addChild(_vScore);
        
        //_vSystems = _vScore.getVisualSystems();
	}
	
	void setWidthAndHeight(num viewerWidth, num viewerHeight){
		_viewerWidth = viewerWidth;
		_viewerHeight = viewerHeight;
		
		_scoreViewer.mask = new Mask.rectangle(0, 0, _viewerWidth, _viewerHeight);
		
		if (_viewerWidth != null && _vScore != null){
			var scale = (_viewerWidth - 2 * EDGE_BUFFER) / _vScore.score.scoreProperties.pageWidth;
			_vScore.scaleX = _vScore.scaleY = scale;
			_vScore.x = EDGE_BUFFER;
			//print('scale: $scale');
			
			if (_enabled){
				_drawViewerBackground();
			}
			
			_updateVisibleSystems(0, true);
		}
	}
	
	void notifyPlaybackStateChange(bool isPlaying){
		if (isPlaying){
			disableUserScroll();
		}
		else {
			enableUserScroll();
		}
	}
	
	/**
	 * enables scroll interaction - must add to stage before calling this
	 */
	void enableUserScroll(){
		if (!_enabled){
			if (_scoreViewer.stage != null){
				_enableListeners(null);
			}
			else {
				_scoreViewer.addEventListener(Event.ADDED_TO_STAGE, _enableListeners);
			}
			_drawViewerBackground();
    		_enabled = true;
		}
	}
	
	void _enableListeners(Event e){
		_mouseDownListener = _scoreViewer.onMouseDown.listen(_onMouseDown);
		_touchStartListener = _scoreViewer.onTouchBegin.listen(_onMouseDown);
		_mouseUpListener = _scoreViewer.onMouseUp.listen(_onMouseUp);
		_touchEndListener = _scoreViewer.onTouchEnd.listen(_onMouseUp);
		_mouseWheelListener = _scoreViewer.onMouseWheel.listen(_onMouseWheel);
		
		_scoreViewer.removeEventListener(Event.ADDED_TO_STAGE, _enableListeners);
	}
	
	void disableUserScroll(){
		if (_enabled){
			if (_mouseDownListener != null)	_mouseDownListener.cancel();
			if (_touchStartListener != null) _touchStartListener.cancel();
			if (_mouseUpListener != null) _mouseUpListener.cancel();
			if (_touchEndListener != null) _touchEndListener.cancel();
			if (_mouseWheelListener != null) _mouseWheelListener.cancel();
			
			_enabled = false;
			
			_scoreViewer.removeEventListener(Event.ADDED_TO_STAGE, _enableListeners);
			
			_clearViewerBackground();
		}
	}
	
	void scrollToSystem(VisualSystem vSystem, num seconds){
		if (_scrollTween != null){
			_scrollTween.complete();
			_scrollTween = null;
		}
		
		//num targetY = -1 * vSystem.scoreY * _vScore.scaleY + 50;
		num targetY = (BitmapMusicRenderer.firstPageVerticalOffset + (-1 * vSystem.scoreY)) * _vScore.scaleY;
		if (seconds > 0 && _vScore.y > targetY){
			_updateVisibleSystems(_vScore.y - targetY);
			_scrollTween = new Tween(_vScore, seconds, Transition.easeOutQuadratic);
			_scrollTween.onComplete = () => _scrollTween = null;
			_scrollTween.animate.y.to(targetY);
			vSystem.stage.juggler.add(_scrollTween);
		}
		else {
			_vScore.y = targetY;
			_updateVisibleSystems(0); //this order is important
		}
	}
	
	void stopCurrentScrollTween(){
		if (_scrollTween != null){
			_scrollTween.complete();
			_scrollTween = null;
		}
	}
	
	bool isNoteInView(VisualNoteGroup vng){
		var vSys = vng.vSystemRef;
	
		if (vSys.parent == null){
			return false;
		}
		else {
			if (_vScore.y + (vSys.scoreY) * _vScore.scaleY > 0 && 
            		_vScore.y + ((vSys.scoreY + vSys.height) * _vScore.scaleY) < _viewerHeight){
				return true;
			}
			return false;
		}
	}
	
	void updateVisualCountoff(int countoffBeat){
		if (_countoffFadeTween != null && !_countoffFadeTween.isComplete){
			_countoffFadeTween.complete();
		}
		if (_countoffDisplay != null && _countoffDisplay.parent == _scoreViewer){
			_scoreViewer.removeChild(_countoffDisplay);
		}
		
		_countoffDisplay = new Sprite();
		String text;
		if (countoffBeat == 2){
			text = "Set";
		}
		else if (countoffBeat == 1){
			text = "Go";
		}
		else {
			text = countoffBeat.toString();
		}
		var tf = new TextField(text, new TextFormat("Arial", 80 * _viewerWidth / 600, 0x00FF00));
		tf.autoSize = TextFieldAutoSize.LEFT;
		_countoffDisplay.addChild(tf);
		_countoffDisplay.x = (_viewerWidth - tf.textWidth) / 2;
		_countoffDisplay.y = (_viewerHeight - tf.textHeight) / 2;
		_scoreViewer.addChild(_countoffDisplay);
		
		_countoffFadeTween = new Tween(_countoffDisplay, 1.5, Transition.easeOutQuadratic);
		_countoffFadeTween.onComplete = () {
			if (_countoffDisplay.parent == _scoreViewer){
				_scoreViewer.removeChild(_countoffDisplay);
			}
			_countoffFadeTween = null;
		};
		_countoffFadeTween.animate.alpha.to(0);
		_scoreViewer.stage.juggler.add(_countoffFadeTween);
	}
	
	void _drawViewerBackground(){
		_scoreViewer.graphics.clear();
		_scoreViewer.graphics.beginPath();
		_scoreViewer.graphics.rect(0, 0, _viewerWidth, _viewerHeight);
		_scoreViewer.graphics.fillColor(0x00FFFFFF);
		_scoreViewer.graphics.closePath();
	}
	
	void _clearViewerBackground(){
		_scoreViewer.graphics.clear();
	}
	
	void _init(){
		_startPos = new Point(0, 0);
		if (_numScrollDeltaReadings == null){
			_numScrollDeltaReadings = 0;
		}
	}
	
	void _onMouseDown(InputEvent e){
		_mouseDownReceived = true;
		_scrollOccurred = false;
		
		_startPos = new Point(_vScore.x, _vScore.y);
		//num vOffset = _vScore.height / _vScore.scaleY / 2;
		//num hOffset = (_vScore.mouseX);
		
		//num leftBound = math.min(0 - _vScore.width / _vScore.scaleX + _viewerWidth, 0);
		//bool lockCenter = true;
		if (e is MouseEvent){
			//vOffset = _vScore.mouseY;
			//hOffset = _vScore.mouseX;
			//lockCenter = false;
			//leftBound = math.min(0 - _vScore.width / _vScore.scaleX + _viewerWidth, 0);
		}
		
		_vScore.startDrag();
		_vScore.addEventListener(Event.ENTER_FRAME, _onEnterFrame);
	}
	
	void _onMouseUp(InputEvent e){
		if (!_mouseDownReceived){
			return;
		}
		_vScore.stopDrag();
		_vScore.removeEventListener(Event.ENTER_FRAME, _onEnterFrame);
		if ((_vScore.x - _startPos.x).abs() > MIN_DISTANCE_FOR_SCROLL ||
				(_vScore.y - _startPos.y).abs() > MIN_DISTANCE_FOR_SCROLL){
			_scrollOccurred = true;
		}
		
		
		_fixHorizontalPosition();
		_fixVerticalPosition(0.3);
        
        _mouseDownReceived = false;
        
        if (!_scrollOccurred){
        	_handleClickOnScore(e);
        }
	}
	
	static Map<num, int> _wheelDeltas = {}; //for each delta num value, its corresponding num occurrences
	num _largestWheelDeltaDist = 0;
	num _lastAppliedDelta = 0;
	void _onMouseWheel(MouseEvent e){
		num deltaDist = e.deltaY.abs();
        		
    	if (deltaDist == 0){ return; }
    	
    	int time = new DateTime.now().millisecondsSinceEpoch;
		int deltaTime = time - _lastScrollWheelTime;
		_lastScrollWheelTime = time;
    	
    	if (deltaDist > _largestWheelDeltaDist){
    		_largestWheelDeltaDist = deltaDist;
    	}
    	
    	_numScrollDeltaReadings++;
    	bool isWheelMouse = false;
    	if (_wheelDeltas.length < 40){ //wheel mice will usually have only a handful of different deltas
	    	if (_wheelDeltas[deltaDist] == null){ _wheelDeltas[deltaDist] = 1; }
	    	else { _wheelDeltas[deltaDist]++; }
	    	
	    	_wheelDeltas.forEach((delta, freq){
	    		if (freq / _numScrollDeltaReadings > 0.3){
	    			isWheelMouse = true;
	    		}
	    	});
	    		
	    	
    	}
    	
    	num calculatedDelta;
    	if (_numScrollDeltaReadings < 5){
    		//start slow until we have some idea what we're working with
    		calculatedDelta = (e.deltaY > 0)? -10 : 10;
    	}
    	else if (isWheelMouse){
    		calculatedDelta = (e.deltaY > 0)? -60 : 60;
    	}
    	else {
    		calculatedDelta = deltaDist;
//    		num logDel = (math.log(deltaDist) / math.log(1.4));
//    		num largestLogDel = (math.log(_largestWheelDeltaDist) / math.log(1.4));
//    		
//    		calculatedDelta = (logDel / largestLogDel) * 60;
//    		
    		if (e.deltaY > 0) { calculatedDelta *= -1; }
    		
			//apply a smoothing
		  	
	    	if (deltaTime > 200){
	    		_lastAppliedDelta = 0;
	    	}
//	    	else {
//	    		num timeAdjustFac = math.min(2, deltaTime / 30);
//	    		calculatedDelta *= timeAdjustFac;
//	    	}
		    calculatedDelta = (_lastAppliedDelta * 5 + calculatedDelta) / 6;
		    _lastAppliedDelta = calculatedDelta;
    	}
    	
    	_vScore.y += calculatedDelta;
    	
    	
		//run updateVisibleSystems before fixing vertical position, because fixVert requires
		//systems to be visible for its check to work
		_updateVisibleSystems(0); 
		if (!_fixVerticalPosition(0)){
			//_updateVisibleSystems(0);
		}
	}
	
	void _onEnterFrame(Event e){
		_fixHorizontalPosition();
		_updateVisibleSystems(0);
	}
	
	bool _fixVerticalPosition([num time = 0.0]){
		num targetY = _vScore.y;
        
		if (targetY + _vScore.height < _viewerHeight - 100){
			targetY = _viewerHeight - _vScore.height - 100;
		}
		if (targetY > 0){
			targetY = 0;
		}
		
		bool correctionMade = false;
		if (targetY != _vScore.y){
			if (time > 0){
				//smooth transition back
				var tween = new Tween(_vScore, 0.3, Transition.easeOutCubic);
        		tween.onComplete = () => _updateVisibleSystems(0);
                tween.animate.y.to(targetY);
                
                _scoreViewer.stage.juggler.add(tween);
			}
			else {
				//instant correct
				_vScore.y = targetY;
				_updateVisibleSystems(0);
			}
			correctionMade = true;
		}
		
		return correctionMade;
	}
	
	void _fixHorizontalPosition(){
		_vScore.x = EDGE_BUFFER;
	}

	///updates which systems are currently in view. This caches the visible systems and removes
	///the cache for systems which are out of view (as well as removing them from the stage).
	///Use cacheAlreadyVisibleSystems the first time a score is processed to make sure that 
	///previously visible systems are cached.
	void _updateVisibleSystems([num nextScrollDelta = 0, bool cacheAlreadyVisibleSystems = false]){
		//int numVisible = 0;
		//int numInvisible = 0;
		for (int i = 0; i < _vSystems.length; i++){
			var vSys = _vSystems[i];
			if (_vScore.y + (vSys.scoreY + vSys.height) * _vScore.scaleY > 0 && 
					_vScore.y + (vSys.scoreY * _vScore.scaleY) < _viewerHeight + nextScrollDelta){
				//numVisible++;
				if (vSys.parent != vSys.pageRef || cacheAlreadyVisibleSystems){
					//cache the system
					vSys.cacheSystemGraphics();
//					vSys.addEventListener(Event.ENTER_FRAME, _onEnterFrameCacheUpdate);
//					_cacheRefreshMap[vSys] = 0;

//					new Timer(new Duration(milliseconds: 100), (){
//						vSys.refreshCache();
//					});
				}
				if (vSys.parent != vSys.pageRef){
					//display it if it's not already displayed
					vSys.pageRef.addChild(vSys);
				}
			}
			else {
				//numInvisible++;
				if (vSys.parent == vSys.pageRef){
					vSys.pageRef.removeChild(vSys);
					vSys.removeCache();
				}
			}
		}
		//print('visible: $numVisible, invisible: $numInvisible');
	}

//	Map<VisualSystem, int> _cacheRefreshMap = {};
//	void _onEnterFrameCacheUpdate(Event e){
//		VisualSystem vSys = e.target as VisualSystem;
//		_cacheRefreshMap[vSys]++;
//		if (_cacheRefreshMap[vSys] >= 10) {
//			vSys.removeEventListener(
//				Event.ENTER_FRAME, _onEnterFrameCacheUpdate);
//			vSys.refreshCache();
//
//			_cacheRefreshMap.remove(vSys);
//		}
//	}
	
	void _handleClickOnScore(InputEvent e){
		var globalPoint = new Point(e.stageX, e.stageY);
    	Point p = _vScore.globalToLocal(globalPoint);
    	var visualSys = _vScore.getVisualSystemUnderPoint(p);
    	if (visualSys != null){
    		Point p2 = visualSys.globalToLocal(globalPoint);
    		var visMeas = visualSys.getVisualMeasureUnderPoint(p2);
    		if (visMeas != null){
    			var e = new ScoreViewerEvent(ScoreViewerEvent.MEASURE_CLICKED);
    			e.visualMeasure = visMeas;
    			_scoreViewer._dispatchClientEvent(e);
//    			visualSys.graphics.beginPath();
//    			visualSys.graphics.rect(visMeas.x, visMeas.y, visMeas.width, visMeas.height);
//    			visualSys.graphics.strokeColor(0xFFFF0000);
//    			visualSys.graphics.closePath();
    		}
    	}
	}
	
	void reportChildrenPositions(DisplayObjectContainer obj) {
		for (var child in obj.children){
			if (child is DisplayObjectContainer){
				reportChildrenPositions(child);
			}
		 	print('$child  ${child.width}  ${child.height}  ${child.x}  ${child.y}');
	  	}
  	}
	
	void showSystemPreview(VisualSystem sys){
		removeSystemPreview(false);
		var sysBounds = sys.bounds;
		num transY = 0 - sysBounds.top;
		//var bd = new BitmapData(_viewerWidth.toInt(), (_viewerHeight - sysBounds.height).toInt(), false);
		//var bd = new BitmapData(_viewerWidth.toInt(), _viewerHeight.toInt(), false);
		var bd = new BitmapData(_viewerWidth.toInt(), _viewerHeight.toInt());
		bd.draw(sys, new Matrix(1, 0, 0, 1, sys.x, transY));
        _systemPreviewBmp = new Bitmap(bd);
        _systemPreviewBmp.y = 200;
        _systemPreviewBmp.scaleX = _systemPreviewBmp.scaleY = _vScore.scaleY;
		_scoreViewer.addChild(_systemPreviewBmp);
		
		_systemPreviewBmp.alpha = 0;
		var tween = new Tween(_systemPreviewBmp, 0.5, Transition.easeOutCubic);
        tween.animate.alpha.to(1.0);
        
        _scoreViewer.stage.juggler.add(tween);
	}
	
	void removeSystemPreview(bool fadeIntoPosition){
		if (_systemPreviewBmp != null && _systemPreviewBmp.parent != null){
			if (fadeIntoPosition){
				var tempSys = _systemPreviewBmp;
    			var tween = new Tween(tempSys, 0.5, Transition.easeOutCubic);
                tween.animate.y.to(50);
                //tween.animate.alpha.to(0);
                tween.onComplete = () => tempSys.parent.removeChild(tempSys);
                _scoreViewer.stage.juggler.add(tween);
    		}
    		else {
    			_systemPreviewBmp.parent.removeChild(_systemPreviewBmp);
    		}
		}
		if (_systemPreviewBmp != null){
			_systemPreviewBmp = null;
		}
	}
    
    bool get scrollOccurred => _scrollOccurred;
}