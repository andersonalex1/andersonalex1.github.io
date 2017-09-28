part of score_performance.stagexl;

class PitchAssessor extends Assessor {
	PitchRecognizer _pitchRecognizer;
	NoteSplitter _noteSplitter;

	AssessmentInstrumentDO _inst;

	//stores all of the PitchRecEvent objects as they are received
	List<PitchRecEvent> _prEvents;
	List<int> _pitchHistory;
	//in order to not re-check PREvents that have already been passed by our
	//time window, we keep track of the earliest index we need to check
	int _prEventWindowStartIndex;

	num _maxAmplitudeEncountered;

	//holds the notation notes that have passed. On each ENTER_FRAME, the notes
	//are checked to see if enough time has passed to warrant checking the
	//assessment data against them
	List<ScoreViewerEvent> _notationNotesQue;
	int _lastNotationPitch;

	//number of milliseconds to wait before checking assessment for a note
	num _assess_Delay = 0.8;

	//contains 1's for correctly played notes, 0's for incorrect notes.
	//Order matches performance order.
	List<int> _hitMissHistory;


	StreamSubscription<PitchRecEvent> _pitchRecSubscription;
	EventStreamSubscription<EnterFrameEvent> _enterFrameSubscription;

	String _debugPRecString = "";
	String _debugNotesString = "";

	List<ScoreViewerEvent> _debugNREvents;
	List<PitchRecEvent> _debugPREvents;
	String _debugMatchedNotes;
	bool _debug = false;

	PitchAssessor(ScoreViewer scoreViewer):super(scoreViewer){

	}

	@override
	void _init(){
		super._init();
		_pitchRecognizer = new PitchRecognizer(MicManager.getInstance());
		_noteSplitter = new NoteSplitter();
	}

	bool setInstrument(InstrumentDO inst){
		_inst = AssessmentInstrumentUtils.getInstrumentByID(inst.id);
		if (_inst == null)
			throw "InstrumentDO.id doesn't match an assessment inst";

		_pitchRecognizer.setInstrument(_inst);
		_noteSplitter.setInstrument(_inst);

		return true;
	}

	///starts assessment
	@override
	void start(){
		////////////////RESET VARIABLES//////////////////
		if (_debug) {
			_debugNREvents = [];
			_debugPREvents = [];
			_debugMatchedNotes = "";
		}

		_hitMissHistory = [];

		_prEvents = [];
		_pitchHistory = [];
		_prEventWindowStartIndex = 0;
		_lastNotationPitch = 0;
		_maxAmplitudeEncountered = 0;

		_noteSplitter.reset();

		_notationNotesQue = [];
		////////////////////////////////////////////////

		_scoreViewer.addEventListener(ScoreViewerEvent.NOTE_REACHED,
			_onNoteReached);

		//use ENTER_FRAME events to check performed notation notes.
		_enterFrameSubscription =
			_scoreViewer.onEnterFrame.listen(_onEnterFrame);

		//prepare pitch rec handling
		_pitchRecognizer.setInstrument(_inst);
		_pitchRecSubscription =
			_pitchRecognizer.onPitchRecEvent.listen(_onPitchRec);

		_pitchRecognizer.startPRec(true);

		//DEBUG
		_debugNotesString = "tuning window: ${_inst.tuningWindow}\n";
		_debugPRecString = "";
	}

	///stops assessment
	@override
	void stop(){
		if (_pitchRecSubscription != null){
			_pitchRecognizer.stopPRec(true);

			_enterFrameSubscription.cancel();
			_enterFrameSubscription = null;

			_pitchRecSubscription.cancel();
			_pitchRecSubscription = null;

			_scoreViewer.removeEventListener(ScoreViewerEvent.NOTE_REACHED,
				_onNoteReached);
		}
	}

	void _onNoteReached(ScoreViewerEvent e){
		_notationNotesQue.add(e);
		if (_debug) _debugNREvents.add(e);
	}

	void _onPitchRec(PitchRecEvent e){
		//for each pitch rec event, store it in the list
		_prEvents.add(e);
		_pitchHistory.add(e.cents);
		if (_inst.checkNoteStartTimes) {
			_noteSplitter.addEvent(e);
		}
		if (_debug) {
			_debugPREvents.add(e);
		}
	}

	void _onEnterFrame(EnterFrameEvent e){
		//check to see if a note is ready to be assessed
		num cTime = AudioManager.context.currentTime; //current time
		while (_notationNotesQue.length > 0 && 	cTime - _assess_Delay >=
				_notationNotesQue[0].contextTime) {
			var nrEvent = _notationNotesQue.removeAt(0);
			var ng = nrEvent.visualNoteGroup.noteGroup;
			if (!ng.isRest && !ng.notes[0].isTieTarget) {
				if (!_inst.checkNoteStartTimes) {
					assessNote(nrEvent, cTime);
				}
				else {
					assessNote4(nrEvent, cTime);
				}
			}
			else {
				_lastNotationPitch = 0;
			}
		}
	}

	void assessNote(ScoreViewerEvent noteReachedEvent, num cTime){
		num noteStartTime = noteReachedEvent.contextTime;
		var assessNote = getAssessNoteFromVNG(noteReachedEvent.visualNoteGroup);
		var noteGroup = assessNote.vng.noteGroup;
		var note = noteGroup.notes[0];
		num durationInSeconds = (noteGroup.qNoteDuration) *
			(60 / noteReachedEvent.tempo);

		//number of matches required to get note correct
		int requiredMatches = (durationInSeconds *
			_inst.requiredPitchesPerSecond).ceil();
		int matchedPitches = 0; //number of matches so far

		int notationCents = note.displayCents - (_inst.transposition * 100);

		num timeWindow = _inst.timeBucketRight * math.pow(durationInSeconds, 0.3);

		bool allowMultipleGuesses = _pitchRecognizer.pitchRecMethod == 4;
		int maxGuesses = 3;

		//DEBUG
		/*_debugNotesString += note.pitchName + "  cents:" +
			String(notationCents) + "  " + String(noteStartTime) +
			"  r" + String(requiredMatches) + "  w" + timeWindow + "  ct" +
			String(cTime) + "\n";*/

		int length = _prEvents.length;
		for (int i = 0; i < length; i++) {
			var pitchRecEvent = _prEvents[i];
			//var logThisEvent:Boolean = pitchRecEvent.correlationScore != -5;
			pitchRecEvent.correlationScore = -5;

			//DEBUG
			/*if (logThisEvent){
				_debugPRecString += "\n" + pitchRecEvent.pitchName + "  " +
					pitchRecEvent.time + "  cents:" + pitchRecEvent.cents +
					"  ct" + String(cTime);
			}*/

			//print(pitchRecEvent.cents);
			if (pitchRecEvent.time >= noteStartTime - timeWindow &&
					pitchRecEvent.time <= noteStartTime + timeWindow) {
				//DEBUG
				/*if (logThisEvent){
					_debugPRecString += "  tm!";
				}*/
				bool pitchMatch = false;
				if (!allowMultipleGuesses) {
					int pRecCents = pitchRecEvent.cents;
					if (!_inst.ignoreOctave) {
						pitchMatch = ((notationCents - pRecCents <
							_inst.tuningWindow) && (pRecCents - notationCents <
							_inst.tuningWindow));
					}
					else {
						int difference = (notationCents >= pRecCents)
							? (notationCents - pRecCents) % 1200
							: (pRecCents - notationCents) % 1200;
						pitchMatch = (difference < _inst.tuningWindow ||
							difference > 1200 - _inst.tuningWindow);
					}
				}
				else { //bells prec uses multiple guesses
					var guesses = pitchRecEvent.centsGuessList;
					int numGuesses = guesses.length;
					if (numGuesses > maxGuesses) {
						numGuesses = maxGuesses;
					}
					for (int j = 0; j < numGuesses; j++) {
						int pRecCents = guesses[j];
						if (_inst.ignoreOctave) {
							if ((notationCents - pRecCents < _inst.tuningWindow)
									&& (pRecCents - notationCents <
									_inst.tuningWindow)) {
								pitchMatch = true;
								break;
							}
						}
						else {
							int difference = (notationCents >= pRecCents)
								? (notationCents - pRecCents) % 1200
								: (pRecCents - notationCents) % 1200;
							if (difference < _inst.tuningWindow ||
									difference > 1200 - _inst.tuningWindow) {
								pitchMatch = true;
								break;
							}
						}
					}
				}

				if (pitchMatch) {
					matchedPitches++;

					//DEBUG
					/*if (logThisEvent){
						_debugPRecString += "  m+" + String(matchedPitches);
					}*/
					if (matchedPitches >= requiredMatches) {
						//handle the visual update of the display to reflect a
						//correctly played note
						_markNoteCorrect(assessNote);

						//make record of this
						_hitMissHistory.add(1);

						//show the timing
						if (i + 1 >= matchedPitches && _debug) {
							_debugMatchedNotes += "matched note: precTime: " +
								"${_prEvents[i + 1 - matchedPitches].time}" +
								" noteTime: $noteStartTime\n";
							print("matched note: precTime: ${_prEvents[i + 1 -
								matchedPitches].time} noteTime: $noteStartTime");
						}

						return;
					}
				}
			}
			else if (pitchRecEvent.time < noteStartTime - timeWindow) {
				_prEvents.removeAt(i);
				i--;
				length--;
			}
			else if (pitchRecEvent.time > noteStartTime + timeWindow) {
				break;
			}
		}

		//if we make it out of the loop without a match, the note should be marked incorrect
		_markNoteIncorrect(assessNote);
		_hitMissHistory.add(0);
	}

	void assessNote4(ScoreViewerEvent noteReachedEvent, num cTime){
		num noteStartTime = noteReachedEvent.contextTime;
		var assessNote = getAssessNoteFromVNG(noteReachedEvent.visualNoteGroup);
		var noteGroup = assessNote.vng.noteGroup;
		var note = noteGroup.notes[0];
		num durationInSeconds = (noteGroup.qNoteDuration) *
			(60 / noteReachedEvent.tempo);

		//number of matches required to get note correct - based on note length
		int requiredMatches = (durationInSeconds < 1)
			? (durationInSeconds * _inst.requiredPitchesPerSecond).ceil()
			: _inst.requiredPitchesPerSecond;
		int matchedPitches = 0; //number of matches so far

		int notationCents = note.displayCents - (_inst.transposition * 100);

		num twLeft;
		num twRight;
		if (durationInSeconds >= 1) {
			twLeft = _inst.timeBucketLeft;
			twRight = _inst.timeBucketRight;
		}
		else {
			twLeft = _inst.timeBucketLeft * math.pow(durationInSeconds, 0.4);
			twRight = _inst.timeBucketRight * math.pow(durationInSeconds, 0.4);
		}

		bool allowMultipleGuesses = _pitchRecognizer.pitchRecMethod == 4;
		int maxGuesses = 3;

		//we need to have at least an optional split within our time window in
		//order to tally towards our requiredMatches
		bool haveSplitPointInTimeWindow = false;

		//DEBUG
		//_debugNotesString += note.pitchName + "  cents:" +
		// String(notationCents) + "  " + String(noteStartTime) + "  r" +
		// String(requiredMatches) + "  w" + twLeft + "/" + twRight + "  ct" +
		// String(cTime) + "\n";

		int length = _prEvents.length;

		for (int i = _prEventWindowStartIndex; i < length; i++) {
			var pitchRecEvent = _prEvents[i];
			//var logThisEvent:Boolean = pitchRecEvent.correlationScore != -5;
			pitchRecEvent.correlationScore = -5;
			num prEventTime = pitchRecEvent.time;
			int pRecCents = pitchRecEvent.cents;

			//DEBUG
			/*if (logThisEvent){
				_debugPRecString += "\n" + pitchRecEvent.pitchName + "  " +
				pitchRecEvent.time + "  cents:" + pitchRecEvent.cents +
				"  ct" + String(cTime);
			}*/

			bool prEventInTimeWindow = (prEventTime >= noteStartTime - twLeft &&
				prEventTime <= noteStartTime + twRight);

			if (pitchRecEvent.pitchSplit || pitchRecEvent.amplSplit) {
				haveSplitPointInTimeWindow = prEventInTimeWindow;
			}

			//don't consider events that are too quiet
			num rms = pitchRecEvent.rms;
			if (rms > _maxAmplitudeEncountered) {
				_maxAmplitudeEncountered = rms;
			}
			if (rms < _maxAmplitudeEncountered * _inst.minAmplPerc) {
				//do nothing - we'll skip this event for consideration
			}

			//print(pitchRecEvent.cents);
			else if ((haveSplitPointInTimeWindow && prEventTime <=
					noteStartTime + 2 * twRight) ||	((prEventTime >=
					noteStartTime && prEventTime <= noteStartTime + twRight) &&
					_lastNotationPitch == notationCents)) {
				//DEBUG
				/*if (logThisEvent){
					_debugPRecString += "  tm!";
				}*/
				bool pitchMatch = false;
				if (!allowMultipleGuesses) {
					//var pRecCents:int = pitchRecEvent.cents;
					if (!_inst.ignoreOctave) {
						pitchMatch = ((notationCents - pRecCents <
							_inst.tuningWindow) && (pRecCents - notationCents <
							_inst.tuningWindow));
					}
					else {
						int difference = (notationCents >= pRecCents)
							? (notationCents - pRecCents) % 1200
							: (pRecCents - notationCents) % 1200;
						pitchMatch = difference < _inst.tuningWindow ||
							difference > 1200 - _inst.tuningWindow;
					}
				}
				else { //bells prec uses multiple guesses
					var guesses = pitchRecEvent.centsGuessList;
					int numGuesses = guesses.length;
					if (numGuesses > maxGuesses) {
						numGuesses = maxGuesses;
					}
					for (int j = 0; j < numGuesses; j++) {
						pRecCents = guesses[j];
						if (!_inst.ignoreOctave) {
							if ((notationCents - pRecCents < _inst.tuningWindow)
									&& (pRecCents - notationCents <
									_inst.tuningWindow)) {
								pitchMatch = true;
								break;
							}
						}
						else {
							int difference = (notationCents >= pRecCents)
								? (notationCents - pRecCents) % 1200
								: (pRecCents - notationCents) % 1200;
							if (difference < _inst.tuningWindow ||
									difference > 1200 - _inst.tuningWindow) {
								pitchMatch = true;
								break;
							}
						}
					}
				}

				if (pitchMatch) {
					matchedPitches++;
					//DEBUG
					/*if (logThisEvent){
						_debugPRecString += "  m+" + String(matchedPitches);
					}*/
					if (matchedPitches >= requiredMatches) {
						_lastNotationPitch = notationCents;

						//handle the visual update of the display to reflect a
						// correctly played note
						_markNoteCorrect(assessNote);

						//make record of this
						_hitMissHistory.add(1);

						//show the timing
						if (i + 1 >= matchedPitches && _debug) {
							_debugMatchedNotes += "matched note: precTime: " +
								"${_prEvents[i + 1 - matchedPitches].time}" +
								"noteTime: $noteStartTime\n";
							print("matched note: precTime:" +
								"${_prEvents[i + 1 - matchedPitches].time}" +
								"noteTime: $noteStartTime");
						}

						return;
					}
				}

			}
			if (prEventTime < noteStartTime - twLeft) {
				_prEventWindowStartIndex++;
			}
			else if (prEventTime > noteStartTime + twRight &&
					!haveSplitPointInTimeWindow) {
				break;
			}
		}

		_lastNotationPitch = notationCents;

		//if we make it out of the loop without a match, the note should be
		//marked incorrect
		_markNoteIncorrect(assessNote);
		_hitMissHistory.add(0);
	}

	//DEBUG
	String get debugPRecString => _debugPRecString;
	String get debugNotesString => _debugNotesString;

	List<PitchRecEvent> get debugPREvents => _debugPREvents;
	///List of NoteReached events from ScoreViewer.
	List<ScoreViewerEvent> get debugNREvents => _debugNREvents;

	String get debugMatchedNotes => _debugMatchedNotes;

	/**
	 * if true, data will be sent to debug output
	 */
	bool get debug => _debug;
	void set debug(bool value) { _debug = value; }

}