part of score_data.data;

class ArticulationType {

	static const int UNKNOWN = -1;
	static const int STACCATO = 0;
	static const int ACCENT = 1;
	static const int LEGATO = 2;
	
	static int getTypeFromName(String name) {
		switch (name){
			case "staccato": return STACCATO;
			
			case "accent": return ACCENT;
			
			case "tenuto": return LEGATO;
			
			default: return UNKNOWN;
		}
	}
}
