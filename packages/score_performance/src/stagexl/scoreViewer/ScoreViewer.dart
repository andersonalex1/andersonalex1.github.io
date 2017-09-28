part of score_performance.stagexl;

class ScoreViewer extends Sprite {
	
	VisualScore _vScore;
	
	ScoreViewerPlaybackManager _pm;
	ScoreViewerViewManager _vm;
	
	List<VisualNoteGroup> _vngList;
	
	ScoreViewer(VisualScore visualScore, num viewerWidth, num viewerHeight){
		
		_init(visualScore, viewerWidth, viewerHeight);
	}
	
	void _init(VisualScore visualScore, num viewerWidth, num viewerHeight){
		_vm = new ScoreViewerViewManager(this);
		_pm = new ScoreViewerPlaybackManager(this, _vm);
		
		setScore(visualScore, viewerWidth, viewerHeight);
		_vm.enableUserScroll();
	}
	
	void setScore(VisualScore visualScore, [num viewerWidth = -1, num viewerHeight = -1]){
		_vScore = visualScore;
		
		//get the list of VisualNoteGroups
		_vngList = _vScore.getVisualNoteGroups();
        _vngList.sort((VisualNoteGroup vng1, VisualNoteGroup vng2) => 
        				(vng1.noteGroup.qNoteTime <= vng2.noteGroup.qNoteTime)? -1 : 1);
        
        
        _vm.setNewScore(_vScore, viewerWidth, viewerHeight);
        _pm.setNewScore(_vScore, _vngList);
	}
	
	void setWidthAndHeight(num viewerWidth, num viewerHeight){
		_vm.setWidthAndHeight(viewerWidth, viewerHeight);
	}
	
	
	void play(List<SampleTimeStampDO> timeStamps, List<num> beatList, List<num> countoffBeatList,
	          [num audioStartDelaySeconds = 0.5, NoteGroup startNG = null, num endQNoteTime = null]) {
		_pm.play(timeStamps, beatList, countoffBeatList, audioStartDelaySeconds, 
				startNG, endQNoteTime);		
	}
	
	void stop(){
		_pm.stop();
	}
	
	void startBeatTrackPlayback(int countoffBeats){
		
	}
	
	/**
	 * scrolls the score to the indicated system
	 */
	void scrollToSystem(System system, num seconds){
		for (var vSystem in _vm._vSystems){
			if (vSystem.systemRef == system){
				_vm.scrollToSystem(vSystem, seconds);
				return;
			}
		}
	}
	
	void _dispatchClientEvent(Event e){
		dispatchEvent(e);
	}
	
	VisualScore get vScore => _vScore;
	
	///returns a list of the VisualNoteGroups, sorted by qNoteTime
	List<VisualNoteGroup> get vngList => _vngList;
	
	ScoreViewerPlaybackManager get playbackManager => _pm;
	
}

class ScoreViewerEvent extends Event {
	VisualNoteGroup visualNoteGroup;
	VisualMeasure visualMeasure;
	num qNoteTime;
	///time stamp from audio context, in seconds.
	num contextTime;

	///tempo in bpm
	num tempo;
	
	static const String NOTE_REACHED = "noteReached";
	static const String BEAT_REACHED = "beatReached";
	static const String MEASURE_CLICKED = "measureClicked";
	
	ScoreViewerEvent(String type):super(type){
		
	}
}

