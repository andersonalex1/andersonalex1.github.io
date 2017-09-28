part of score_performance.stagexl;

class RhythmAssessor extends Assessor {
	KeyHitRecognizer _hitRecognizer;
	
	SFPlayer _sfPlayer;
	
	int _noteIndex; //the index of the next note to be matched
	
	SFLoader _sfLoader; //creates notes for playback
	
	StreamSubscription<HitEvent> _hitSubscription;
	
	bool _firstNotePlayed;
	List<ScoreViewerEvent> _notesReachedQue; //list of notes reached in playback
	List<ScoreViewerEvent> _beatsReachedQue; //list of beats reached in playback
	
	List<HitEvent> _rhythmHits; //list of rhythm hit events
	List<HitEvent> _beatHits; //list of beat hit events
	
	num _defaultWindowSize = 0.25;
	static const num DEFAULT_TEMPO = 90;
	
	RhythmAssessor(ScoreViewer scoreViewer, SFPlayer sfPlayer,
			SFLoader sfLoader):super(scoreViewer){
		
		_sfPlayer = sfPlayer;
		_sfLoader = sfLoader;
		
	}
	
	///starts assessment
	void start(){
		_hitSubscription = _hitRecognizer.onHit.listen(_onHit);
		_scoreViewer.addEventListener(ScoreViewerEvent.NOTE_REACHED, _onNoteReached);
		_scoreViewer.addEventListener(ScoreViewerEvent.BEAT_REACHED, _onBeatReached);
		
		_rhythmHits = [];
		_beatHits = [];
		
		_notesReachedQue = [];
		_beatsReachedQue = [];
		_firstNotePlayed = false;
		
		_noteIndex = 0;
		
		_hitRecognizer.startHitRec();
	}
	
	///stops assessment
	void stop(){
		if (_hitSubscription != null){
			_hitRecognizer.stopHitRec();
			
			_hitSubscription.cancel();
			_hitSubscription = null;
			_scoreViewer.removeEventListener(ScoreViewerEvent.NOTE_REACHED, _onNoteReached);
			_scoreViewer.removeEventListener(ScoreViewerEvent.BEAT_REACHED, _onBeatReached);
		}
	}
	
	void _init(){
		super._init();
		_hitRecognizer = KeyHitRecognizer.getInstance(AudioManager.context);
		_hitRecognizer.sendBeatEvents = true;
	}
	
	
	
	void _onHit(HitEvent e){
		//change the time to the current qNoteTime
		e.time = _scoreViewer.playbackManager.qNoteTime;
		(e.hitType == HitType.RHYTHM_HIT)? _handleRhythmHit(e) : _handleBeatHit(e);
	}
	
	
	
	void _onNoteReached(ScoreViewerEvent e){
		//the playback has passed another VisualNoteGroup - store the event
		if (!_firstNotePlayed) _firstNotePlayed = true;
		_notesReachedQue.add(e);
	}
	
	void _onBeatReached(ScoreViewerEvent e){
		if (_firstNotePlayed){
			_beatsReachedQue.add(e);
		}
	}
	
	void _handleRhythmHit(HitEvent e){
		_rhythmHits.add(e);
		
		var note = _findNoteMatchForHit(e);
		if (note != null){
			_markNoteCorrect(note);
			_playNote(note.vng.noteGroup.notes[0]);
		}
		else {
			note = _findClosestNoteForHit(e);
			_playNote(note.vng.noteGroup.notes[0]);
			
			_addExtraNote(e.time);
		}
	}
	
	void _handleBeatHit(HitEvent e){
		_beatHits.add(e);
	}
	
	AssessmentNote _findNoteMatchForHit(HitEvent e){
		var tempo = _scoreViewer.playbackManager.tempo;
		num windowSize = _defaultWindowSize * (tempo / DEFAULT_TEMPO);
		
		for (int i = _noteIndex; i < _noteList.length; i++) {
			var cng = _noteList[i].vng.noteGroup;
			
			//don't assess rests or notes that continue or complete ties
			if (cng.isRest || cng.notes[0].tieState == TieState.CONTINUE ||
						cng.notes[0].tieState == TieState.STOP) {
				continue;
			}
			num noteTime = cng.qNoteTime;
			if (e.time > noteTime - windowSize && e.time < noteTime + windowSize){
				//note matched within window
				_noteIndex = i + 1;
				//print('matched note: ${_noteList[i].vng.noteGroup.qNoteTime}');
				return _noteList[i];
			}
			else if (e.time <= cng.qNoteTime - windowSize){
				//the current note is already passed - no need to check more
				break;
			}
		}
		return null;
	}
	
	AssessmentNote _findClosestNoteForHit(HitEvent e){
		int i = (_noteIndex < _noteList.length)? _noteIndex
												: _noteList.length - 1;
		var closestNote = _noteList[i];
		num closestDistance = (closestNote.vng.noteGroup.qNoteTime - e.time).abs();
		int increment = (closestNote.vng.noteGroup.qNoteTime > e.time)? -1 : 1;
		for (i; i >= 0 && i < _noteList.length; i += increment){
			num distance = (_noteList[i].vng.noteGroup.qNoteTime - e.time).abs();
			if (distance <= closestDistance){
				closestDistance = distance;
				closestNote = _noteList[i];
			}
			else {
				break;
			}
		}
		return closestNote;
	}
	
	void _playNote(Note note){
		var part = note.noteGroup.voice.measure.staff.partRef;
		int pitch = (note.displayCents ~/ 100) - part.chromaticTransposition;
		int startTime = (AudioManager.context.currentTime *
			_sfPlayer.SAMPLE_RATE).round();
		int duration = (0.5 * _sfPlayer.SAMPLE_RATE).round();
		var preset = _sfLoader.getPreset(0, 0);
		var pNote = PerformanceNoteDO.createPerformanceNote(pitch, startTime,
			duration, 0.5, 0.5, preset);
		
		_sfPlayer.playNote(pNote);
	}
	
	
}