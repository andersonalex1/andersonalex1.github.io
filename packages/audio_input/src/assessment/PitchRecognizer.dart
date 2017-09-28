part of audio_input.assessment;

class PitchRecognizer {
	MicManager _micManager;
	int _micSampleRate;
	
	int _quality;
	num _minFreq;
	num _maxFreq;
	int _windowWidth;
	int _overSampTimes;
	int _pitchRecMethod;
	int _resampleDivisor;
	
	num _correlationScore;
	
	List<PitchRecEvent> _prEvents;
	
	List<double> _leftOverMicData;
	
	num _recordDelay; //in seconds
	num _recordTimeStamp; //in seconds
	
	StreamSubscription<Float32List> _micSub;
	
	StreamController<PitchRecEvent> _pitchRecEventController = new StreamController.broadcast();
	
	PitchRecognizer(MicManager micManager){
		_micManager = micManager;
		
		_init();
	}
	
	void _init(){
		setInstrument(AssessmentInstrumentUtils.getInstrumentByID(3));
		
		_micSampleRate = _micManager.audioContext.sampleRate.toInt();
	}
	
	/**
	 * start pitch rec. 
	 * set startMicCapture to true if you aren't planning to use the mic data elsewhere (for recording, etc.).
	 * If you need to keep the recorded data, you should call MicManager.startCapture() separately and set 
	 * startMicCapture to false here.
	 */
	void startPRec(bool startMicCapture){
		_prEvents = [];
		
		_leftOverMicData = [];
		
		_recordDelay = -1.0;
		_recordTimeStamp = _micManager.audioContext.currentTime;
		
		_micSub = _micManager.onMicData.listen(_onMicData);
		if (startMicCapture){
			_micManager.startCapture();
		}
	}
	
	void stopPRec(bool stopMicCapture){
		if (_micSub != null){
			_micSub.cancel();
			_micSub = null;
		}
		if (stopMicCapture){
			_micManager.stopCapture();
		}
	}
	
	void setInstrument(AssessmentInstrumentDO instDO){
		_minFreq = instDO.minFreq;
		_maxFreq = instDO.maxFreq;
		_windowWidth = instDO.windowWidth;
		
		_resampleDivisor = 1;
		if (instDO.sampleRate != null){
			var sampleRate = instDO.sampleRate;
			while (sampleRate <= _micSampleRate / 2) {
				_resampleDivisor *= 2;
				sampleRate *= 2;
			}
		}
		
		_quality = instDO.pRecQuality;
		_pitchRecMethod = instDO.pRecMethod;
		_overSampTimes = instDO.overSampTimes;
	}
	
	void _onMicData(Float32List data){
		num time = _micManager.audioContext.currentTime;
		num durOfData = data.length / _micSampleRate;
		if (_recordDelay == -1.0){
			_recordDelay = time - _recordTimeStamp - durOfData;
			print('record delay: ${_recordDelay}');
		}
		
		_processData(data.toList(), time);
	}
	
	void _processData(List<double> data, num timeStamp){
		if (_leftOverMicData.length > 0){
			_leftOverMicData.addAll(data);
			data = _leftOverMicData;
		}
		
		//calculate the number of notes (pitch rec readings) to return from this set of 
		//data, based on how many _windowWidths it comprises
		int pitchesToRead = data.length ~/ (_windowWidth * _resampleDivisor);

		//seconds per pitch reading (window)
		num secondsPerPitch = _windowWidth / _micSampleRate;
		//seconds per oversamp iteration (a division of a pitch)
		num secondsPerOverSampIteration = secondsPerPitch / _overSampTimes;
		
		//the current position we're reading from in the sample data - depending on resampling, this may
		//or may not increment by 1
		int dataPos = 0; 
		
		for (int i = 0; i < pitchesToRead; i++){
			int overSampIteration = 0;
			
			//make sure oversamp iterations don't take us to audio we don't have
			//(if we were on the final "note" and an oversamp iteration beyond
			//0, we'd get into samples we don't have)
			while ((overSampIteration < _overSampTimes && i < pitchesToRead - 1)
					|| (i == pitchesToRead - 1 && overSampIteration == 0)) {
				//read the samples into our array for processing
				List<double> curData = new List<double>(_windowWidth);
				num sum = 0;
				num value;
				num peakAmpl = 0;
				for (int j = 0; j < _windowWidth; j++) {
					value = data[dataPos];
					sum += value * value;
					if (value > peakAmpl){
						peakAmpl = value;
					}
					curData[j] = value;
					dataPos += _resampleDivisor;
				}
				
				num rms = math.sqrt(sum / _windowWidth);
				
				num adjustedStartTime = timeStamp + (i * secondsPerPitch) +
					(overSampIteration * secondsPerOverSampIteration);
				
				num frequency;
				switch(_pitchRecMethod) {
//					case 0:
//						var frequency:Number = autoCorrelateProductMethod(dataVector);
//						break;
					case 1:
						frequency = _autoCorrelateProductDifferenceMethod(curData);
						break;
//					case 2:
//						frequency = autoCorrelateProductDifferenceMethodExpectedNoteList(dataVector);
//						break;
//					case 3:
//						frequency = autoCorrelateProductDifferenceMethodZeroCrossingChecks(dataVector);
//						break;
//					case 4:
//						frequency = -1;
//						fftPitchPercussionDetect(dataVector, adjustedStartTime, rms, peakAmpl); //this method dispatches the event, so no return is needed
//						break;
//					case 5:
//						frequency = autoCorrelateSquareDifferencesMethodZeroCrossingChecks(dataVector);
//						break;
					default:
						print("unsupported method! PitchRecognizer.processData()");
				}
				
				if (frequency > 0) {
					_notifyOfPitch(frequency, adjustedStartTime, rms, peakAmpl);
				}					
				
				overSampIteration++;
				//dataPos -= ((_overSampTimes - 1) / _overSampTimes) *
				//  (_windowWidth * _resampleDivisor); //from flash
				dataPos = overSampIteration * _windowWidth ~/ _overSampTimes; //dart experiment
			}
		}
	}
	
	//method 1
	num _autoCorrelateProductDifferenceMethod(List<double> samplesVector) { //product peak and subtraction average sum method
		//finds the intervals necessary for calculating one period and then picks the best period based on max product sums. 
		//After finding this period it extends the period across the full set of samples and then looks to the left and right for an interval
		//that works best across multiple periods by using a subtraction sum averaging method (lowest average is the best).
		
		var validIValues = _getValidIntervals(samplesVector);
		int bestSinglePeriodInterval = _findPeriodViaProductSums(samplesVector, validIValues);
		num bestMultiPeriodInterval = _findAveragePeriodViaAverageDifferenceSums(samplesVector, bestSinglePeriodInterval);
		
		return (_micSampleRate / _resampleDivisor) / bestMultiPeriodInterval;
	}
	
	List<int> _getValidIntervals(List<double> samplesVector) {
		int length = samplesVector.length;
		
		//get valid i values (separation values) - only distances from one peak to the next are valid
		List<int> validIValues = [];
		int firstPeakIndex = -1;
		bool readyForPeak = false;
		num lastValue = samplesVector[0];
		
		for (int i = 0; i < length; i++) {
			if ((samplesVector[i] <= lastValue) && (readyForPeak)) { //if this is a peak...
				if (firstPeakIndex != -1) { //if not the first peak, add distance between current and last peak to validIValues
					int distance = i - firstPeakIndex;
					num frequencyToCheck = 44100 / distance;
					if ((frequencyToCheck >= _minFreq) && (frequencyToCheck <= _maxFreq)) {
						validIValues.add(i - firstPeakIndex);
					}
					else if (frequencyToCheck < _minFreq) { //there can't be any more valid values at this point
						break;
					}
				}
				else {
					firstPeakIndex = i;
				}					
				readyForPeak = false;
			}
			else if (samplesVector[i] > lastValue) {
				readyForPeak = true;
			}
			lastValue = samplesVector[i];
		}
		
		return validIValues;
	}
	
	int _findPeriodViaProductSums(List<double> samplesVector, List<int> validIValues) {
		//returns the length of a single period after finding the highest sum for the passed in intervals
		int length = samplesVector.length;
		num sum;			
		//int validValueIndex = 0;
		
		num greatestSum = -10;
		int greatestSumsInterval = -1;
		int quality = _quality;
		
		for (int interval in validIValues) {
			sum = 0;
			for (int j = 0; j < length - interval; j += quality) {
				sum += samplesVector[j] * samplesVector[j + interval];	
			}
			
			if (sum >= greatestSum) {
				greatestSum = sum;
				greatestSumsInterval = interval;
			}
			
			
		}
		
		_correlationScore = greatestSum; 
		
		return greatestSumsInterval;
	}
	
	num _findAveragePeriodViaAverageDifferenceSums(List<double> samplesVector, int bestSinglePeriodInterval) {
		//look forward as many periods as possible and use a subtraction sum averaging method to find 
		//the best correlation that's close to the value of the product-determined period
		int length = samplesVector.length;
		int minBufferSamples = 10;
		int totalPeriods = length ~/ bestSinglePeriodInterval;
		//make sure there's enough room on the right to check correlation values and that totalPeriods is at least 1
		totalPeriods = ((length % bestSinglePeriodInterval < minBufferSamples) && (totalPeriods > 1))? 
								totalPeriods - 1 : totalPeriods; 
		
		int startingPoint = totalPeriods * bestSinglePeriodInterval;
		num bestAverage = -1; //we want the lowest average, but it must start out as the average at the starting point
		int bestIntervalIndex = startingPoint;
		bool improvedCorrelation = false; //set to true if a better correlation is found - used so that
		num sum;
		int minIValueToCheck = (startingPoint - minBufferSamples >= 0)? (startingPoint - minBufferSamples) : 0;
		num currentAverage;
		for (int i = startingPoint; i > minIValueToCheck; i--) { //try the values to the left first
			sum = 0;
			for (int j = 0; j < length - i; j += 1) {
				sum += (samplesVector[j] - samplesVector[j + i]).abs();					
			}
			currentAverage = sum / (length - i);
			if ((currentAverage < bestAverage) || (i == startingPoint)) {
				bestAverage = currentAverage;
				bestIntervalIndex = i;
				improvedCorrelation = (i != startingPoint)? true : false;
			}
			else {
				break;
			}
		}
		if (improvedCorrelation == false) { //if no better correlation was found on the left...
			//make sure not to look at any samples that don't exist
			int maxIValue = (startingPoint + minBufferSamples <= length)? 
							startingPoint + minBufferSamples : length; 
			for (int i = startingPoint; i < maxIValue; i++) { //now try the values on the right
				sum = 0;
				for (int j = 0; j < length - i; j += 1) {
					sum += (samplesVector[j] - samplesVector[j + i]).abs();					
				}
				currentAverage = sum / (length - i);
				if ((currentAverage < bestAverage) || (i == startingPoint)) {
					bestAverage = currentAverage;
					bestIntervalIndex = i;
				}
				else {
					break;
				}
			}
		}
		//return the average period length
		return (bestIntervalIndex / totalPeriods);
	}
	
	void _notifyOfPitch(num frequency, num time, num rms, num peakAmpl) {
		var pRecEvent = new PitchRecEvent();
		pRecEvent.frequency = frequency;

		int cents = 100 * (69 + 17.3123404907 * math.log(frequency / 440)).round();
		pRecEvent.cents = cents;
		pRecEvent.pitchName = PitchUtils.getCommonPitchNameFromCents(cents);
		pRecEvent.time = time;
		//compute the tuning (distance from 100 cent multiple - ex. 23, -44, etc.
		cents %= 100;
		if (cents >= 50) {
			cents -= 100;
		}
		pRecEvent.tuning = cents;
		pRecEvent.correlationScore = _correlationScore;
		pRecEvent.rms = rms;
		pRecEvent.peakAmpl = peakAmpl;

		_prEvents.add(pRecEvent);
		
		//trace(time);
		//trace(pRecEvent.pitchName, pRecEvent.time);
		_pitchRecEventController.add(pRecEvent);
	}
	
	Stream<PitchRecEvent> get onPitchRecEvent => _pitchRecEventController.stream;

	int get pitchRecMethod => _pitchRecMethod;
}

class PitchRecEvent {
	num frequency;
	int cents;
	String pitchName;
	int tuning;
	///time is in seconds, corresponding to AudioContext.currentTime
	num time;
	num correlationScore;
	
	List<int> centsGuessList;
	List<num> amplsGuessList;
	
	num rms;
	num peakAmpl;
	
	bool pitchSplit = false;
	bool amplSplit = false;
	int splitCents;
	
	static int totalEvents = 0;
}

class PitchUtils {
	static final Map<int, String> centPitchNames = { 0:'C',100:'C',200:'D',300:'E',400:'E',500:'F',600:'F',
    	                                                 700:'G',800:'A',900:'A',1000:'B',1100:'B'};
	
	static String getCommonPitchNameFromCents(int cents){
		//we really mean Dart's %12... -100 is a B, so -1%12 == 11
		String letter = centPitchNames[(cents/100)%12 * 100];
		letter += (cents ~/ 1200 - 1).toString();
		return letter;
	}
}
