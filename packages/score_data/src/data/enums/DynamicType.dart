part of score_data.data;

class DynamicType {
	
	static const String FFFF = "ffff";
	static const String FFF = "fff";
	static const String FF = "ff";
	static const String F = "f";
	static const String MF = "mf";
	static const String MP = "mp";
	static const String P = "p";
	static const String PP = "pp";
	static const String PPP = "ppp";
	static const String PPPP = "pppp";
	
	
	static num getVolumeByType(String type){
		switch(type){
			case F: return 0.5;
			case P: return 0.3;
			case FF: return 0.6;
			case PP: return 0.2;
			case MF: return 0.43;
			case MP: return 0.37;
			case FFF: return 0.65;
			case PPP: return 0.15;
			case FFFF: return 0.7;
			case PPPP: return 0.1;
			default: return 0.45;
		}
	}
}
