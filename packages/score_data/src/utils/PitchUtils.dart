part of score_data.utils;

class PitchUtils {
	
	//mapping of chromatic to diatonic transpositions
	static List<List<int>> transpositions = [[0,0],[1,1],[1,2],[2,3],[2,4],[3,5],[4,6],[4,7],
	                                         [5,8],[5,9],[6,10],[6,11],[7,12]];
	
	//diatonic base cent values of pitch names
	static final Map<String, int> pitchNameCentVals = { 'C':0,'D':200,'E':400,'F':500,'G':700,'A':900,'B':1100 };
	static final Map<int, String> centPitchNames = { 0:'C',100:'C',200:'D',300:'E',400:'E',500:'F',600:'F',
	                                                 700:'G',800:'A',900:'A',1000:'B',1100:'B'};
	static final List<String> pitchNames = ["C", "D", "E", "F", "G", "A", "B"];
	static final List<String> sharps = ["F", "C", "G", "D", "A", "E", "B"];
	static final List<String> flats = ["B", "E", "A", "D", "G", "C", "F"];
	
	/**
	 * takes a pitch name (such as "A4" or "C5" - never with an accidental and always uppercase) and converts it 
	 * into a integer value useful for locating the pitch on a staff
	 * @param	pitchName A two character string - an uppercase letter followed by a single digit number. 
	 * The system depends on these as sequential: A3, B3, C4, D4, E4, F4, G4
	 * @return	an integer representation of the pitch that can be used for math based placement of
	 *  objects on staff lines/spaces
	 */
	static int getStepValueOfNote(String pitchName) {
		String letter = pitchName[0];
		//int number = (letter != "A" && letter != "B")? int.parse(pitchName[1]) : int.parse(pitchName[1]) + 1;
		int number = (letter != "A" && letter != "B")? int.parse(pitchName.substring(1)) : 
													   int.parse(pitchName.substring(1)) + 1;
		int stepValue = 7 * number + (letter.codeUnitAt(0) - 65);
		return stepValue;
	}
	
	/**
	 * gets the number of steps (lines and spaces) the requested pitch lies below the top staff line of the requested clef
	 * @param	pitchName A two character string - an uppercase letter (A-G) followed by a single digit number (0-9)
	 * @param	clefType A string matching a constant from the nEngine.data.symbols.ClefType class
	 * @return	the number of steps below. A negative value means the note is above the staff.
	 */
	static int getStepsFromTopStaffLine(String pitchName, String clefType) {
		int stepValue = getStepValueOfNote(pitchName);
		int topStaffLineStepValue = 40;
		
		switch (clefType) {
			case ClefType.TREBLE:
				topStaffLineStepValue = 40;
				break;
			case ClefType.BASS:
				topStaffLineStepValue = 28;
				break;
			case ClefType.TENOR:
				topStaffLineStepValue = 32;
				break;
			case ClefType.ALTO:
				topStaffLineStepValue = 34;
				break;
			default:
				print("unsupported clef! nEngine.utils.PitchUtils.getStepsFromTopStaffLine: " + clefType);
		}
		
		return topStaffLineStepValue - stepValue;
	}

	/**
	 * returns the name of the note (not including accidental) that matches the staff line position on the specified clef
	 * @param stepsFromTopStaffLine each line and space is a step - negative values mean above the staff
	 * @param clefType a String matching a constant from the ClefType class
	 * @return the name of the pitch (ex. A4, B5, etc.)
	 */
	static String getPitchNameFromStaffLinePosition(int stepsFromTopStaffLine, String clefType) {
		int topStaffLineNoteIndex; //the index of the name of the note on the top staff line as it appears in the pitches Array below
		int topStaffLineNoteOctave; //the octave of the note on the top staff line

		switch (clefType) {
			case ClefType.TREBLE:
				topStaffLineNoteIndex = 3; //F is 4th in the index below
				topStaffLineNoteOctave = 5; //it's an F5
				break;
			case ClefType.BASS:
				topStaffLineNoteIndex = 5;
				topStaffLineNoteOctave = 3;
				break;
			case ClefType.TENOR:
				topStaffLineNoteIndex = 2;
				topStaffLineNoteOctave = 4;
				break;
			case ClefType.ALTO:
				topStaffLineNoteIndex = 4;
				topStaffLineNoteOctave = 4;
				break;
			default:
				print("unsupported clef! nEngine.utils.PitchUtils.getPitchNameFromStaffLinePosition: $clefType");
				topStaffLineNoteIndex = 3;
				topStaffLineNoteOctave = 5;
		}

		int noteIndex = topStaffLineNoteIndex - stepsFromTopStaffLine;
		int noteOctave = topStaffLineNoteOctave;
		while(noteIndex < 0){ //if our noteIndex is negative, we have a note that's in a lower octave
			noteIndex += 7;
			noteOctave--;
		}
		while(noteIndex > 6){ //if our noteIndex is greater than 6, we have a note that's in a higher octave
			noteIndex -= 7;
			noteOctave++;
		}

		//List<String> pitches = ["C", "D", "E", "F", "G", "A", "B"]; //the array starts from C because that's where the octave numbering starts
		//String noteName = pitches[noteIndex] + noteOctave.toString();
		String noteName = pitchNames[noteIndex] + noteOctave.toString();

		return noteName;
	}
	
	static String getCommonPitchNameFromCents(int cents){
		//we really mean Dart's %12... -100 is a B, so -1%12 == 11
		String letter = centPitchNames[(cents/100)%12 * 100];
		letter += (cents ~/ 1200 - 1).toString();
		return letter;
	}

	/**
	 * returns the number of leger lines for the requested line/space position
	 * @param stepsFromTopStaffLine negative values indicate steps above the staff, positive below
	 * @return negative values for leger lines above, positive for below
	 */
	static int getNumberOfLegerLines(int stepsFromTopStaffLine) {
		//compute leger lines
		int legerLines = 0;
		if (stepsFromTopStaffLine < -1) { //if the note is above the staff 2 steps or more...
			legerLines = stepsFromTopStaffLine ~/ 2; //one leger line for every 2 steps. Integer division works in our favor here, since 3 / 2 == 1 (high Bb is 3 steps above but has only one leger)
		}
		else if (stepsFromTopStaffLine > 9) { //if the note is below the staff 2 steps or more...
			legerLines = (stepsFromTopStaffLine - 8) ~/ 2;
		}

		return legerLines;
	}
	
	/**
	 * returns a reasonable diatonic transposition for a given chromatic transposition
	 * @param	chromaticSteps the number of chromatic steps the transposition encompasses
	 * @return	a corresponding number of diatonic steps that's typically associated with this chromatic transposition
	 */
	static int getCommonDiatonicTranspositionFromChromaticSteps(int chromaticSteps) {
		int numOctaves = chromaticSteps ~/ 12;
		int index = (chromaticSteps < 0)? (-1 * chromaticSteps % 12) : chromaticSteps % 12; //modulus makes this different between dart and as3
		int diatonicSteps = (chromaticSteps < 0)? -1 * transpositions[index][0] : transpositions[index][0];
		diatonicSteps += 7 * numOctaves; //numOctaves will be negative for downward transpositions
		
		return diatonicSteps;
	}
	
//	static int getDiatonicHarmonicTransposition(int diatonicSteps){
//		if (diatonicSteps == 0){
//			return 0;
//		}
//		
//		int numOctaves = diatonicSteps ~/ 7; //includes neg/pos sign
//		int baseDiatonic = diatonicSteps.remainder(7);
//		int baseHarmonic = (baseDiatonic > 0)? baseDiatonic - 7 : baseDiatonic + 7;
//		return (baseHarmonic + (numOctaves * 7));
//	}


	/**
	 * calculates the alteration for a given note as indicated by the key signature
	 * @param pitchLetterName the uppercase letter name of the pitch (A, B, C, D, E, or F)
	 * @param keySig the number of sharps or flats in the key sig - positive values for sharps, negative for flats
	 * @return negative integers refer to the number of flats, positive values indicate sharps, 0 indicates no alteration (natural)
	 */
	static int getKeySigAlterationForNote(String pitchLetterName, int keySig) {
		int keySigAlteration = 0;
		if (keySig > 0){
			//List<String> accidentals = ["F", "C", "G", "D", "A", "E", "B"];
			int pitchIndex = sharps.indexOf(pitchLetterName);
			keySigAlteration = keySig ~/ 7 + ((pitchIndex < keySig % 7)? 1 : 0); //the accidental alteration occurring naturally for this note because of the key sig
		}
		else if (keySig < 0) {
			//List<String> accidentals = ["B", "E", "A", "D", "G", "C", "F"];
			int pitchIndex = flats.indexOf(pitchLetterName);
			keySigAlteration = 1 * keySig ~/ 7 - ((pitchIndex < -1 * keySig % 7)? 1 : 0); //the accidental alteration occurring naturally for this note because of the key sig
		}
		else {
			keySigAlteration = 0;
		}

		return keySigAlteration;
	}
	
	/// Returns the absolute alteration of a note, relative to the key of C, and regardless
	/// of the key signature. Ex. An F# (6600) in the key of D will return 1 even though F# is in the key
	/// signature.
	/// @displayCents = the chromatic pitch displayed (so a Trumpet's D4 and a Flute's D4 are both 6200)
	/// @diatonicStepsFromTopStaffLine = the number of lines and spaces the displayed pitch is from the
	/// top staff line
	/// @clefType = the clef of the note
	static int getAlterationForCents(int displayCents, String pitchName){
		int naturalCents = pitchNameToDiatonicCents(pitchName);
		return ((displayCents - naturalCents) ~/ 100);
	}
	
	static int pitchNameToDiatonicCents(String pitchName) {
		int cents = pitchNameCentVals[pitchName[0]];
		int octave = int.parse(pitchName.substring(1));
		
		cents += 1200 + (octave * 1200);
		return(cents);
	}

	/**
	 * gets the key signature alteration amount for the passed in transposition values
	 * @param diatonicSteps the number of diatonic steps the transposed note is above the concert pitch note (Bb trumpet would be 1)
	 * @param chromaticSteps the number of chromatic steps the transposed note is above the concert pitch note (Bb trumpet would be 2)
	 * @return negative integer for an alteration in the flats direction, positive for an alteration in the sharps direction
	 */
	static int getKeySigAlterationForTransposition(int diatonicSteps, int chromaticSteps) {
		//D Major is diatonic = 1, chromatic = 2 ... 2 + 0 = 2
		//F Major is diatonic = 3, chromatic = 5  .... 6 + -7 = -1
		//F Major is diatonic = -4, chromatic = -7 ... -8 + 7 = -1
		//G Major is diatonic = 4, chromatic = 7 ... 8 + -7 = 1

		//return -2 * diatonicSteps + (-7 * (chromaticSteps - (2 * diatonicSteps))); //use this if transposition is amount needed to get TO concert pitch
		return 2 * diatonicSteps + (7 * (chromaticSteps - (2 * diatonicSteps)));
	}

	/**
	 * returns the key signature value (-7 to 7) for the requested key
	 * @param diatonicStepsFromC the diatonic steps from C of the new key
	 * @param chromaticStepsFromC the chromatic steps from C of the new key
	 * @param major true if the key is Major, false if it's minor
	 * @return a negative integer indicates a key with that number of flats, positive with sharps, and 0 is no sharps or flats
	 */
	static int getKeySignature(int diatonicStepsFromC, int chromaticStepsFromC, bool major) {
		return (major)? getKeySigAlterationForTransposition(diatonicStepsFromC, chromaticStepsFromC) :
				getKeySigAlterationForTransposition(diatonicStepsFromC, chromaticStepsFromC) - 3;
	}

//	/**
//	 * returns the diatonic steps offset for the requested key sig value, relative to C
//	 * @param key the key sig value (number of accidentals - positive for sharps, negative for flats)
//	 * @param major true if the key is major
//	 * @return the number of diatonic steps from C - positive is above
//	 */
//	static int getDiatonicStepsForKey(int key, bool major) {
//		if (key >= 0){
//			return (major)? (key * 4) % 7 : ((key * 4 - 2) % 7);
//		}
//		else {
//			return (major)? (-1 * (key * 4) % 7) * -1 : -1 * (-1 * (key * 4 - 2) % 7);
//		}
//	}

//	/**
//	 * returns the chromatic steps offset of the root note of the requested key, relative to C
//	 * @param key the key sig value (number of accidentals - positive for sharps, negative for flats)
//	 * @param major true if the key is major
//	 * @return the number of chromatic steps from C - positive is above
//	 */
//	static int getChromaticStepsForKey(int key, bool major) {
//		if (key >= 0){
//			return (major)? (key * 7) % 12 : ((key * 7 - 3) % 12);
//		}
//		else {
//			return (major)? (-1 * (key * 7) % 12) * -1 : -1 * (-1 * (key * 7 - 3) % 12);
//		}
//	}
	
//	///returns the pitch shift, in diatonic steps, between two keys. This is the number of diatonic steps 
//	///notes should be transposed by when changing from this oldKey to this newKey
//	static int getDiatonicShiftForKeyChange(int oldKey, int newKey, bool oldKeyIsMajor, bool newKeyIsMajor,
//	                                        [bool transposeUp = true]){
//		
//		int oldKeyPos = getDiatonicStepsForKey(oldKey, oldKeyIsMajor);
//		int newKeyPos = getDiatonicStepsForKey(newKey, newKeyIsMajor);
//		
//		int keyDelta = (newKeyPos - oldKeyPos).remainder(7);
//		if (transposeUp && keyDelta < 0){ keyDelta += 7; }
//		else if (!transposeUp && keyDelta > 0) { keyDelta -= 7; }
//		
//		return keyDelta; 
//	}
	
//	///returns the pitch shift, in chromatic steps, between two keys. This is the number of chromatic steps 
//	///notes should be transposed by when changing from this oldKey to this newKey
//	static int getChromaticShiftForKeyChange(int oldKey, int newKey, bool oldKeyIsMajor, bool newKeyIsMajor,
//	                                        [bool transposeUp = true]){
//		
//		int oldKeyPos = getChromaticStepsForKey(oldKey, oldKeyIsMajor);
//		int newKeyPos = getChromaticStepsForKey(newKey, newKeyIsMajor);
//		
//		int keyDelta = (newKeyPos - oldKeyPos).remainder(12);
//		if (transposeUp && keyDelta < 0){ keyDelta += 12; }
//		else if (!transposeUp && keyDelta > 0) { keyDelta -= 12; }
//		
//		return keyDelta; 
//	}
	
	static TranspositionDO getTranspositionForKeyChange(int oldKey, int newKey, bool oldKeyIsMajor,
														bool newKeyIsMajor, [bool transposeUp = true]){
		//for the sake of relative steps, Maj/Min has no effect. Going from Amin to CMaj, an A will become
		//a C, just like it will when going from AMaj to CMaj. But to get the appropriate key delta, we 
		//must translate minor keys to their parallel major so that we can compare on equal terms
		//(CMaj and Amin are both keyless, so the delta would be 0 if we don't change Amin to AMaj 3sharps)
		
		if (!oldKeyIsMajor) oldKey += 3;
		if (!newKeyIsMajor) newKey += 3;
		
		//ex. old AMaj (3) to new CMaj (0) //-3
		//ex. old CMaj (0) to new CbMaj(-7) //-7
		//ex. old DMaj (2) to new GMaj (1) //-1
		//ex. old DMaj (2) to new BMaj (5) //3
		//ex. old CMaj (0) to new C#Maj (7) //7
		int keyDelta = newKey - oldKey;
		
		//ex. keyDelta = -3 // -9, -5
		//ex. keyDelta = -7 // -1, 0
		//ex. keyDelta = -1 // -7, -4
		//ex. keyDelta = 3  //  9, 5
		//ex. keyDelta = 7  //  1, 0
		//ex. keyDelta = 5  //  11, 6
		int chromDelta = (keyDelta * 7).remainder(12);
		int diatDelta = (keyDelta * 4).remainder(7);
		
		if (transposeUp && chromDelta < 0){
			chromDelta += 12;
			diatDelta += 7;
		}
		else if (!transposeUp && chromDelta > 0){
			chromDelta -= 12;
			diatDelta -= 7;
		}
		return new TranspositionDO(diatDelta, chromDelta);
	}
	
	/**
	 * determines the nearest transposition direction from an old key to a new one
	 * -1 means down is closer, 1 means up is closer, 0 means they're equal
	 */
	static int getNearestTranspositionDirection(int oldKey, int newKey, bool oldKeyIsMajor, bool newKeyIsMajor){
		if (!oldKeyIsMajor) oldKey += 3;
        if (!newKeyIsMajor) newKey += 3;
        int keyDelta = newKey - oldKey;
        int chromDelta = (keyDelta * 7).remainder(12);
        if (chromDelta > 6 || (chromDelta > -6 && chromDelta < 0)){
        	return -1; //down is closer
        }
        else if (chromDelta < -6 || (chromDelta < 6 && chromDelta > 0)){
        	return 1; //up is closer
        }
        else {
        	return 0; //equally close
        }
	}

	/**
	 * gets the total key size, combining the outgoing key with the new key by figuring out how many outgoing naturals are needed
	 * @param newKey the new key signature that will be displayed
	 * @param outgoingKey the key signature from the previous measure
	 * @return the total number of accidentals that must be displayed (always positive)
	 */
	static int getTotalKeySize(int newKey, int outgoingKey) {
		if (newKey < 0){
			if (outgoingKey < newKey){
				return outgoingKey * -1;
			}
			else if (outgoingKey <= 0){
				return newKey * -1;
			}
			else {
				return newKey * -1 + outgoingKey;
			}
		}
		else {
			if (outgoingKey > newKey){
				return outgoingKey;
			}
			else if (outgoingKey >= 0){
				return newKey;
			}
			else {
				return newKey - outgoingKey;
			}
		}
	}

	/**
	 * figures out which accidentals (naturals, sharps and flats) should be shown for the combination of new and outgoing keys
	 * @param newKey the new key signature (from -7 to 7)
	 * @param outgoingKey the old key signature (from -7 to 7)
	 * @return creates an array that contains 4 sets of 7 numbers. Each set corresponds to an accidental category - naturalized flats,
	 * naturalized sharps, flats, and sharps. Each set goes in order for flats or sharps (BEADGCF or FCGDAEB). A 1 indicates
	 * that an accidental should be drawn for that position. A 0 indicates it should not.
	 * [NAT. FLATS,    NAT. SHARPS,   FLATS,         SHARPS       ]
	 * [0,0,0,1,1,0,0, 0,0,0,0,0,0,0, 1,1,1,0,0,0,0, 0,0,0,0,0,0,0]
	 */
	static List<int> getAccidentalsForNewKeySignature(int newKey, int outgoingKey) {
		/*if (newKey > 7 || newKey < -7 || outgoingKey > 7 || outgoingKey < -7){
			throw new Error("Key signature can not have more than 7 accidentals!");
		}*/
		int numNaturals = 0;
		int numFlats = 0;
		int numSharps = 0;
		
		//check for more than 7 accidentals and calculate the number of double sharps/flats
		int numDoubleFlats = 0;
		int numDoubleSharps = 0;
		if (newKey < - 7) {
			numDoubleFlats = -7 - newKey;
			newKey = -7;
		}
		else if (newKey > 7) {
			numDoubleSharps = newKey - 7;
			newKey = 7;
		}
		if (outgoingKey < -7) {
			outgoingKey = -7;
		}
		else if (outgoingKey > 7) {
			outgoingKey = 7;
		}

		/*if (newKey < 0){
			trace("here");
		}*/

		//figure out how many naturals we need for canceling the old key
		int cancelStartIndex = 0; //the index of the first natural we apply
		bool cancelSharps = false; //true if naturals are used to neutralize sharps - false for flats

		if (newKey < 0){
			numFlats = -1 * newKey;
			if (outgoingKey < newKey){
				//going from more flats to less, so we need to cancel out the difference
				numNaturals = newKey - outgoingKey; //-3 - (-7) = +4
				cancelStartIndex = newKey * -1;
				cancelSharps = false;
			}
			else if (outgoingKey <= 0){
				//no naturals, as we're just adding flats
			}
			else {
				//we had sharps before, so we need a natural for each of them
				numNaturals = outgoingKey;
				cancelStartIndex = 0;
				cancelSharps = true;
			}
		}
		else {
			numSharps = newKey;
			if (outgoingKey > newKey){
				//going from more sharps to less, so we need to cancel out the difference
				numNaturals = outgoingKey - newKey;
				cancelStartIndex = newKey;
				cancelSharps = true;
			}
			else if (outgoingKey >= 0){
				//no naturals, as we're just adding sharps
			}
			else {
				//we had flats before, so we need a natural for each of them
				numNaturals = -1 * outgoingKey;
				cancelStartIndex = 0;
				cancelSharps = false;
			}
		}

		//we create an array that contains 4 sets of 7 numbers. Each set corresponds to an accidental category - naturalized flats,
		//naturalized sharps, flats, and sharps. Each set goes in order for flats or sharps (BEADGCF or FCGDAEB). A 1 indicates
		//that an accidental should be drawn for that position. A 0 indicates it should not.
		//[NAT. FLATS,    NAT. SHARPS,   FLATS,         SHARPS       ]
		//[0,0,0,1,1,0,0, 0,0,0,0,0,0,0, 1,1,1,0,0,0,0, 0,0,0,0,0,0,0]

		List<int> accidentals = new List<int>(28);

		//first are the naturalized flats
		int i = 0;
		for (i; i < 7; i++){
			if (!cancelSharps){
				if (numNaturals > 0 && i >= cancelStartIndex){
					accidentals[i] = 1;
					numNaturals--;
					continue;
				}
			}
			accidentals[i] = 0;
		}

		//now the naturalized sharps
		for (i; i < 14; i++){
			if (cancelSharps){
				if (numNaturals > 0 && i - 7 >= cancelStartIndex){
					accidentals[i] = 1;
					numNaturals--;
					continue;
				}
			}
			accidentals[i] = 0;
		}

		//the flats for the new key
		//i: 14  numFlats: 5  numDoubleFlats: 0
		//print('i: $i  numFlats: $numFlats  numDoubleFlats: $numDoubleFlats'); 
		for (i; i < 21; i++) {
			if (i - 14 < numDoubleFlats) {
				accidentals[i] = 2;
			}
			else if (i - 14 < numFlats){
				//print(i);
				accidentals[i] = 1;
			}
			else {
				accidentals[i] = 0;
			}
		}

		//the sharps for the new key
		for (i; i < 28; i++) {
			if (i - 21 < numDoubleSharps) {
				accidentals[i] = 2;
			}
			else if (i - 21 < numSharps){
				accidentals[i] = 1;
			}
			else {
				accidentals[i] = 0;
			}
		}

		return accidentals;
	}
}