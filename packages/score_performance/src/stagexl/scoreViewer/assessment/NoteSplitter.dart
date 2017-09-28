part of score_performance.stagexl;

class NoteSplitter {

	List<PitchRecEvent> _prEvents = [];
	List<num> _pitchHistory = [];

	int _currentEventIndex = 0;

	///////SHARED SPLIT PARAMS//////////


	///////OPTIONAL SPLIT PARAMS////////
	int _osMinStablePitches = 6;
	int _osPitchesToConsider = 9;
	int _osMinTotalPitchJump = 60;
	int _osMinPitchStabilityThreshold = 40;
	int _osLastStablePitch = 0;
	//keeps track of the number of events that have kept stable and are added
	//into our average
	int _osStablePitchEventsCount = 0;

	num _osMinAmplPercRise = 1.0;
	num _osAmplMaxRiseTime = 0.1;

	num _osLastSplitTime = 0.0;

	num _minTimeBetweenSplits = 0.1;
	//minimum amplitude a pitch event must be to be considered as a split point
	num _minAmplPerc = 0.0;
	num _highestAmpl = 0.0;


	NoteSplitter() {

	}

	//sets note splitter parameters using settings from the passed in instrument
	void setInstrument(AssessmentInstrumentDO inst) {
		if (inst.psMinStablePitches != null) {
			_osMinStablePitches = inst.psMinStablePitches;
		}
		if (inst.psPitchesToConsider != null) {
			_osPitchesToConsider = inst.psPitchesToConsider;
		}
		if (inst.psMinTotalPitchJump != null) {
			_osMinTotalPitchJump = inst.psMinTotalPitchJump;
		}
		if (inst.psMinPitchStabilityThresh != null) {
			_osMinPitchStabilityThreshold = inst.psMinPitchStabilityThresh;
		}
		if (inst.asMinAmplPercRise != null) {
			_osMinAmplPercRise = inst.asMinAmplPercRise;
		}
		if (inst.asMaxAmplRiseTime != null) {
			_osAmplMaxRiseTime = inst.asMaxAmplRiseTime;
		}
		if (inst.spMinTimeBetweenSplits != null) {
			_minTimeBetweenSplits = inst.spMinTimeBetweenSplits;
		}
		if (inst.minAmplPerc != null) {
			_minAmplPerc = inst.minAmplPerc;
		}
	}

	/**
	 * resets the splitter for a new performance
	 */
	void reset() {
		_prEvents = [];
		_pitchHistory = [];
		_currentEventIndex = 0;

		_osLastStablePitch = 0;
		_osStablePitchEventsCount = 0;
		_osLastSplitTime = 0;
		_highestAmpl = 0;
	}

	void addEvent(PitchRecEvent prEvent) {
		//_prEvents[_currentEventIndex] = prEvent;
		_prEvents.add(prEvent);
		//_pitchHistory[_currentEventIndex] = prEvent.cents;
		_pitchHistory.add(prEvent.cents);

		var cprEvent = _prEvents[_currentEventIndex];

		if (cprEvent.rms > _highestAmpl) {
			_highestAmpl = cprEvent.rms;
		}
		else if (cprEvent.rms < _minAmplPerc * _highestAmpl) {
			_currentEventIndex++;
			return;
		}

		//make sure it passes our amplitude threshold


		//first check to see if we have an optional pitch split
		int cPitch = prEvent.cents;
		if ((cPitch - _osLastStablePitch >= _osMinTotalPitchJump ||
			_osLastStablePitch - cPitch >= _osMinTotalPitchJump) &&
			_currentEventIndex - _osPitchesToConsider + 1 >= 0) {
			//okay, the pitch has jumped enough. Now see if we're stable.
			int firstPitchIndex = _currentEventIndex - _osPitchesToConsider + 1;
			int firstSamePitchIndex = -1;
			int stableCount = 1;
			int stableTotal = cPitch;
			bool pitchStable = false;
			for (int i = firstPitchIndex; i < _currentEventIndex; i++) {
				if (_pitchHistory[i] - cPitch < _osMinPitchStabilityThreshold &&
						cPitch - _pitchHistory[i] < _osMinPitchStabilityThreshold){
					stableCount++;
					stableTotal += _pitchHistory[i];
					if (firstSamePitchIndex == -1) {
						firstSamePitchIndex = i;
					}
					if (stableCount >= _osMinStablePitches) {
						pitchStable = true;
					}
				}
			}
			if (pitchStable) {
				int newAverage = stableTotal ~/ stableCount;
				//make sure the new average pitch is truly a leap from the old
				//average pitch, and not just the event that triggered the jump
				if (newAverage - _osLastStablePitch >= _osMinTotalPitchJump ||
						_osLastStablePitch - newAverage >= _osMinTotalPitchJump){
					_osLastStablePitch = newAverage;
					_osStablePitchEventsCount = stableCount;
					_osLastSplitTime = _prEvents[firstPitchIndex].time;
					_prEvents[firstSamePitchIndex].pitchSplit = true;
					_prEvents[firstSamePitchIndex].splitCents = _osLastStablePitch;
				}

			}
		}
		else if (cPitch - _osLastStablePitch < _osMinPitchStabilityThreshold &&
				_osLastStablePitch - cPitch < _osMinPitchStabilityThreshold){
			//if this event continues our stable stretch, update our pitch average
			_osStablePitchEventsCount++;
			if (_osStablePitchEventsCount < 2) {
				//for averaging to take place, we must at least count the
				// original average - guard against a value of 1 or 0 required
				// stable pitches
				_osStablePitchEventsCount = 2;
			}
			_osLastStablePitch = (((_osStablePitchEventsCount - 1) *
				_osLastStablePitch) + cPitch) ~/ _osStablePitchEventsCount;
		}


		//check to see if we have an optional ampl split
		if (cprEvent.time - _minTimeBetweenSplits <= _osLastSplitTime) {
			_currentEventIndex++;
			return;
		}

		int prevEventIndex = _currentEventIndex - 1;
		while (prevEventIndex >= 0 && _prEvents[prevEventIndex].time >=
				cprEvent.time - _osAmplMaxRiseTime) {
			if (_prEvents[prevEventIndex].rms *
					(1 + _osMinAmplPercRise) <= cprEvent.rms) {
				cprEvent.amplSplit = true;
				_osLastSplitTime = cprEvent.time;
				break;
			}
			prevEventIndex--;
		}

		_currentEventIndex++;
	}
}