part of audio_input.assessment;

class AssessmentInstrumentUtils {
	static final List<AssessmentInstrumentDO> instruments = [
		new AssessmentInstrumentDO(3, "Soprano Recorder", 1, 
				transposition: -12,
				minFreq: 400,
				maxFreq: 2500,
				windowWidth: 256,
				pRecMethod: 1,
				pRecQuality: 10,
				overSampTimes: 2,
				requiredPitchesPerSecond: 30,
				tuningWindow: 50,
				ignoreOctave: false,
				checkNoteStartTimes: true,
				timeBucketLeft: 0.3,
				timeBucketRight: 0.45,
				psMinStablePitches: 6,
				psPitchesToConsider: 9,
				psMinTotalPitchJump: 60,
				psMinPitchStabilityThresh: 50,
				asMinAmplPercRise: 1.0,
				asMaxAmplRiseTime: 0.05,
				spMinTimeBetweenSplits: 0.1,
				minAmplPerc: 0.05
				),
		new AssessmentInstrumentDO(101, "Clap", 2,
				minTimeBetweenClaps: 80,
				minAmplRatioToFloor: 5,
				minConsecutiveQuietPeaks: 0,
				minAmplSlopeScore: 1.5,
				qNoteNudge: -0.15,
				qNoteBucket: 0.25
				),
		new AssessmentInstrumentDO(102, "Rhythm Voice", 2,
				minTimeBetweenClaps: 120,
				minAmplRatioToFloor: 4,
				minConsecutiveQuietPeaks: 0,
				minAmplSlopeScore: 1.5,
				qNoteNudge: -0.2,
				qNoteBucket: 0.25
				)
	];
	
	static AssessmentInstrumentDO getInstrumentByID(int id){
		for (var inst in instruments){
			if (inst.id == id){
				return inst;
			}
		}
		return null;
	}
}

class AssessmentInstrumentDO {
	int id;
	String name;
	int assessmentType; //rhythm, pitch, etc.
	
	//pitch rec params
	int transposition;
	num minFreq;
	num maxFreq;
	num windowWidth;
	int sampleRate;
	int pRecMethod;
	int pRecQuality;
	int overSampTimes;
	
	//pitch assessment params
	int requiredPitchesPerSecond;
	int tuningWindow;
	bool ignoreOctave;
	bool checkNoteStartTimes;
	num timeBucketLeft;
	num timeBucketRight;
	num minAmplPerc;
	
	//pitch and amplitude splitting params
	int psMinStablePitches;
	int psPitchesToConsider;
	int psMinTotalPitchJump;
	int psMinPitchStabilityThresh;
	num asMinAmplPercRise;
	num asMaxAmplRiseTime;
	num spMinTimeBetweenSplits;
	
	//rhythm strike params
	int minTimeBetweenClaps;
	num minAmplRatioToFloor;
	int minConsecutiveQuietPeaks;
	num minAmplSlopeScore;
	
	//rhythm assessment params
	num qNoteNudge;
	num qNoteBucket;
	
	
	AssessmentInstrumentDO(this.id, this.name, this.assessmentType, {
				int transposition : null, 
				num minFreq : null,
				num maxFreq : null,
				num windowWidth : null,
				int sampleRate : null,
				int pRecMethod : null,
				int pRecQuality : null,
				int overSampTimes : null,
				
				int requiredPitchesPerSecond: null,
            	int tuningWindow : null,
				bool ignoreOctave : null,
            	bool checkNoteStartTimes: null,
            	num timeBucketLeft: null,
            	num timeBucketRight: null,
            	num minAmplPerc: null,
            	
            	int psMinStablePitches: null,
            	int psPitchesToConsider: null,
            	int psMinTotalPitchJump: null,
            	int psMinPitchStabilityThresh: null,
            	num asMinAmplPercRise: null,
            	num asMaxAmplRiseTime: null,
            	num spMinTimeBetweenSplits: null,
            	
            	int minTimeBetweenClaps: null,
            	num minAmplRatioToFloor: null,
            	int minConsecutiveQuietPeaks: null,
            	num minAmplSlopeScore: null,
            	
            	num qNoteNudge: null,
            	num qNoteBucket
            }) {
		
		//pitch rec params
		this.transposition = transposition;
		this.minFreq = minFreq;
		this.maxFreq = maxFreq;
		this.windowWidth = windowWidth;
		this.sampleRate = sampleRate;
		this.pRecMethod = pRecMethod;
		this.pRecQuality = pRecQuality;
		this.overSampTimes = overSampTimes;
		
		//pitch assessment params
		this.requiredPitchesPerSecond = requiredPitchesPerSecond;
		this.tuningWindow = tuningWindow;
		this.ignoreOctave = ignoreOctave;
		this.checkNoteStartTimes = checkNoteStartTimes;
		this.timeBucketLeft = timeBucketLeft;
		this.timeBucketRight = timeBucketRight;
		this.minAmplPerc = minAmplPerc;
		
		//pitch and amplitude splitting params
		this.psMinStablePitches = psMinStablePitches;
		this.psPitchesToConsider = psPitchesToConsider;
		this.psMinTotalPitchJump = psMinTotalPitchJump;
		this.psMinPitchStabilityThresh = psMinPitchStabilityThresh;
		this.asMinAmplPercRise = asMinAmplPercRise;
		this.asMaxAmplRiseTime = asMaxAmplRiseTime;
		this.spMinTimeBetweenSplits = spMinTimeBetweenSplits;
		
		//rhythm strike params
		this.minTimeBetweenClaps = minTimeBetweenClaps;
		this.minAmplRatioToFloor = minAmplRatioToFloor;
		this.minConsecutiveQuietPeaks = minConsecutiveQuietPeaks;
		this.minAmplSlopeScore = minAmplSlopeScore;
		
		//rhythm assessment params
		this.qNoteNudge = qNoteNudge;
		this.qNoteBucket = qNoteBucket;
	}
	
	String get label => name;
}