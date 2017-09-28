part of audio_input.assessment;

class MicHitRecognizer extends HitRecognizer {
	MicManager _micManager;
	int _micSampleRate;
	
	int _recordDelay;
	int _recordTimeStamp;
	
	int _lastHitTime;
	int _currentSampleIndex;
	List<double> _samples;
	
	int _windowSize = 4096;
	
	double _averagePeakAmpl;
	List<double> _recentPeaks;
	double _floorPeakAmpl;
	int _numPeakReadings;
	int _consecutiveQuietPeaks;
	
	AssessmentInstrumentDO _instDO;
	
	StreamSubscription<Float32List> _micSub;
	
	MicHitRecognizer(this._micManager):super(){
		_init();
	}
	
	void _init(){
		_instDO = AssessmentInstrumentUtils.getInstrumentByID(101);
		_micSampleRate = _micManager.audioContext.sampleRate.toInt();
	}
	
	void startHitRec(){
		_recordDelay = -1;
		
		_lastHitTime = 0;
		_currentSampleIndex = 0;
		_samples = [];
		
		_averagePeakAmpl = 0.0;
		_recentPeaks = [];
		_floorPeakAmpl = 0.0;
		_numPeakReadings = 0;
		_consecutiveQuietPeaks = 0;
		
		_micSub = _micManager.onMicData.listen(_onMicData);
		
		_recordTimeStamp = (_micManager.audioContext.currentTime * 1000).toInt();
	}
	
	void stopHitRec(){
		_micSub.cancel();
	}
	
	void setInstrument(AssessmentInstrumentDO instDO){
		_instDO = instDO;
	}
	
	void _onMicData(Float32List data){
		int msTime = (_micManager.audioContext.currentTime * 1000).toInt();
		int msLengthOfData = - (1000 * (data.length / _micSampleRate)).toInt();
		if (_recordDelay == -1){
			_recordDelay = msTime - _recordTimeStamp - msLengthOfData;
		}
		
		int dataStartTime = msTime - _recordTimeStamp - msLengthOfData;
		_processAudioData(data.toList(), dataStartTime);
	}
	
	void _processAudioData(List<double> samplesBA, int timeStamp) {
		//int clapCount = 0;
		
		//extract the samples
		//samplesBA.position = 0;
		int numSamples = samplesBA.length;
		for (int i = 0; i < numSamples; i++) {
			_samples.add(samplesBA[i]);
		}
		
		//go through the samples a window width at a time. At the end of processing each window, 
		//we'll move the window forward by half its width to get an overlap
		
		int startSampleIndex = _currentSampleIndex;
		while (_currentSampleIndex + _windowSize <= _samples.length) {
			//get the adjusted time for this window
			int cTime = timeStamp + ((_currentSampleIndex - startSampleIndex) ~/ 44.1);
	
			
			//get the samples for this window
			List<double> windowSamples = [];
			double highestAmpl = -2.0;
			//int highestAmplIndex = -1;
			double lowestAmpl = 2.0;
			//int lowestAmplIndex = -1;
			
			for (int i = _currentSampleIndex; i < _currentSampleIndex + _windowSize; i++) {
				double value = _samples[i];
				if (value > highestAmpl) {
					highestAmpl = value;
					//highestAmplIndex = i;
				}
				if (value < lowestAmpl) {
					lowestAmpl = value;
					//lowestAmplIndex = i;
				}
				windowSamples.add(_samples[i]);
			}
			
			//calculate average peaks as well as the average peak of the noise floor
			num maxPeak = (lowestAmpl * -1 > highestAmpl)? lowestAmpl * -1 : highestAmpl;
			if (maxPeak < double.MIN_POSITIVE) {
				maxPeak = double.MIN_POSITIVE;
			}
			_averagePeakAmpl = (_averagePeakAmpl * _numPeakReadings + maxPeak) / (_numPeakReadings + 1);
			if (_recentPeaks.length >= 10) {
				_recentPeaks.removeAt(0);
			}
			_recentPeaks.add(maxPeak);
			double highestRecentPeak = _recentPeaks[0];
			for (int i = 1; i < _recentPeaks.length; i++) {
				if (_recentPeaks[i] > highestRecentPeak) {
					highestRecentPeak = _recentPeaks[i];
				}
			}
			
			if (_numPeakReadings < 20) {
				_floorPeakAmpl = (_floorPeakAmpl * _numPeakReadings + highestRecentPeak) / (_numPeakReadings + 1);
			}
			//after getting 20 readings, we'll start only averaging in peaks that are quieter
			else if (highestRecentPeak < _floorPeakAmpl){ 
				_floorPeakAmpl = ((_floorPeakAmpl * 19) + highestRecentPeak) / 20;
				//trace("highest recent peak:", highestRecentPeak);
			}
			_numPeakReadings++;
			
			//test for clap conditions
			
			if (/*highestAmpl > 0.05 &&*/ cTime - _lastHitTime > _instDO.minTimeBetweenClaps) {
				//passed basic volume tests, and enough time has elapsed since last hit
				
				num amplSlopeScore = _detectHitByAmplSlope(windowSamples, highestAmpl, lowestAmpl);
				//num peakAverageScore = (_numPeakReadings > 20)? maxPeak / _averagePeakAmpl : 0.0;
				num peakFloorScore = (_numPeakReadings > 20)? maxPeak / _floorPeakAmpl : 0.0;
				
				if ((peakFloorScore >= _instDO.minAmplRatioToFloor && 
						_consecutiveQuietPeaks >= _instDO.minConsecutiveQuietPeaks && 
						amplSlopeScore >= _instDO.minAmplSlopeScore)) {
					_consecutiveQuietPeaks = 0;
					_lastHitTime = cTime;
					//clapCount++;
					//trace(cTime, highestAmpl.toFixed(3), highestAmplIndex, peakFloorScore.toFixed(1), amplSlopeScore.toFixed(1));
				
					//dispatch a clap event
					var hEvent = new HitEvent();
					hEvent.hitType = HitType.RHYTHM_HIT;
					
					hEvent.time = timeStamp / 1000;
					
					_hitEventController.add(hEvent);		
				}
				else if (peakFloorScore < _instDO.minAmplRatioToFloor) {
					_consecutiveQuietPeaks++;
				}
			}
			
			
			//shift our window forward by half its size so that we overlap samples
			_currentSampleIndex += _windowSize ~/ 2;
		}
		
	}
	
	double _detectHitByAmplSlope(List<double> samplesList, double highestAmpl, double lowestAmpl) {
		
		double bestJumpRatio = (_recentPeaks.length > 1)
					? _recentPeaks[_recentPeaks.length - 1] / _recentPeaks[_recentPeaks.length - 2] 
					: 0.0;
		
		//return a value between 1 and 10 rating the quality of our best jump
		// a decent jump size is 0.01, but it's not a sure thing
		
		//var score:int = 100 * bestJump;
		double score = bestJumpRatio;
		
		return score;
	}
	
	int detectHitByJerkiness(List<double> samplesList, double highestAmpl, double lowestAmpl) {
		int numSamples = samplesList.length;
		double prevAmpl;
		double cAmpl = samplesList[0];
		double nextAmpl = samplesList[1];
		
		//int numJerks = 0;
		double biggestJerk = 0.0;
		for (int i = 1; i < numSamples - 1; i++) {
			prevAmpl = cAmpl;
			cAmpl = nextAmpl;
			nextAmpl = samplesList[i + 1];
			
			double midPointAmpl = (prevAmpl + nextAmpl) / 2;
			
			if (midPointAmpl - cAmpl > 0.01 || cAmpl - midPointAmpl > 0.01) {
				//numJerks++;
				if (midPointAmpl - cAmpl > biggestJerk) {
					biggestJerk = midPointAmpl - cAmpl;
				}
				else if (cAmpl - midPointAmpl > biggestJerk) {
					biggestJerk = cAmpl - midPointAmpl;
				}
			}
		}
		
		//return a value between 1 and 10 rating the quality of our best jerk
		// a decent jump size is 0.02
		int score = (100 * biggestJerk).toInt();
		if (score > 10) {
			score = 10;
		}
		
		return score;
	}
	
	int _detectHitByPeaks(List<double> samplesList, double highestAmpl, double lowestAmpl, int highestAmplIndex) {
		
		int numSamples = samplesList.length;
		
		double lastAmpl = 0.0;
		double highestAmplBetweeenCrossings = 0.0; //keeps track of the highest ampl (peak) between 0 crossings
		int indexOfHighestAmplBetweenCrossings = -1;
		List<int> peakIndexes = [];
		List<double> peaks = [];
		//int numPeaks = 0;
		int numPostMaxAmplPeaks = 0;
		//double postMaxAmplPeakTotal = 0.0;
		
		double nearPeakThreshold = 0.7;
		int numNearPeaks = 0;
		
		for (int i = 0; i < numSamples; i++) {
			double cAmpl = samplesList[i];
			if (cAmpl > highestAmplBetweeenCrossings) {
				highestAmplBetweeenCrossings = cAmpl;
				indexOfHighestAmplBetweenCrossings = i;
			}
			else if (cAmpl <= 0 && lastAmpl > 0) {
				//log the highest point from the previous section as a peak
				peakIndexes.add(indexOfHighestAmplBetweenCrossings);
				peaks.add(highestAmplBetweeenCrossings);
				//numPeaks++;
				if (i >= highestAmplIndex && i < highestAmplIndex + 400) {
					numPostMaxAmplPeaks++;
					//postMaxAmplPeakTotal += highestAmplBetweeenCrossings;
				}
				if (highestAmplBetweeenCrossings > nearPeakThreshold * highestAmpl) {
					numNearPeaks++;
				}
				
				indexOfHighestAmplBetweenCrossings = -1;
				highestAmplBetweeenCrossings = 0.0;
			}
			
			lastAmpl = cAmpl;
		}			
		
		//var score:int = 15 - numNearPeaks;
		int score = 2.5 * numPostMaxAmplPeaks ~/ numNearPeaks;
		if (score < 0) {
			score = 0;
		}
		else if (score > 10) {
			//trace(score);
			score = 10;
		}
		
		return score;
	}
	
	double _detectHitByPeakAverages(double highestAmpl, double lowestAmpl) {			
		double score = (_numPeakReadings > 20)? highestAmpl / _averagePeakAmpl : 0.0;
		if (score > 10.0) {
			//trace(score);
			score = 10.0;
		}
		
		return score;
	}
	
	double _detectHitByPeakSustainment(double highestAmpl, double lowestAmpl) {
		double score = (_numPeakReadings > 20)? highestAmpl / _floorPeakAmpl : 0.0;
		if (score > 10) {
			//trace(score);
			score = 10.0;
		}
		
		return score;
	}
}