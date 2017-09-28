part of score_data.data;

class Barline extends NotationObject {
	///matches BarlineStyle constant
	int style;
	///matches BarlineLocation constant
	int location;
}


class BarlineStyle {
	static const int REGULAR = 0;
	static const int DOTTED = 1;
	static const int DASHED = 2;
	static const int HEAVY = 3;
	static const int LIGHT_LIGHT = 4;
	static const int LIGHT_HEAVY = 5;
	static const int HEAVY_LIGHT = 6;
	static const int HEAVY_HEAVY = 7;
	static const int TICK = 8;
	static const int SHORT = 9;
	static const int NONE = 10;
	
	static int getStyle(String type){
		if (type == null) return REGULAR;
		switch(type){
			case 'regular': return REGULAR;
			case 'dotted': return DOTTED;
			case 'dashed': return DASHED;
			case 'heavy': return HEAVY;
			case 'light-light': return LIGHT_LIGHT;
			case 'light-heavy': return LIGHT_HEAVY;
			case 'heavy-light': return HEAVY_LIGHT;
			case 'heavy-heavy': return HEAVY_HEAVY;
			case 'tick': return TICK;
			case 'short': return SHORT;
			case 'none': return NONE;
			default: return REGULAR;
		}
	}
}

class BarlineLocation {
	static const int LEFT = 0;
	static const int MIDDLE = 1;
	static const int RIGHT = 2;
	
	static int getLocation(String location){
		if (location == null) return RIGHT;
		switch (location){
			case 'left': return LEFT;
			case 'middle': return MIDDLE;
			case 'right': return RIGHT;
			default: return RIGHT;
		}
	}
}

