//part of score_data.utils;
//
//class PitchTimeConverter { //utility class for converting pitch and time units
//	
//	static int letterToCents(String pitchName) {
//		int octave = int.parse(pitchName[pitchName.length - 1]);
//		
//		int cents = 0;
//		
//		if ((pitchName.indexOf("C#") != -1) || (pitchName.indexOf("Db") != -1)){
//			cents = 100;
//		}
//		else if ((pitchName.indexOf("D#") != -1) || (pitchName.indexOf("Eb") != -1)){
//			cents = 300;
//		}
//		else if (pitchName.indexOf("Fb") != -1){
//			cents = 400;
//		}
//		else if (pitchName.indexOf("E#") != -1){
//			cents = 500;
//		}
//		else if ((pitchName.indexOf("F#") != -1) || (pitchName.indexOf("Gb") != -1)){
//			cents = 600;
//		}
//		else if ((pitchName.indexOf("G#") != -1) || (pitchName.indexOf("Ab") != -1)){
//			cents = 800;
//		}
//		else if ((pitchName.indexOf("A#") != -1) || (pitchName.indexOf("Bb") != -1)){
//			cents = 1000;
//		}
//		else if (pitchName.indexOf("Cb") != -1){
//			cents = 1100;
//		}
//		else if ((pitchName.indexOf("C") != -1) || (pitchName.indexOf("B#") != -1)){
//			cents = 0;
//		}
//		else if (pitchName.indexOf("D") != -1){
//			cents = 200;
//		}
//		else if (pitchName.indexOf("E") != -1){
//			cents = 400;
//		}
//		else if (pitchName.indexOf("F") != -1){
//			cents = 500;
//		}
//		else if (pitchName.indexOf("G") != -1){
//			cents = 700;
//		}
//		else if (pitchName.indexOf("A") != -1){
//			cents = 900;
//		}
//		else if (pitchName.indexOf("B") != -1){
//			cents = 1100;
//		}
//		//trace (octave + "  " + cents + "  " + pitchName);
//		cents += 1200 + (octave * 1200);
//		return(cents);
//	}
//	
//	static String centsToLetter(int cents) {
//		int centIndex = (cents - 50) ~/ 100;
//		 String pitchName = "";
//		switch (centIndex % 12){
//			case 0:
//				pitchName = ("C# / Db" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 1:
//				pitchName = ("D" + (centIndex ~/ 12 - 1).toString() + "     ");
//				break;
//			case 2:
//				pitchName = ("D# / Eb" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 3:
//				pitchName = ("E" + (centIndex ~/ 12 - 1).toString() + "     ");
//				break;
//			case 4:
//				pitchName = ("F" + (centIndex ~/ 12 - 1).toString() + "     ");
//				break;
//			case 5:
//				pitchName = ("F# / Gb" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 6:
//				pitchName = ("G" + (centIndex ~/ 12 - 1).toString() + "     ");
//				break;
//			case 7:
//				pitchName = ("G# / Ab" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 8:
//				pitchName = ("A" + (centIndex ~/ 12 - 1).toString() + "     ");
//				break;
//			case 9:
//				pitchName = ("A# / Bb" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 10:
//				pitchName = ("B" + (centIndex ~/ 12 - 1).toString() + "     ");
//				break;
//			case 11:
//				pitchName = ("C" + (centIndex ~/ 12).toString() + "     ");
//				break;
//			default:
//				print("shouldn't get here - PitchTimeConverter.centsToLetter");
//		}
//		return(pitchName);
//	}
//	
//	static String centsToLetterNoSpaces(int cents) {
//		int centIndex = (cents - 50) ~/ 100;
//		 String pitchName = "";
//		switch (centIndex % 12){
//			case 0:
//				pitchName = ("C#/Db" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 1:
//				pitchName = ("D" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 2:
//				pitchName = ("D#/Eb" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 3:
//				pitchName = ("E" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 4:
//				pitchName = ("F" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 5:
//				pitchName = ("F#/Gb" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 6:
//				pitchName = ("G" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 7:
//				pitchName = ("G#/Ab" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 8:
//				pitchName = ("A" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 9:
//				pitchName = ("A#/Bb" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 10:
//				pitchName = ("B" + (centIndex ~/ 12 - 1).toString());
//				break;
//			case 11:
//				pitchName = ("C" + (centIndex ~/ 12).toString());
//				break;
//			default:
//				print("shouldn't get here - PitchTimeConverter.centsToLetterNoSpaces");
//		}
//		return(pitchName);
//	}
//	
//	static int roundCents(int unroundedCents) { //returns the cent value rounded off to the nearest 100
//		int hundreds = unroundedCents ~/ 100;
//		int tens = unroundedCents % 100;
//		if (tens >= 50){
//			return (hundreds * 100 + 100);
//		}
//		else {
//			return (hundreds * 100);
//		}
//	}
//	
//	/**
//	 * returns the cent value rounded off to the nearest 100 (50 and above goes up). Should be faster than roundCents()
//	 * @param	unroundedCents the cent value to round
//	 * @return	the rounded cents
//	 */
//	static int roundCents2(int unroundedCents) {
//		return 100 * ((unroundedCents + 50) ~/ 100);
//	}
//	
//	/**
//	 * converts the passed in frequency into a pitch name
//	 * @param	freq the frequency as a num
//	 * @return	the pitch name as a string
//	 */
//	static String frequencyToPitch(num freq) {
//		num transposedFreq = freq;
//		int octaveDivisions = 0; //number of times pitch is divided to get within an octave of the base frequency
//		num baseFreq = 3.4375; //very low A
//		while (transposedFreq > 2 * baseFreq) {
//			transposedFreq /= 2;
//			octaveDivisions++;
//		}
//		
//		//compute the factor that must be multiplied by the base frequency to reach the requested frequency (after it has been transposed to within one octave)
//		num multFactor = 12 * math.log(transposedFreq / baseFreq) / math.log(2);
//		
//		switch (multFactor.round()) {
//			case 0:
//				return ("A" + (octaveDivisions - 3).toString());
//			case 1:
//				return ("A#/Bb" + (octaveDivisions - 3).toString());
//			case 2:
//				return ("B" + (octaveDivisions - 3).toString());
//			case 3:
//				return ("C" + (octaveDivisions - 2).toString());
//			case 4:
//				return ("C#/Db" + (octaveDivisions - 2).toString());
//			case 5:
//				return ("D" + (octaveDivisions - 2).toString());
//			case 6:
//				return ("D#/Eb" + (octaveDivisions - 2).toString());
//			case 7:
//				return ("E" + (octaveDivisions - 2).toString());
//			case 8:
//				return ("F" + (octaveDivisions - 2).toString());
//			case 9:
//				return ("F#/Gb" + (octaveDivisions - 2).toString());
//			case 10:
//				return ("G" + (octaveDivisions - 2).toString());
//			case 11:
//				return ("G#/Ab" + (octaveDivisions - 2).toString());
//			case 12:
//				return ("A" + (octaveDivisions - 2).toString());
//			default:
//				print("unsupported pitch: $freq");
//				return "";
//		}
//	}
//	
//	/**
//	 * converts the passed in value from frequency to cents and returns the rounded cents
//	 * @param	freq The frequency to convert
//	 * @return	the equivalent cents value rounded to the nearest 100 as an int
//	 */
//	static int frequencyToRoundedCents(num freq) {
//		String pitchName = frequencyToPitch(freq);
//		return (letterToCents(pitchName));
//	}
//	
//	/**
//	 * converts the passed in value from frequeny to cents
//	 * @param	freq The frequency to convert
//	 * @return	the equivalent cents value as an int
//	 */
//	static int frequencyToCents(num freq) {
//		return (100 * (69 + 17.3123404907 * math.log(freq / 440))) as int;
//	}
//}
