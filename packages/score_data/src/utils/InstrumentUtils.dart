part of score_data.utils;

class InstrumentUtils {
	static final List<InstrumentDO> instruments = [
		new InstrumentDO(3, "Soprano Recorder", "treble", -12, -2, 2,
			[[60, 71, 74], [60, 67, 79], [60, 71, 84], [60, 71, 128]],
			fingeringMode : 0, defaultRange: Range.MEDIUM),
		new InstrumentDO(4, "Alto Recorder", "treble", -5, -2, 2,
			[[60, 67, 74], [60, 67, 79], [60, 67, 84], [60, 67, 128]],
			fingeringMode : 0, defaultRange: Range.MEDIUM),
		new InstrumentDO(300, "Alto Recorder Untransposed", "treble", 0, -3, 1,
			[[67, 74, 81], [67, 74, 86], [67, 74, 91], [67, 74, 128]],
			fingeringMode : 2, defaultRange: Range.MEDIUM),
			
		new InstrumentDO(5, "Piccolo", "treble", -12, -3, 1,
			[[65, 78, 82], [65, 78, 87], [62, 78, 93], [62, 78, 128]]),
		new InstrumentDO(6, "Flute", "treble", 0, -3, 1,
			[[65, 77, 82], [63, 77, 87], [60, 77, 93], [60, 77, 128]]),
		new InstrumentDO(7, "Oboe", "treble", 0, -3, 1,
			[[65, 74, 79], [60, 74, 84], [58, 74, 91], [58, 74, 128]]),
		new InstrumentDO(8, "Bassoon", "bass", 0, -3, 1,
			[[43, 53, 60], [43, 53, 67], [34, 53, 74], [34, 53, 128]]),
		new InstrumentDO(9, "Clarinet", "treble", 2, -2, 2,
			[[52, 67, 77], [52, 72, 86], [52, 72, 91], [52, 72, 128]]),
		new InstrumentDO(10, "Bass Clarinet", "treble", 14, -2, 2,
			[[52, 67, 77], [52, 70, 86], [52, 70, 91], [52, 70, 128]]),
		new InstrumentDO(11, "Soprano Sax", "treble", 2, -2, 2,
			[[62, 72, 79], [58, 72, 84], [58, 72, 90], [58, 72, 128]]),
		new InstrumentDO(12, "Alto Sax", "treble", 9, -1, 3,
			[[62, 72, 79], [58, 72, 84], [58, 72, 90], [58, 72, 128]]),
		new InstrumentDO(13, "Tenor Sax", "treble", 14, -2, 2,
			[[62, 72, 79], [58, 72, 84], [58, 72, 90], [58, 72, 128]]),
		new InstrumentDO(14, "Bari Sax", "treble", 21, -1, 3,
			[[62, 72, 79], [58, 72, 84], [58, 72, 90], [58, 72, 128]]),
			
		new InstrumentDO(15, "Trumpet", "treble", 2, -2, 2,
			[[58, 64, 74], [54, 69, 79], [54, 69, 86], [54, 69, 128]]),
		new InstrumentDO(16, "Horn in F", "treble", 7, -2, 2,
			[[55, 64, 74], [53, 67, 79], [53, 67, 84], [48, 67, 128]]),
		new InstrumentDO(17, "Trombone", "bass", 0, -4, 0,
			[[44, 53, 60], [40, 53, 65], [40, 53, 72], [40, 53, 128]]),
		new InstrumentDO(18, "Euphonium TC", "treble", 14, -2, 2,
			[[58, 64, 74], [54, 69, 79], [54, 69, 86], [54, 69, 128]]),
		new InstrumentDO(19, "Euphonium BC", "bass", 0, -4, 0,
			[[44, 50, 60], [40, 55, 65], [40, 55, 72], [40, 55, 128]]),
		new InstrumentDO(20, "Tuba", "bass", 0, -4, 0,
			[[32, 38, 48], [28, 43, 53], [28, 43, 60], [28, 43, 128]]),
			
		new InstrumentDO(21, "Violin", "treble", 0, -1, 3,
			[[62, 68, 79], [55, 72, 86], [55, 72, 92], [55, 72, 128]]),
		new InstrumentDO(22, "Viola", "alto", 0, -1, 3,
			[[55, 61, 72], [48, 65, 79], [48, 65, 85], [48, 65, 128]]),
		new InstrumentDO(23, "Cello", "bass", 0, -1, 3,
			[[43, 49, 60], [36, 53, 67], [36, 53, 73], [36, 53, 128]]),
		new InstrumentDO(24, "Bass", "bass", 12, -1, 3,
			[[40, 49, 60], [40, 51, 67], [40, 53, 73], [40, 53, 128]]),

		new InstrumentDO(25, "Piano", "treble", 0, -2, 2,
			[[1, 69, 128], [1, 69, 128], [1, 69, 128], [1, 69, 128]])
	];
	
	static InstrumentDO getInstrumentByID(int id){
		for (var inst in instruments){
			if (inst.id == id){
				return inst;
			}
		}
		return instruments[0];
	}
}

class InstrumentDO {
	int id;
	String name;
	String clef;
	int transposition;
	int minKey;
	int maxKey;
	List<List<int>> ranges; //[[minPitch, comfortPitch, maxPitch], ...] easy,med,adv,off
	int fingeringMode; //null means no fingerings
	int defaultRange;
	
	InstrumentDO(this.id, this.name, this.clef, this.transposition, this.minKey, 
			this.maxKey, this.ranges, {int fingeringMode : null, int defaultRange : Range.MEDIUM}) {
		this.fingeringMode = fingeringMode;
		this.defaultRange = defaultRange;
	}
	
	String get label => name;
}

class Range {
	static const int EASY = 0;
	static const int MEDIUM = 1;
	static const int ADVANCED = 2;
	static const int OFF = 3;
	
	static String getRangeString(int range){
		switch (range){
			case EASY: return "Easy";
			case MEDIUM: return "Medium";
			case ADVANCED: return "Advanced";
			case OFF: return "Off";
			default: throw ('invalid range!');
		}
	}
}