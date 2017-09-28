part of score_data.data;
	
class AccidentalType {
	
	static const int NONE = 100;
	static const int NATURAL = 0;
	static const int SHARP = 1;
	static const int FLAT = -1;
	static const int DOUBLE_SHARP = 2;
	static const int DOUBLE_FLAT = -2;
	static const int TRIPLE_SHARP = 3;
	static const int TRIPLE_FLAT = -3;
//	static const String NONE = "none";
//	static const String NATURAL = "natural";
//	static const String SHARP = "sharp";
//	static const String FLAT = "flat";
//	static const String DOUBLE_SHARP = "double-sharp";
//	static const String DOUBLE_FLAT = "flat-flat";
//	static const String TRIPLE_SHARP = "triple-sharp";
//	static const String TRIPLE_FLAT = "triple-flat";
	

	/**
	 * returns the constant from the AccidentalType class that matches the passed in alteration
	 * @param alteration a value from -2 to 2 (negative for flats, positive for sharps, 0 for natural)
	 * @return a string matching a constant from the AccidentalType class
	 */
	static int getAccidentalType(int alteration) {
		switch (alteration){
			case 0:
				return AccidentalType.NATURAL;
			case 1:
				return AccidentalType.SHARP;
			case 2:
				return AccidentalType.DOUBLE_SHARP;
			case 3:
				return AccidentalType.TRIPLE_SHARP;
			case -1:
				return AccidentalType.FLAT;
			case -2:
				return AccidentalType.DOUBLE_FLAT;
			case -3:
				return AccidentalType.TRIPLE_FLAT;
			default:
				print('unsupported accidental alteration: $alteration');
//				throw "Unsupported accidental type! " + alteration.toString();
				return AccidentalType.NONE;
		}
	}
	
	static int getAccidentalFromString(String name){
		switch (name){
			case 'none': return NONE;
			case 'natural': return NATURAL;
			case 'sharp': return SHARP;
			case 'flat': return FLAT;
			case 'double-sharp': return DOUBLE_SHARP;
			case 'sharp-sharp': return DOUBLE_SHARP;
			case 'flat-flat': return DOUBLE_FLAT;
			case 'triple-sharp': return TRIPLE_SHARP;
			case 'triplet-flat': return TRIPLE_FLAT;
			default: return NONE;
		}
	}
	
}