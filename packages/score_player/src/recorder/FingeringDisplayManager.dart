part of score_player;

class FingeringDisplayManager {

	Sprite _container; //the container to add the recorder to (the Player object)
	num _xPos; //the x pos to place the recorder
	num _yPos; //the y pos to place the recorder
	num _scale; //the amount we have to scale by to fit the recorder
    	
	ScoreViewer _scoreViewer;
	
	//the amount of width that should be reserved for the recorder (0 if not recorder)
	num _displayWidth = 0; 
	
	Sprite _recorderBackground; //the background recorder image
	Sprite _fingeringDisplay; //the fingering for the current note
	
	bool _instrumentSupportsFingerings = false;

	bool _showFingerings = true;
	
	List<EventStreamSubscription> _listeners;
	
	static const num RECORDER_DISPLAY_WIDTH = 46;
	static const num RECORDER_DISPLAY_HEIGHT = 312;
	
	FingeringDisplayManager(this._container, ResourceManager resourceManager){
		FingeringDisplay.resourceManager = resourceManager;
	}
	
	///sets the fingering display (or removes it) for the new instrument
	///returns true if a change in the display occurred.
	bool setInstrument(InstrumentDO ido, bool showFingeringsIfAvailable){
		bool lastInstSupportedFingerings = _instrumentSupportsFingerings;
		if (ido.fingeringMode != null && showFingeringsIfAvailable){
			FingeringDisplay.fingerMode = ido.fingeringMode;
			_displayWidth = 46;
			_showRecorderBackground();
			_instrumentSupportsFingerings = true;
			_showFingerings = true;
		}
		else {
			FingeringDisplay.destroyDisplays();
			_displayWidth = 0;
			_removeRecorderBackground();
			_instrumentSupportsFingerings = false;
			_showFingerings = false;
		}
		
		return (_instrumentSupportsFingerings != lastInstSupportedFingerings);
			
		
	}
	
	void setNewScore(ScoreViewer scoreViewer){
		_removeListeners();
		_scoreViewer = scoreViewer;
		_addListeners();
	}
	
	void setPosition(num xPos, num yPos, num maxHeight, num stageWidth){
		_xPos = xPos;
		_yPos = yPos;
		_scale = math.min(maxHeight / RECORDER_DISPLAY_HEIGHT, 2.0);
		if (_scale * RECORDER_DISPLAY_WIDTH > 0.1 * stageWidth){
			_scale = (0.1 * stageWidth) / RECORDER_DISPLAY_WIDTH;
		}
		if (_recorderBackground != null && _recorderBackground.parent == _container){
			_recorderBackground.x = _xPos;
			_recorderBackground.y = _yPos;
			_recorderBackground.scaleX = _recorderBackground.scaleY = _scale;
		}
	}
	
	void _showRecorderBackground(){
		if (_recorderBackground == null){
			var bmp = new Bitmap(FingeringDisplay.resourceManager
				.getTextureAtlas("recorder").getBitmapData("background"));//TextureAssets.recorderBackground);
			_recorderBackground = new Sprite();
			_recorderBackground.addChild(bmp);
		}
		_recorderBackground.scaleX = _recorderBackground.scaleY = _scale;
		_recorderBackground.x = _xPos;
		_recorderBackground.y = _yPos;
		if (_recorderBackground.parent != _container){
			_container.addChild(_recorderBackground);
		}
	}
	
	void _removeRecorderBackground(){
		if (_recorderBackground != null && _recorderBackground.parent == _container){
			_container.removeChild(_recorderBackground);
			_recorderBackground = null;
		}
	}
	
	void _onVngClick(InputEvent e){
		_displayFingering((e.currentTarget as VisualNoteGroup));
	}
	
	void _onNoteReached(ScoreViewerEvent e){
		if (e.visualNoteGroup.noteGroup.visible){
			_displayFingering(e.visualNoteGroup);
		}
	}
	
	void _displayFingering(VisualNoteGroup vng){
		if (vng.noteGroup.isRest){
			return; //no fingerings for rests
		}
		
		//remove old fingering
		if (_fingeringDisplay != null && _fingeringDisplay.parent == _recorderBackground){
    		_recorderBackground.removeChild(_fingeringDisplay);
    	}
		
		//add new fingering
    	//_fingeringDisplay = FingeringDisplay.getFingeringDisplay(vng.noteGroup.notes[0].displayCents);
		_fingeringDisplay = FingeringDisplay.getFingeringDisplay(vng.noteGroup.visibleNotes[0].displayCents);
    	if (_fingeringDisplay != null){
    		_fingeringDisplay.x = 4;
        	_fingeringDisplay.y = 3;
        	_recorderBackground.addChild(_fingeringDisplay);
    	}
    	
	}
	
	void _addListeners(){
		if (_scoreViewer != null && _instrumentSupportsFingerings){
			var vngList = _scoreViewer.vScore.getVisualNoteGroups();
			_listeners = [];
			for (var vng in vngList){
				if (vng.noteGroup.isRest){
					continue;
				}
				vng.mouseCursor = MouseCursor.POINTER;
				_listeners.add(vng.onMouseClick.listen(_onVngClick));
				_listeners.add(vng.onTouchTap.listen(_onVngClick));
			}
			
			_scoreViewer.addEventListener(ScoreViewerEvent.NOTE_REACHED, _onNoteReached);
		}
	}
	
	void _removeListeners(){
		if (_scoreViewer != null){
			if (_listeners != null){
				var vngList = _scoreViewer.vScore.getVisualNoteGroups();
				for (var vng in vngList){
					if (vng.noteGroup.isRest){
    					continue;
    				}
    				vng.mouseCursor = MouseCursor.DEFAULT;
    			}
				for (var stream in _listeners){
					stream.cancel();
				}
				_listeners = null;
			}
			
			_scoreViewer.removeEventListener(ScoreViewerEvent.NOTE_REACHED, _onNoteReached);
		}
	}
	
	///the amount of width that should be reserved for the recorder (0 if not recorder)
	num get displayWidth => _displayWidth * _scale;
	
}