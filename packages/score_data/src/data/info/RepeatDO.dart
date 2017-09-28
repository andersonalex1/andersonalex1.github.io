part of score_data.data;

class RepeatDO extends BaseDataObject {
	///matches RepeatDirection constant
	int repeatDirection;
	///number of times to repeat - 1 is 1
	int repeatTimes;
	
	///The ending-number type is used to specify either a comma-separated list of positive 
	///integers without leading zeros, or a string of zero or more spaces. It is used for 
	///the number attribute of the ending element. The zero or more spaces version is used 
	///when software knows that an ending is present, but cannot determine the type of the ending.
	String endingNumber;
	
	///matches EndingType constant
	int endingType;
	
	///the vertical position of the ending line
	num endingVPos;
}


class RepeatDirection {
	static const int FORWARD = 0;
	static const int BACKWARD = 1;
	
	static int getDirection(String direction){
		if (direction == null) return null;
		switch (direction){
			case "forward": return FORWARD;
			case "backward": return BACKWARD;
			default: return null;
		}
	}
}

class EndingType {
	static const int START = 0;
	static const int STOP = 1;
	static const int DISCONTINUE = 2;
	
	static int getType(String type){
		if (type == null) return STOP;
		switch (type){
			case 'start': return START;
			case 'stop': return STOP;
			case 'discontinue': return DISCONTINUE;
			default: return STOP;
		}
	}
}