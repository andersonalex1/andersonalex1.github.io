part of score_data.data;

class DurationType {
	
	static const int MAXIMA = 32768;
	static const int LONG = 16384;
	static const int BREVE = 8192;
	static const int WHOLE = 4096;
	static const int HALF = 2048;
	static const int QUARTER = 1024;
	static const int EIGHTH = 512;
	static const int SIXTEENTH = 256;
	static const int THIRTY_SECOND = 128;
	static const int SIXTY_FOURTH = 64;
	static const int ONE_TWO_EIGHTH = 32;
	static const int TWO_FIVE_SIXTH = 16;
	static const int FIVE_TWELFTH = 8;
	static const int ONE_ZERO_TWO_FOURTH = 4;
	
	static const int UNSUPPORTED = -1;

	/**
	 * returns the duration unit duration of the requested durationType, factoring in the number of augmentation dots
	 * @param durationType a String matching a constant from this class
	 * @param numDots the number of augmentation dots
	 * @return the duration of the note in Duration Units
	 */
	static int getDurationValue(int durationType, int numDots) {
		//int duration;
		int duration = durationType; //3/22/2015
//		switch (durationType) {
//			case 'whole':
//				duration = 4096;
//				break;
//			case 'half':
//				duration = 2048;
//				break;
//			case 'quarter':
//				duration = 1024;
//				break;
//			case 'eighth':
//				duration = 512;
//				break;
//			case '16th':
//				duration = 256;
//				break;
//			case '32nd':
//				duration = 128;
//				break;
//			case '64th':
//				duration = 64;
//				break;
//			case 'breve':
//				duration = 8192;
//				break;
//			case 'long':
//				duration = 16384;
//				break;
//			case 'maxima':
//				duration = 32768;
//				break;
//			case '128th':
//				duration = 32;
//				break;
//			case '256th':
//				duration = 16;
//				break;
//			case '512th':
//				duration = 8;
//				break;
//			case '1024th':
//				duration = 4;
//				break;
//			default:
//		}
		
		int dotVal = duration ~/ 2;
		for (int i = 0; i < numDots; i++) {
			duration += dotVal;
			dotVal ~/= 2;
		}
		
		return duration;
	}

	/**
	 * returns the String DurationType value for the requested duration
	 * @param duration a duration that is one of the supported powers of 2
	 * @return a String matching one of the String constants from this class
	 */
	static int getDurationType(String durationName) {
		switch(durationName){
			case 'whole': return DurationType.WHOLE;
			case 'half': return DurationType.HALF;
			case 'quarter': return DurationType.QUARTER;
			case 'eighth': return DurationType.EIGHTH;
			case '16th': return DurationType.SIXTEENTH;
			case '32nd': return DurationType.THIRTY_SECOND;
			case '64th': return DurationType.SIXTY_FOURTH;
			case 'breve': return DurationType.BREVE;
			case 'long': return DurationType.LONG;
			case 'maxima': return DurationType.MAXIMA;
			case '128th': return DurationType.ONE_TWO_EIGHTH;
			case '256th': return DurationType.TWO_FIVE_SIXTH;
			case '512th': return DurationType.FIVE_TWELFTH;
			case '1024th': return DurationType.ONE_ZERO_TWO_FOURTH;
			default:
				print("unsupported base duration! ScoreManager.getDurationType: $durationName");
		}

		//throw new Error("Unsupported duration!");
		return UNSUPPORTED;
	}

	/**
	 * calculates the dots portion of the duration
	 * @param duration a duration matching one of the powers of 2 durations
	 * @param numDots number of augmentation dots
	 * @return the duration value of the dots themselves (not combined with the supplied duration)
	 */
	static int calculateDotDuration(int duration, int numDots) {
		int dotVal = duration ~/ 2;
		int dotTotal = 0;
		for (int i = 0; i < numDots; i++) {
			dotTotal += dotVal;
			dotVal ~/= 2;
		}

		return dotTotal;
	}

	/**
	 * gets the base duration and the number of dots needed to create the requested total duration
	 * @param totalDuration the duration you want to match
	 * @return an array with 2 elements - the base duration first, then the number of dots
	 */
	static List<int> getBaseDurationAndDots(int totalDuration) {
		int baseDuration = 2;
		while (baseDuration * 2 < totalDuration){
			baseDuration *= 2;
		}

		int numDots = 0;
		int combinedDuration = baseDuration;
		int dotValue = baseDuration ~/ 2;
		while(combinedDuration < totalDuration){
			combinedDuration += dotValue;
			dotValue ~/= 2;
			numDots++;
		}

		if (combinedDuration != totalDuration){
			//throw new Error("Unsupported total duration! Must be achievable as a power of 2 plus the addition of augmentation dots.");
		}

		return [baseDuration, numDots];
	}
	
}