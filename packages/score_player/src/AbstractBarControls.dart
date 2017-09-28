part of score_player;

class AbstractBarControls extends Sprite {
	AbstractPlayer pm;

	ScoreViewer _scoreViewer;
	VisualScore _vScore;

	VisualMeasure _currentVMeasure;
	//VisualSystem _currentVSystem;

	Sprite buttonContainer;

	AbstractBarControls(AbstractPlayer playerManager){
		pm = playerManager;
		init();
	}

	void init(){
		draw();

		pm.addEventListener(PlayerEvent.PLAYER_INIT, onPlayerInit);
		pm.addEventListener(PlayerEvent.SONG_RENDERED, onSongRendered);
		pm.addEventListener(PlayerEvent.PLAYBACK_STARTED, onPlaybackStarted);
		pm.addEventListener(PlayerEvent.PLAYBACK_FINISHED, onPlaybackFinished);
		pm.addEventListener(PlayerEvent.SONG_CLOSING, onSongClosing);
	}

	void draw(){
		//create the cursor
		var cursor = new Shape();
		cursor.graphics.beginPath();
		cursor.graphics.moveTo(12, 57);
		cursor.graphics.lineTo(2, 67);
		cursor.graphics.lineTo(2, 110);
		cursor.graphics.lineTo(12,  120);
		cursor.graphics.strokeColor(0xFF86D87D, 5, JointStyle.ROUND, CapsStyle.ROUND);
		cursor.graphics.closePath();
		this.addChild(cursor);

		//create the container for the buttons
		buttonContainer = new Sprite();
		this.addChild(buttonContainer);
	}


	void onPlayerInit(PlayerEvent e){
	}

	void onSongRendered(PlayerEvent e){
		_scoreViewer = e.scoreViewer;
		_vScore = _scoreViewer.vScore;
		_setCurrentVMeasure(_vScore.visualPages[0].visualSystems[0].visualMeasures[0],
			_vScore.visualPages[0].visualSystems[0]);

		toggleEnabled(true);
	}

	void onPlaybackStarted(PlayerEvent e){
		toggleEnabled(false);
	}

	void onPlaybackFinished(PlayerEvent e){
		toggleEnabled(true);
	}

	void onSongClosing(PlayerEvent e){
		toggleEnabled(false);
	}

	void toggleEnabled(bool enabled){
		_vScore.mouseChildren = enabled;
		_vScore.mouseEnabled = enabled;

		_scoreViewer.removeEventListener(ScoreViewerEvent.MEASURE_CLICKED,
			_onMeasureClicked);
		if (enabled) {
			_scoreViewer.addEventListener(ScoreViewerEvent.MEASURE_CLICKED,
				_onMeasureClicked);
		}
	}

	void _onMeasureClicked(ScoreViewerEvent e) {
		_setCurrentVMeasure(e.visualMeasure, e.visualMeasure.vSystemRef);
	}

	void _setCurrentVMeasure(VisualMeasure vMeasure, VisualSystem vSystem) {
		if (vMeasure != null) {
			if (parent != null) {
				parent.removeChild(this);
			}

			buttonContainer.x = 0;

			x = vSystem.x + vMeasure.x;
			if (x + width > vSystem.width + vSystem.x){
				buttonContainer.x = vSystem.width + vSystem.x -	(x + width);
			}

			y = vSystem.scoreY + vMeasure.y - 68;
			_vScore.addChild(this);
			_currentVMeasure = vMeasure;
			//_currentVSystem = vSystem;
		}
	}

	NoteGroup getStartNote() {
		if (_currentVMeasure != null) {
			return (_currentVMeasure.measureRef.voices[0].noteGroups[0]);
		}
		return null;
	}

	///gets the last NoteGroup in the last measure that should be in the
	///playback region. If numMeasuresToPlay is 1, the last note will be in the
	///same bar as the start note.
	NoteGroup getEndNote(int numMeasuresToPlay) {
		if (_currentVMeasure != null) {
			var endMeasure = _currentVMeasure.measureRef;
			if (numMeasuresToPlay < 1) {
				numMeasuresToPlay = 1;
			}
			int measureIndex = 1;
			while (measureIndex < numMeasuresToPlay && endMeasure.next != null){
				endMeasure = endMeasure.next;
				measureIndex++;
			}
			var lastNG = endMeasure.voices[0].noteGroups[endMeasure.voices[0]
				.noteGroups.length - 1];
			return lastNG;
		}
		return null;
	}
}