part of score_data.data;

class ClefType {
	
	static const String TREBLE = "treble";
	static const String BASS = "bass";
	static const String ALTO = "alto";
	static const String TENOR = "tenor";

	static String getClefType(String sign, int line) {
		switch(sign) {
			case "G":
				return TREBLE;
				
			case "F":
				return BASS;
				
			case "C":
				return (line == 4)? TENOR : ALTO;
				
			default:
				return TREBLE;
		}
	}
	
}