part of score_data.music_creation;

class Arranger {
	ScoreManager _scoreManager;

	bool _debug = false;

	Arranger (this._scoreManager){

	}

	/////////////////////////////////NOTE/STAFF HIDING//////////////////////////
	///hides all but the indicated staff for the given part
	void makePartSingleStaff(Part part, [staffIndex = 0]){
		for (int i = 0; i < part.staves.length; i++){
			part.staves[i].visible = (i == staffIndex);
		}
	}

	///sets all staves to visible (reverts makePartSingleStaff())
	void showAllStaves(){
		for (var part in _scoreManager.score.parts){
			for (var staff in part.staves){
				staff.visible = true;
			}
		}
	}

	///shows only the top notes in the top voice
	void showTopNotesOnly(Staff staff){
		for (var measure in staff.measures){
			var voices = measure.voices;
			for (int i = 0; i < voices.length; i++){
				var voice = voices[i];
				if (voices.length > 0 && voice.number > 1){
					//hide NoteGroups in lower voices
					for (var ng in voice.noteGroups){
						ng.visible = false;
					}
				}
				else {
					for (var ng in voice.noteGroups){
						if (!ng.isRest){
							var notes = ng.notes;
							if (notes.length > 1) {
								//hide lower notes on chords
								for (int j = notes.length - 2; j >= 0; j--) {
									notes[j].visible = false;
								}
								ng.clearVisibleNotesCache();
							}
						}
					}
				}
			}
		}
	}

	///designed to undo showTopNotes only, reverts all note visibility to
	///previous state
	void revertNoteHiding(Staff staff){
		for (var measure in staff.measures){
			for (var voice in measure.voices){
				for (var ng in voice.noteGroups){
					ng.revertVisibility();
					for (var note in ng.notes){
						note.revertVisibility();
					}
					ng.clearVisibleNotesCache();
				}
			}
		}
	}

	////////////////////////////////SMART TRANSPOSITION/////////////////////////

	///Transposes song to fit the specified part(s) as comfortably as possible
	///If you intend to use fixOctaveProblems() after this to enforce an instrument range,
	///you should specify a maxAllowedPitch here, as it will attempt to choose the key that will
	///result in the fewest required octave correction points. If you don't intend to call
	///fixOctaveProblems(), you might want to set enforceMinPitch to true and leave
	///maxAllowedPitch null, as this will use a simpler algorithm that picks the key and
	///transposition that best fits the comfort note and key range while not allowing notes to go
	///below the minAllowedPitch.
	///
	///Also sets the diatonic/chromatic transposition of the specified part (and its measures).
	///instTransposition = the chromatic transposition of the instrument, in written
	///		steps above concert pitch
	///clef = the clef for the instrument
	///comfortPitch = the comfort center of the written range (soprano recorder low C is 60, same as flute)
	///minAllowedPitch = the min allowed written pitch for the instrument (60 for sop recorder).
	///		minAllowedPitch is used in conjunction with enforceMinPitch. If enforceMinPitch is set to true,
	///		the resulting transposition will honor the minAllowedPitch. If enfoceMinPitch is false,
	///		the result may go below the minAllowedPitch to allow for range octave correction to handle
	///		the task.
	///minKey = desired minimum key sig (negative values for flats, positive for sharps)
	///maxKey = desired maximum key sig (negative values for flats, positive for sharps)
	///parts = the part to base the song transposition on
	///limitPlaybackOctaveChange = if true, each part's playbackOctaveDelta prop
	///will be adjusted if necessary to keep the playback octave from changing
	///too drastically.
	///maxAllowedPitch = if set, this value will be used as a non-binding consideration for choosing
	///		the best key. The result may still go above this value. With this set to null, a different
	///		algorithm is run for choosing the best key to transpose to.
	void fitMusicToInstrument(int instTransposition, String clef, int comfortPitch,
		int minAllowedPitch, int minKey, int maxKey, [Part part = null,
			bool limitPlaybackOctaveChange = true, int maxAllowedPitch = null,
			bool enforceMinPitch = true]) {
		//change the clef and transposition for the current instrument
		//int transposition = (instTransposition < 0)? -1 * (-1 * instTransposition % 12) : instTransposition % 12;
		int transposition = instTransposition;

		int minPitch = 200; //min written (display) cents / 100
		int maxPitch = 0; //max written (display) cents / 100
		List<int> pitches = [];

		//int pitchTotal = 0;
		//int numNotes = 0;

		if (part == null) part = _scoreManager.score.parts[0];

		_scoreManager.setPartTransposition(part, transposition);


		for (var staff in part.staves) {
			_scoreManager.changeClef(staff.measures[0], staff.measures[staff.measures.length - 1], clef);
		}

		//we want to determine the highest and lowest notes in the song
		//var noteGroups = part.noteGroups;
		var noteGroups = part.getNoteGroupsWithoutRests(0, 0);
		for (var ng in noteGroups) {
			//if (!ng.isRest) {
			if (!ng.isRest && ng.visible){
				//int pitch = ng.notes[0].displayCents ~/ 100;
				int pitch = ng.visibleNotes[0].displayCents ~/ 100;
				pitches.add(pitch);
				if (pitch > maxPitch){
					maxPitch = pitch;
				}
				if (pitch < minPitch){
					minPitch = pitch;
				}
				//pitchTotal += pitch;
				//numNotes++;
			}
		}


		//num averagePitch = pitchTotal / numNotes;

		//first find the interval that would get our top and bottom notes best fitted around our comfort note,
		//and adjust it so that it doesn't go below the min playable pitch for the instrument
		int adjustInterval = (comfortPitch - ((minPitch + maxPitch) / 2)).toInt();
		//int adjustInterval = (comfortPitch - averagePitch).round();
		if (enforceMinPitch && minPitch + adjustInterval < minAllowedPitch) {
			adjustInterval = minAllowedPitch - minPitch;
		}


		//get a list of the transpositions on each side of the adjustInterval which fit the
		//min and max allowed key signatures
		var firstMeasure = part.staves[0].measures[0];
		int origKey = firstMeasure.displayKey;
		bool isMajor = firstMeasure.isMajorKey;
		Map<TranspositionDO, int> validTranspositions = {};
		for (int newKey = minKey; newKey <= maxKey; newKey++){
			var upTrans = PitchUtils.getTranspositionForKeyChange(origKey, newKey, isMajor, isMajor, true);
			while(upTrans.chromatic < adjustInterval){
				upTrans.chromatic += 12;
				upTrans.diatonic += 7;
			}
			while(upTrans.chromatic > adjustInterval + 12){
				upTrans.chromatic -= 12;
				upTrans.diatonic -= 7;
			}
			validTranspositions[upTrans] = newKey;

			if (upTrans.chromatic != 0){
				var downTrans = new TranspositionDO(upTrans.diatonic - 7, upTrans.chromatic - 12);
				if (!enforceMinPitch || downTrans.chromatic + minPitch > minAllowedPitch){
					validTranspositions[downTrans] = newKey;
				}
			}
		}

		//pick the best of the legitimate transpositions that fit our key requirements
		TranspositionDO bestTrans;
		if (maxAllowedPitch == null){
			bestTrans = _chooseTranspositionByKeyAndDistanceFromIdeal(validTranspositions,
				minKey, maxKey, adjustInterval);
		}
		else {
			bestTrans = _chooseTranspositionByFewestOctaveShifts(validTranspositions, pitches,
				minAllowedPitch, maxAllowedPitch, adjustInterval, minKey, maxKey);
		}

		//calculate playback octave correction
		int pboDelta = 0;
		if (limitPlaybackOctaveChange){
			while(bestTrans.chromatic + pboDelta * 12 > 7){ pboDelta--; }
			while(bestTrans.chromatic + pboDelta * 12 <= -5){ pboDelta++; }
		}

		//transpose the song
		_scoreManager.transposeSong(bestTrans.diatonic, bestTrans.chromatic,
			false, pboDelta);

		//for any parts other than the primary one(s) we're trying to transpose, we can limit the octave changes
		//to preserve the sound of an accompaniment
		/*if (limitOctaveChangesOfOtherParts){
			int octaveCorrection = 0;
			while(bestTrans.chromatic + octaveCorrection * 12 > 7){ octaveCorrection--; }
			while(bestTrans.chromatic + octaveCorrection * 12 <= -5){ octaveCorrection++; }

			if (octaveCorrection != 0){
				var score = _scoreManager.score;
				for (int i = 0; i < score.parts.length; i++){
					var p = score.parts[i];
					if (p != part){
						_scoreManager.changeOctaveOfPart(p, octaveCorrection);
					}
				}
			}
		}*/
	}

	///scores potential transpositions based on how far they are from the ideal chromatic
	///transposition interval and how much they deviate from the ideal key - returns the winner
	TranspositionDO _chooseTranspositionByKeyAndDistanceFromIdeal(
		Map<TranspositionDO, int> validTranspositions,
		int minKey, int maxKey, int idealChromatic){

		int idealKey = (maxKey + minKey) ~/ 2;
		int adjustmentOffset;
		int bestScore = 0;
		TranspositionDO bestTrans;
		int points;

		for (var trans in validTranspositions.keys){
			adjustmentOffset = (trans.chromatic - idealChromatic).abs();
			int newKey = validTranspositions[trans];
			points = (100 - adjustmentOffset - (1.5 * (newKey - idealKey).abs())).toInt();
			if (points > bestScore){
				bestScore = points;
				bestTrans = trans;
			}
		}
		return bestTrans;
	}

	///scores potential transpositions based on how many octave shifts would be necessary to
	///make the notes fit between the min and max allowed pitches
	TranspositionDO _chooseTranspositionByFewestOctaveShifts(
			Map<TranspositionDO, int> validTranspositions,
			List<int> pitches, int minAllowedPitch,
			int maxAllowedPitch, int idealChromatic,
			int minKey, int maxKey){
		int idealKey = (maxKey + minKey) ~/ 2;
		int adjustmentOffset;
		int bestScore = 999999; //we want the lowest score
		int bestNonZeroOffsets = 999999;
		TranspositionDO bestTrans;
		int points;
		for (var trans in validTranspositions.keys){
			adjustmentOffset = (trans.chromatic - idealChromatic).abs();
			if (adjustmentOffset > 6){
				//consider skipping versions that are too far from our ideal...
				//we have the same key in the other direction, anyway
				//continue;
			}

			int chromaticTrans = trans.chromatic;
			int numShifts = 0;
			int currentOffset = 0;
			int numNonZeroOffsetNotes = 0;
			for (int pitch in pitches){
				bool changeMade = false;
				while (pitch + currentOffset + chromaticTrans > maxAllowedPitch){
					currentOffset -= 12;
					changeMade = true;
				}
				while (pitch + currentOffset + chromaticTrans < minAllowedPitch){
					currentOffset += 12;
					changeMade = true;
				}
				if (changeMade) { numShifts++; }
				if (currentOffset != 0){ numNonZeroOffsetNotes++; }
			}

			points = numShifts;
			if (points < bestScore){
				bestScore = points;
				bestTrans = trans;
				bestNonZeroOffsets = numNonZeroOffsetNotes;
			}
			else if (points == bestScore && numNonZeroOffsetNotes < bestNonZeroOffsets){
				//favor key direction that minimizes octave adjustment
				bestScore = points;
				bestTrans = trans;
				bestNonZeroOffsets = numNonZeroOffsetNotes;
			}
			else if (points == bestScore){
				//tie breaker - weigh the distance from the ideal transposition and the key
				int newKeyDelta = (idealKey - validTranspositions[trans]).abs();
				int newPoints = (100 - adjustmentOffset - (1.5 * newKeyDelta)).toInt();
				int bestKeyDelta = (idealKey - validTranspositions[bestTrans]).abs();
				int bestAdjustmentOffset = (bestTrans.chromatic - idealChromatic).abs();
				int bestPoints = (100 - bestAdjustmentOffset - (1.5 * bestKeyDelta)).toInt();

				if (newPoints > bestPoints){
					bestScore = points; //NOT newPoints! - keep same comparison basis
					bestTrans = trans;
					bestNonZeroOffsets = numNonZeroOffsetNotes;
				}
			}
		}
		return bestTrans;
	}


	////////////////////OCTAVE RANGE CHECKING ADJUSTMENT/////////////////////////////////
	void fixOctaveProblems(Part part, int minPitch, int maxPitch, int comfortPitch) {
		//notes without rests and without notes that continue or end ties
		//var ngList = _getNoteGroupsForPartWithoutRestsOrTieIntos(part);
		var ngList = part.getNoteGroupsWithoutRestsOrTieIntos();
		if (ngList.length == 0){
			return;
		}

		bool _isInRange(int index, int transposition) {
			//int pitch = ((ngList[index].notes[0].displayCents / 100) + (12 * transposition)).toInt();
			int pitch = ((ngList[index].visibleNotes[0].displayCents / 100) + (12 * transposition)).toInt();
			return (pitch >= minPitch && pitch <= maxPitch);
		}

		//////////////////////////////////////
		//create the list of start points that require different transpositions
		List<int> points = _getOctaveShiftMarkers(ngList, minPitch, maxPitch);
		//////////////////////////////////////

		//create the list of points that have to be transposed

		//consider each consecutive pair of points and determine if a smooth transition can happen between
		//them or whether a new transposition (or 0 transposition) must exist between them.
		//we do this by looking forward from the left point (if it exists), matching the left point's
		//transposition as long as possible with each successive note. Then we start from the
		//right point and look backwards, matching the right point's transposition as long as possible for
		//each preceding note. We track the index reached in both cases. If they overlap,
		//we know a smooth transition can be achieved with no further points. If the left and right point
		//are the same transposition, we'll apply that transposition to all of the notes
		//inbetween as well. If they are different, we will perform a routine to find the best transition
		//point between the two octaves.

		//if the indexes reached above leave a gap, as shown below with left/right points of 2 and 3:
		//2, 2, 2, 2, 0, 0, 0, 0, 3, 3, 3
		//...we find the integer octave transposition value closest to the average of 2 and 3 (2.5)
		//which IS achievable for all notes that fill the gap. We already know that 0 is a viable
		//value, but we'll look for the value that is the best fit. We'll then create 2 additional
		//points (m1, m2) (these could be the same, if the gap size is 1), each with this "compromise"
		//value. Then we'll perform the routine to find the smoothest transition between the left point
		//and m1, and then again with m2 to the right point. Between m1 and m2, all notes will be
		//set to our compromise transposition value

		int leftIndex = 0;
		int rightIndex;
		int leftTrans = (points[0] == null)? 0 : points[0];
		int rightTrans;
		for (int i = 0; i < points.length; i++) {
			if (points[i] != null || i == points.length - 1) {
				if (i == points.length - 1) {
					//print('here');
				}
				rightIndex = i;
				rightTrans = (points[i] == null)? 0 : points[i];

				//figure out how far we can stretch the left point's transposition
				int leftTransReachIndex = leftIndex;
				while (leftTransReachIndex + 1 <= rightIndex && _isInRange(leftTransReachIndex + 1, leftTrans)) {
					leftTransReachIndex++;
				}

				//figure out how far we can stretch the right point's transposition
				int rightTransReachIndex = rightIndex;
				while (rightTransReachIndex -1 >= leftIndex && _isInRange(rightTransReachIndex - 1, rightTrans)) {
					rightTransReachIndex--;
				}

				if (leftIndex == 0 && leftTrans == 0 && rightIndex == points.length - 1 && rightTrans == 0) {
					//special case for situation where the beginning of the song and end are both at 0
					//transposition with no points inbetween
					points[0] = 0;
					points[points.length - 1] = 0;
					_createTransitionTranspositions(ngList, points, leftIndex, rightIndex, minPitch,
						maxPitch, comfortPitch);
				}
				else if (rightIndex - leftIndex <= 1) {
					//handle special case where consecutive notes were out of range by not running logic
					//to check between them. This also applies to the first note
					//if it has a transposition other than 0 (it will be both the left and right point right now)

					//check if either of these are the beginning/last note in the song. If so,
					//and if they have a transposition of 0, we need to identify them as a point
					if (leftIndex == 0 && leftTrans == 0) {
						points[leftIndex] = _isInRange(leftIndex, rightTrans)? rightTrans : 0;
					}
					if (rightIndex == points.length - 1 && rightTrans == 0) {
						points[points.length - 1] = _isInRange(rightIndex, leftTrans)? leftTrans : 0;
					}
				}
				else if (leftTransReachIndex >= rightTransReachIndex - 1) {
					//a successful reach

					//we don't need any extra transposition points between these two - we'll let the
					//transition routine find the best place to jump (unless they're the same)

					if (leftIndex == 0 && leftTrans == 0) {
						//this is the start of the song, and if possible, we want the right point's
						//transposition to push back to the beginning. However if doing so would put notes
						//out of range, we set the left point (start note) to 0.
						points[0] = (rightTransReachIndex <= leftIndex)? points[rightIndex] : 0;
						//////////////8/23/2015 TEST//////////////
						//points[0] = (rightTransReachIndex <= leftIndex && rightIndex - leftIndex < 5)
						//							? points[rightIndex] : 0;
						//////////////////////////////////////////
					}
					else if (rightIndex == points.length - 1 && rightTrans == 0) {
						//this is the end of the song, and if possible, we want the left point's
						//transposition to stretch to the end. However if doing so would put notes out of
						//range, we'll instead set the right point (last note) to 0.
						points[points.length - 1] = (leftTransReachIndex >= rightIndex)? points[leftIndex] : 0;
						//////////////8/23/2015 TEST//////////////
						//points[points.length - 1] = (leftTransReachIndex >= rightIndex && rightIndex - leftIndex < 5)
						//							? points[leftIndex] : 0;
						//////////////////////////////////////////
					}

					_createTransitionTranspositions(ngList, points, leftIndex, rightIndex, minPitch, maxPitch, comfortPitch);
				}
				else {
					//we have some sort of gap. Create two new middle points to define this region.
					//In the special case of the left or right point being the beginning/end
					//of the piece, we'll make that point the m1Index/m2Index
					int m1Index = (leftIndex == 0 && leftTrans == 0)? leftIndex : leftTransReachIndex + 1;
					int m2Index = (rightIndex == points.length - 1 && rightTrans == 0)? rightIndex : rightTransReachIndex - 1;
					//var m1Index:int = (leftIndex == 0 && leftTrans == 0)? leftTransReachIndex : leftTransReachIndex + 1;
					//var m2Index:int = (rightIndex == points.length - 1 && rightTrans == 0)? rightTransReachIndex : rightTransReachIndex - 1;

					//now find the transposition that works for all notes from m1Index to m2Index
					//and which is closest to the average transposition of the left and right points
					//we already know that 0 works for these values (because otherwise they would
					//have had their own point associated with them). But we might be able to more closely
					//match the left and right transpositions.
					num averageTrans = (leftTrans + rightTrans) / 2;
					int testTrans = (averageTrans > 0)? averageTrans.ceil() : averageTrans.floor();
					bool foundSuitable = false;
					while (!foundSuitable) {
						if (testTrans == 0) {
							break; //no need to test 0 again
						}
						else if (testTrans == leftTrans || testTrans == rightTrans) {
							testTrans += (testTrans < 0)? 1 : -1;
							//no need to test either the left or right points' transpositions again, we
							//know they can't work in the gap
							continue;
						}

						//test the new transposition on the gap notes
						foundSuitable = true;
						for (int j = m1Index; j <= m2Index; j++) {
							if (_isInRange(j, testTrans) == false) {
								foundSuitable = false;
								testTrans += (testTrans < 0)? 1 : -1;
								break;
							}
						}
					}

					//we have our verified transposition value
					points[m1Index] = testTrans;
					points[m2Index] = testTrans;

					if (m1Index - leftIndex > 1){
						_createTransitionTranspositions(ngList, points, leftIndex, m1Index, minPitch, maxPitch, comfortPitch);
					}
					if (m2Index - m1Index > 1) {
						_createTransitionTranspositions(ngList, points, m1Index, m2Index, minPitch, maxPitch, comfortPitch);
					}
					if (rightIndex - m2Index > 1) {
						_createTransitionTranspositions(ngList, points, m2Index, rightIndex, minPitch, maxPitch, comfortPitch);
					}
				}



				//prepare for next pair of points by making the current right point the new left point
				leftIndex = i;
				leftTrans = points[i];
			}
		}

		//the points array now has a transposition value for every note - transpose the notes!
		//_adjustOctavesOfNotes(points, ngList); //changed on 11/4/2016 to add part
		_scoreManager.adjustOctavesOfNotes(points, ngList);

	}

	List<int> _getOctaveShiftMarkers(List<NoteGroup> ngList, int minPitch, int maxPitch) {
		//the purpose of this function is to find the minimum number of different
		//places the octave must shift in the song. This returns a list of
		//values indicating the required octave shift (1, -1, 2, etc.) at places
		//where it's no longer possible to continue with a previous octave. The
		//code works by starting with the first note and documenting all of the
		//octaves it could potentially be transposed to and still fit in the min/max
		//range. Then as we loop forward through successive notes, we check to see
		//which of those initial octaves is still viable, removing an octave each
		//time it proves impossible for the current note. When we get to a point
		//where none of the original octaves can work, we pick the octave that
		//made it the farthest and mark that for the original position. We then
		//get a new set of octaves for our current note, mark this as the new
		//original position, and move forward. This should give us the fewest
		//possible number of octave shifts and hopefully keep us closer to the
		//original shape. At a later stage we'll go through and look for good
		//places to shift between these octave markers.
		List<int> points = [];
		List<int> remainingOctaveOptions = null;
		int transpositionStartIndex = 0;
		for (int i = 0; i < ngList.length; i++) {
			points.add(null);

			var ng = ngList[i];

			var note = ng.visibleNotes[0];
			int pitch = note.displayCents ~/ 100;

			if (remainingOctaveOptions != null) { //this is only null on first pass
				//check which of our remaining transposition options are still valid
				List<int> octaveOptions = [];
				for (int octave in remainingOctaveOptions){
					int testPitch = pitch + (12 * octave);
					if (testPitch >= minPitch && testPitch <= maxPitch){
						octaveOptions.add(octave);
					}
				}


				if (octaveOptions.length == 0/* || i == ngList.length - 1*/) {
					//okay, none of the previously valid octave options fit with this
					//note (or it's the last note). So first we need to pick a winner
					//octave for the previous transposition start position.
					remainingOctaveOptions.sort((a, b) => (a * a <= b * b)? -1 : 1);
					if(_debug) print(remainingOctaveOptions);
					points[transpositionStartIndex] = remainingOctaveOptions[0];

					//and now kill the remainingOctaveOptions so that we can create
					//a fresh set for the current note
					if (octaveOptions.length == 0) {
						remainingOctaveOptions = null;
					}
				}
				else {
					//octaveOptions.length must be > 0
					//these octaves were still good, so update the remainingOctaveOptions
					remainingOctaveOptions = octaveOptions;
				}
			}

			//build the initial list of transposition options for the new starting
			//point
			if (remainingOctaveOptions == null) {
				transpositionStartIndex = i;
				remainingOctaveOptions = [];
				int octave = 0;
				while (pitch + (12 * octave) <= maxPitch) {
					if (pitch + (12 * octave) >= minPitch) {
						if (remainingOctaveOptions.indexOf(octave) == -1) {
							remainingOctaveOptions.add(octave);
						}
					}
					octave++;
				}
				octave = -1;
				while (pitch + (12 * octave) >= minPitch) {
					if (pitch + (12 * octave) <= maxPitch) {
						if (remainingOctaveOptions.indexOf(octave) == -1) {
							remainingOctaveOptions.add(octave);
						}
					}
					octave--;
				}
			}

		}

		if (points.length > 0) {
			//the last note position will not yet have an octave designation
			remainingOctaveOptions.sort((a, b) => (a * a <= b * b) ? -1 : 1);
			points[points.length - 1] = remainingOctaveOptions[0];

			//the first note position may also not have been set if no shifts happened
			if (points[0] == null) points[0] = points.last;

			if (_debug) print("points: ${points.toString()}");
		}
		return points;
	}

	void _createTransitionTranspositions(List<NoteGroup> ngList, List<int> transpositionPoints,
		int leftIndex, int rightIndex, int minPitch, int maxPitch, int comfortPitch) {

		int leftTrans = transpositionPoints[leftIndex];
		int rightTrans = transpositionPoints[rightIndex];

		if (leftTrans == rightTrans) {
			//special situation - all transpositions are the same, so set them and be done
			for (int i = leftIndex + 1; i < rightIndex; i++) {
				transpositionPoints[i] = leftTrans;
			}
			return;
		}

		/////////////////////////////

		//calculate a base score for the first interval between the newly transposed note and the following untransposed note

		num bestTransitionScore = -10000;
		int bestTransitionIndex = leftIndex; //index of the last note that should be transposed

		for (int i = leftIndex; i < rightIndex; i++) {
			var currentNG = ngList[i];
			var cNote = currentNG.visibleNotes[0];
			int cPitchLeftTrans = ((cNote.displayCents / 100) + (12 * leftTrans)).toInt();

			var nextNG = ngList[i + 1];
			var nNote = nextNG.visibleNotes[0];
			int nPitchLeftTrans = ((nNote.displayCents / 100) + (12 * leftTrans)).toInt();
			int nPitchRightTrans = ((nNote.displayCents / 100) + (12 * rightTrans)).toInt();

			if (cPitchLeftTrans < minPitch || cPitchLeftTrans > maxPitch) {
				break; //we've reached the end of notes that can be set to the left transposition
			}
			if (nPitchRightTrans < minPitch || nPitchRightTrans > maxPitch) {
				//this can't be the jumping point because the right note can't be transposed with the right transposition
				//it also means that any transition points found before this point are also invalid, because they would require notes that come after them to be
				//transposed into an unplayable range. Reset the score.
				bestTransitionScore = -10000;
				continue;
			}

			//calculate a score for the interval between the transposed current note and the untransposed next note
			int interval = (nPitchRightTrans - cPitchLeftTrans).abs();
			num newIntervalScore = 2.0 / (interval + 1); //larger intervals are worth fewer points. add a constant to guard against div by 0

			//jumps with a larger time gap are less damaging (and thus worth more points).
			//adjust the score for this return point based on the time between the notes and whether this return interval is smaller or larger than
			//the interval to the next note if we DON'T return at this point. Fast transitions between notes favor the smaller interval
			int alternateInterval =(nPitchLeftTrans - cPitchLeftTrans).abs(); //the interval we'll have if we don't return at this point
			newIntervalScore = 0.4 * (alternateInterval + 24) / (interval + 24);

			num qNoteDistance = (nextNG.qNoteTime - currentNG.qNoteTime).abs(); //the time gap between the starts of the notes
			num distanceFactor = math.pow(qNoteDistance, 0.33); //Cap the effect of the qNoteDistance
			newIntervalScore *= math.min(distanceFactor, 2);

			num newTransitionScore = newIntervalScore;

			//if the new return point is superior to the last found return point, set it as the new point to beat
			if (newTransitionScore >= bestTransitionScore) {
				//print('zeroTransBonus: $zeroTransBonus');
				bestTransitionIndex = i;
				bestTransitionScore = newTransitionScore;
			}

		}

		//print(bestTransitionScore);
		//we have our best transition point. Set notes before that (and including it) to the leftTrans value and notes to the right to the rightTrans value
		for (int i = leftIndex; i <= rightIndex; i++) {
			transpositionPoints[i] = (i <= bestTransitionIndex)? leftTrans : rightTrans;
			//transpositionPoints[i] = 0; //just a visual test to see notes untransposed
		}
	}

	bool get debug => _debug;
	void set debug(bool value) { _debug = value; }
}