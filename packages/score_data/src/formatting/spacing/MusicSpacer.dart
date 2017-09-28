part of score_data.formatting;

class MusicSpacer {
	Score _score;

	//spacing values (in tenths)
	num _qNoteWidth; //the space (in tenths) that would ordinarily be applied to a quarter note
	num _keySigWidth; //the amount of space to allow for a single accidental
	num _timeSigWidth; //the amount of space to allow for a time signature
	num _clefWidth; //the amount of space to allow for a clef at the beginning of a system
	num _clefDistanceFromBarline; //the amount of space between the clef and the barline as well as between the clef and key or time or note
	num _measureLeadIn; //the amount of space to have at the beginning of a measure before notes or other elements
	num _minMeasureWidth; //the minimum width of a measure
	num _noteheadWidth; //the width of a notehead
	//num; _graceNoteWidth //the width to award a grace note
	
	num _standardSystemWidth; //the width of a normal system (not the first one, which has an indent)
	
	//the ratio of the horizontal spacing requirement of one note to another note of half the first note's duration (a quarter 
			//gets X times as much space as an eighth note)
	//private static const SPACING_FACTOR:num = 1.6179; Golden Ratio
	static const num SPACING_FACTOR = 1.4179; 
	
	//private static const FIRST_SYSTEM_INDENT:num = 70; //extra indentation for the first system (in tenths)
	
	
	MusicSpacer(Score score) {
		_score = score;
		
		init();
	}
	
	void initializeScoreSettings(){
		//get music spacing values
		ScoreProperties sProps = _score.scoreProperties;
		_qNoteWidth = sProps.qNoteWidth;
		_keySigWidth = sProps.keySigWidth;
		_timeSigWidth = sProps.timeSigWidth;
		_clefWidth = sProps.clefWidth;
		_clefDistanceFromBarline = sProps.clefDistanceFromBarline;
		_measureLeadIn = sProps.measureLeadIn;
		_minMeasureWidth = sProps.minMeasureWidth;
		_noteheadWidth = sProps.noteheadWidth;

		
		//get the width of a normal system (not the first one, which has an indent)
		_standardSystemWidth = sProps.pageWidth - sProps.leftPageMargin - sProps.rightPageMargin - 
								sProps.leftSystemMargin - sProps.rightSystemMargin;
	}
	
	/**
	 * computes the ideal hPos for every note and the ideal width of each measure stack
	 * @param	measureStack the measureStack to compute - if null, all stacks in the score are computed
	 */
	void computeIdealSpacingValues([MeasureStack measureStack = null]) {
		if (measureStack != null) {
			computeIdealSpacingForStack(measureStack);
		}
		else {
			List<MeasureStack> stacks = _score.getMeasureStacks();
			for (var stack in stacks) {
				computeIdealSpacingForStack(stack);
			}
		}		
	}
	
	/**
	 * groups the measures into systems
	 * @param	measuresPerSystem if greater than 0, this number of measures will be enforced for all systems
	 */
	void groupMeasuresIntoSystems([int measuresPerSystem = 0]) {			
		List<System> systems = _score.getSystems();
		if (systems.length < 1) {
			return;
		}
		
		//make a record of the Stacks each system had from the previous render. In the end we'll compare the
		//new groupings to the old so that we can mark the systems that need to be rendered again.
		List<List<MeasureStack>> originalStackGroupings = new List<List<MeasureStack>>();

		//first put all of the measure stacks into the first system. We won't remove the other systems, as they may contain information we want to keep. But this
		//will simplify distribution.
		System firstSystem = systems[0];
		List<MeasureStack> firstSystemsStacks = systems[0].measureStacks;
		originalStackGroupings.add(firstSystemsStacks.sublist(0));
		System cSystem = null;
		for (int i = 1; i < systems.length; i++){
			cSystem = systems[i];
			List<MeasureStack> stacks = cSystem.measureStacks;
			originalStackGroupings.add(stacks.sublist(0));
			for (var stack in stacks){
				stack.systemRef = firstSystem;
				firstSystemsStacks.add(stack);
			}
			cSystem.clearAllStacks();
		}

		//now distribute the stacks
		int i = 0;
		while (i < systems.length) {
			cSystem = systems[i];
			num totalWidth = 0;
			for (int j = 0; j < cSystem.measureStacks.length; j++) {
				MeasureStack cStack = cSystem.measureStacks[j];
				if (j == 0) {//mark the first measure of each system as a new system stack
					cStack.newSystem = true;
					for (var measure in cStack.measures) {
						//measure.showClef = true; //the key and clef should show for every measure in the stack
						measure.showKey = true;
						measure.clefs[0].show = true;
						measure.clefs[0].smallSize = false;
					}

					//add in the width for the start of system clef and key
					if (!cStack.newKey){ //if this was true, then the value has already been accounted for in the stack's idealWidth
						totalWidth += cStack.maxKeySize * _keySigWidth;
					}
					if (!cStack.newClef){ //if this was true, then the value has already been accounted for in the stack's idealWidth
						totalWidth += _clefWidth;
					}
					
				}
				else {
					cStack.newSystem = false;
					for (var measure in cStack.measures) {
						//measure.showClef = cStack.newClef; //for measures that don't begin systems, clefs and keys should only be shown if they are new
						measure.clefs[0].show = measure.clefs[0].isNew;
						measure.clefs[0].smallSize = true;
						measure.showKey = cStack.newKey;
					}
				}
				
				totalWidth += cStack.idealWidth;
				if (measuresPerSystem > 0) { //if an exact number of measures per system is specified
					if (j >= measuresPerSystem) {
						if (cSystem.next == null) { //add a new system if we need it
							systems.add(addSystem(cSystem));
						}
						cSystem.next.insertMeasureStacks(cSystem.removeStacksFromEnd(cSystem.measureStacks.length - j)); //take the measures at the end of the current stack and insert them into the next one
						break; //go to the next system
					}
				}
				else if (j > 0 && totalWidth > (_standardSystemWidth - cSystem.indent) * 0.95) { //if the system is overfilled
					if (cSystem.next == null) { //add a new system if we need it
						systems.add(addSystem(cSystem));
					}
					cSystem.next.insertMeasureStacks(cSystem.removeStacksFromEnd(cSystem.measureStacks.length - j)); //take the measures at the end of the current stack and insert them into the next one
					break; //go to the next system
				}
				
				//okay, if we made it this far, we haven't necessarily reached the limit of # of measures this system can hold. Make sure we have another measure to check.
				if (j == cSystem.measureStacks.length - 1) { //if this is the last measure in the system...
					//pull one from the next system backwards
					if (cSystem.next != null) {
						cSystem.addMeasureStacks(cSystem.next.removeStacksFromBeginning(1));
					}						
				}
			}
			i++;
		}

		//remove any systems from the end that no longer have any MeasureStacks
		i--;
		while (cSystem.measureStacks.length == 0){
			Page cPage = cSystem.pageRef;
			cPage.removeSystem(cSystem);
			systems.removeLast();
			if (cPage.systems.length == 0){
				_score.removePage(cPage);
			}
			cSystem = cSystem.previous;
		}

		//now we have filled each system with as many measures as will fit easily, but this may have short changed the last system to have too few measures
		//go back through systems in reverse order and see if any measures would be better moved to the previous system
		//we'll keep going through them until the test finds no changes to make
		bool changeMade = (measuresPerSystem == 0); //don't do this if a specific number of measures per system was requested
		while(changeMade){
			changeMade = false;
			cSystem = systems[systems.length - 1];
			while (cSystem.previous != null){
				//go through each system and see if the last stack on the previous system would make more sense to put on the current system
				System prevSystem = cSystem.previous;
				MeasureStack qStack = prevSystem.measureStacks[prevSystem.measureStacks.length - 1]; //the stack we're thinking of moving from the previous system to the current
				while(prevSystem.requestedStackWidth - qStack.idealWidth > 0.95 * cSystem.requestedStackWidth){
					//while the previous system is fuller without that stack than the current system is currently (meaning the cSystem has greater need of it)
					//change the attributes of the current first stack of the cSystem so that it no longer is treated as such
					MeasureStack leadStack = cSystem.measureStacks[0];
					leadStack.newSystem = false;
					for (var measure in leadStack.measures) {
						//measure.showClef = leadStack.newClef; //the key and clef should show only if they are new
						measure.clefs[0].show = measure.clefs[0].isNew;
						measure.clefs[0].smallSize = true;
						measure.showKey = leadStack.newKey;
					}
					//insert the last stack from the previous system onto this system, changing its attributes to be a system leader stack
					cSystem.insertStack(prevSystem.removeStacksFromEnd(1)[0]);
					leadStack = cSystem.measureStacks[0];
					leadStack.newSystem = true;
					for (var measure in leadStack.measures) {
						//measure.showClef = true; //the key and clef should show for every measure in the stack
						measure.clefs[0].show = true;
						measure.clefs[0].smallSize = false;
						measure.showKey = true;
					}

					//make note of the fact that we have made a change so that we can have another pass
					changeMade = true;
				}

				cSystem = cSystem.previous; //prepare to check the previous system
			}
		}
		
		//now that we've placed all of our systems where they need to go, we can compare the new layout to the old
		//and figure out what actually needs to be rendered again
		int numNewSystems = systems.length;
		int numOriginalSystems = originalStackGroupings.length;
		for (int i = 0; i < numNewSystems; i++) {
			cSystem = systems[i];
			//first check to make sure this system even existed before:
			if (i >= numOriginalSystems) {
				cSystem.needsRendering = true;
				continue;
			}
			
			List<MeasureStack> newSystemStacks = cSystem.measureStacks;
			List<MeasureStack> oldSystemStacks = originalStackGroupings[i];
			if (oldSystemStacks.length == newSystemStacks.length) {
				//okay, the lengths matched... now see if the stacks are identical
				int numStacks = oldSystemStacks.length;
				for (int j = 0; j < numStacks; j++) {
					if (oldSystemStacks[j] != newSystemStacks[j]) {
						cSystem.needsRendering = true; //stack mismatch! force the re-render
						break;
					}
				}
			}
			else {
				//the number of stacks has changed - we definitely need to re-render
				cSystem.needsRendering = true;
			}
		}
	}
	
	System addSystem(System currentSystem) {
		System newSystem = new System(_score.scoreProperties);
		newSystem.previous = currentSystem;
		currentSystem.next = newSystem;
		currentSystem.pageRef.addSystem(newSystem);
		
		return newSystem;
	}
	
	/**
	 * computes the actual position values for the measures and notes of the System in preparation for rendering
	 * @param	system the system to calculate
	 */
	void computeActualSpacingValues(System system) {
		List<MeasureStack> stacks = system.measureStacks;
		int numStacks = stacks.length;
		if (numStacks == 0){
			return;
		}

		num sysWidth = _standardSystemWidth - system.indent;

		//calculate the expandable space - that is the space which does not include indent space at the beginning of each measure
		MeasureStack firstStack = stacks[0]; //the first stack will potentially have extra indent space counted since it starts a system
		num totalIndentSpace = firstStack.indentAsSystemLeader;
		num totalNoteIdealSpace = firstStack.idealWidth - firstStack.indent;
		for (int i = 1; i < numStacks; i++){
			MeasureStack stack = stacks[i];
			totalIndentSpace += stack.indent;
			totalNoteIdealSpace += stack.idealWidth - stack.indent;
		}
		
		

		//compute the necessary scale based on the requested space for the notes vs. the actual space the system provides for the notes
		num scale = (sysWidth - totalIndentSpace) / totalNoteIdealSpace;
		
		//multiply the ideal values for notes and measures by the scale factor to get actual position
		num hPos = 0;
		num stackIdealWidth;
		num stackIndent;
		for (int i = 0; i < numStacks; i++){
			MeasureStack stack = stacks[i];
			/*if (stack.noteGroups[0].numDots == 2) {
				trace('break here');
			}*/

			stack.startPosition = hPos; //the horizontal position of the left barline of the stack

			if (i == 0){ //for the first stack, we must use its indentAsSystemLeader indent value instead of its normal indent. This affects total width as well.
				stackIdealWidth = stack.idealWidth - stack.indent + stack.indentAsSystemLeader;
				stackIndent = stack.indentAsSystemLeader;
			}
			else {
				stackIdealWidth = stack.idealWidth;
				stackIndent = stack.indent;
			}

			//we only want to scale the portion of the measure that comes after the indent (only the part that contains the notes)
			num newWidth = (stackIdealWidth - stackIndent) * scale + stackIndent;
			stack.width = newWidth;
			for (var ng in stack.noteGroups) {
				if (ng.visible == false){
					ng.hPos = stackIndent;
					continue;
				}
				if (ng.isRest && ng.voice.noteGroups.length == 1){ //if it's a single rest in the measure, we must center it
					ng.hPos = (newWidth + stackIndent - _measureLeadIn) / 2;
				}
				else {
					ng.hPos = (ng.idealHPos + stackIndent - stackIndent) * scale + stackIndent; //remove the indent before multiplying by the scale factor, then add it back in
				}
			}

			//update the position for the next stack
			hPos += stack.width;
		}
	}
	
	void init() {
		initializeScoreSettings();
	}
	
	
	
	/**
	 * computes the ideal position of each note group and the ideal width of the measure stack
	 * @param	stack the MeasureStack to compute
	 */
	void computeIdealSpacingForStack(MeasureStack stack) {
		num cTime = (stack.noteGroups.length > 0)? stack.noteGroups[0].qNoteTime : stack.startTime;
		num cPosition = 0;
		
		num clefDFB = _score.scoreProperties.clefDistanceFromBarline;
		
		//compute the required minimum lead in measure space for this stack, regardless of its position in the system
		stack.indent = _measureLeadIn;
		if (stack.newClef) { //add space for the beginning-of-measure clef
			stack.indent += _clefWidth + clefDFB;
		}
		if (stack.newKey) { //add space for the key sig
			stack.indent += stack.maxKeySize * _keySigWidth + clefDFB;
		}
		bool showTime = stack.measures[0].showTime;
		if (showTime) { //add space for the time sig
			stack.indent += _timeSigWidth + clefDFB;
		}

		//now also compute the required lead in for this stack if it happens to fall at the beginning of the system (where clef and key are mandatory)
		stack.indentAsSystemLeader = _measureLeadIn + _clefWidth + clefDFB;
		if (stack.maxKeySize > 0) {
			stack.indentAsSystemLeader += (stack.maxKeySize * _keySigWidth) + clefDFB;
		}
		if (showTime) { //add space for the time sig
			stack.indentAsSystemLeader += _timeSigWidth + clefDFB;
		}
		
		//print('${stack.indent}, ${stack.indentAsSystemLeader}');
		//check for repeat signs
		num repeatSpaceAtEnd = 0;
		if (stack.repeatDOs != null){
			for (var rdo in stack.repeatDOs){
				if (rdo.repeatDirection == RepeatDirection.FORWARD){
					stack.indent += _measureLeadIn;
					stack.indentAsSystemLeader += _measureLeadIn;
				}
				else if (rdo.repeatDirection == RepeatDirection.BACKWARD){
					repeatSpaceAtEnd = _measureLeadIn;
				}
			}
		}
		
		
		cPosition = 0;

		//compute the position of each note. We need to consider that some notes might have dots or accidentals and require a minimum amount of space.
		//Notes at the same time position must be aligned, and so we have to consider the minimum space requirement of the "fattest" note at a given
		//position. At each position, we'll measure the size of the noteGroup, see if it's the biggest, and put it in a list of notes at that position.
		//when we've moved onto the next position, we'll check that the space we allowed for each note at the previous position >= to that minimum requirement.
		
		num NORMAL_MIN_WHITE_SPACE = _noteheadWidth * 1.3;
		num LYRIC_LETTER_SPACE = 0.9 * _noteheadWidth;
		
		num newTimePositionDelta = 0; //the margin between the current notes and notes at the previous time solely based on the time between them.
		
		num firstNoteTime = cTime; //the qnote time of the first note in the measure - usually matches stack start time, but grace notes can come earlier.
		List<NoteGroup> notesAtCurrentPos = new List<NoteGroup>();
		num largestLeftExtension = 0; //left margin extension for noteGroups at current time
		num largestRightExtension = 0; //right margin extension for noteGroups at current time
		num prevRightExtension = 0; //right margin extension for noteGroups at previous time
		
		num minWhiteSpace;
		
		List<NoteGroup> noteGroups = stack.noteGroups;
		int numNoteGroups = noteGroups.length;
		for (int i = 0; i < numNoteGroups; i++){
			NoteGroup ng = noteGroups[i];
			
			if (ng.visible == false){
				//don't include invisible entries in spacing
				continue;
			}
			
			/*if (ng.isGrace) {
				trace("here");
			}*/
			
			//compute the left and right margin needed for this ng
			num ngLeftExtension = ng.numAccidentalLevels * _noteheadWidth;
			if (ngLeftExtension > 0 && ng.qNoteTime == stack.startTime){
				//experiment 3/8/2015 - special case accidentals at beginning of measure
				//to let them eat into the lead-in
				ngLeftExtension -= _measureLeadIn / 2;
			}
			num ngRightExtension = 0;
			if (ng.clef != null){
				ngLeftExtension += _clefWidth + _clefDistanceFromBarline;
			}
			if (ng.lyric != null) {
				num halfLyricWidth = ng.lyric.text.length * LYRIC_LETTER_SPACE / 2 - _noteheadWidth / 2;
				ngRightExtension += halfLyricWidth;
//				if (halfLyricWidth > ngLeftExtension) {
//					ngLeftExtension = halfLyricWidth;
//				}
				//experiment 3/8/2015
				if (ng.qNoteTime != stack.startTime){
					//original behavior
					if (halfLyricWidth > ngLeftExtension) {
						ngLeftExtension = halfLyricWidth;
					}
				}
				else {
					//special case the beginning of the bar - let the lyric eat through the measure lead-in
					if (halfLyricWidth - _measureLeadIn > ngLeftExtension) {
    					ngLeftExtension = halfLyricWidth - _measureLeadIn;
    				}
				}
				
			}

			//allow extra space for notes with flags
			//experiment 3/8/2015 - added BeamState.NONE check as well as checking for up stem
			if (!ng.isRest && (ng.beamStates.length == 0 || ng.beamStates[0] == BeamState.NONE) && 
						ng.duration < 1024 && ngRightExtension < 0.5 * _noteheadWidth &&
						ng.stemDirection == StemDirection.UP) {
				ngRightExtension = 0.5 * _noteheadWidth;
			}
			
			if (ng.qNoteTime > cTime) {
				if (notesAtCurrentPos.length > 0) {
					//process the notes at the previous time
					//check to see if the default newTimePositionDelta gave enough room to accommodate their largest left margin
					//as well as the right margin of the previous noteGroups. 
					minWhiteSpace = (cTime > firstNoteTime)? NORMAL_MIN_WHITE_SPACE : 0; //no whitespace margin at beginning - measure lead in takes care of that
					if (newTimePositionDelta - largestLeftExtension - prevRightExtension < minWhiteSpace) {
						cPosition += minWhiteSpace - (newTimePositionDelta - largestLeftExtension - prevRightExtension);
						for (var previousNG in notesAtCurrentPos) {
							previousNG.idealHPos = cPosition;
						}
					}
					prevRightExtension = largestRightExtension;
				}
				
				//reset the min note width and notes list
				notesAtCurrentPos = [ng];
				largestLeftExtension = ngLeftExtension; //the first note at the new position sets the initial min space value
				largestRightExtension = ngRightExtension; //the first note at the new position sets the initial min space value
				
				//compute the new position (based on duration distance from previous position)
				newTimePositionDelta = (_qNoteWidth * math.pow(SPACING_FACTOR, math.log(ng.qNoteTime - cTime) / math.log(2)));
				
				cPosition += newTimePositionDelta;
				cTime = ng.qNoteTime;
				
			}
			else {
				//keep track of all of the notes at the current position. We may need to loop through them if we discover a minimum space hasn't been met
				notesAtCurrentPos.add(ng); 
				
				//check if this notegroup's spacing requirement is the largest we've seen at this time, and if so, update the min space requirement for this position
				if (ngLeftExtension > largestLeftExtension) {
					largestLeftExtension = ngLeftExtension;
				}
				if (ngRightExtension > largestRightExtension) {
					largestRightExtension = ngRightExtension;
				}
			}
			
			ng.idealHPos = cPosition; //we may change later, but initialize the position to default now.
			
//			if (ng.qNoteTime == stack.startTime){
//				print('time: ${stack.startTime} idealHPos: ${ng.idealHPos} ' + 
//						' leftExt: $ngLeftExtension  rightExt: $ngRightExtension');
//			}
		}
		
		//the last note(s) in the stack haven't had the chance to override the default spacing
		if (notesAtCurrentPos.length > 0) {
			//process the notes at the previous time
			//check to see if the default newTimePositionDelta gave enough room to accommodate their largest left margin
			//as well as the right margin of the previous noteGroups.
			minWhiteSpace = (cTime > firstNoteTime)? NORMAL_MIN_WHITE_SPACE : 0; //no whitespace margin at beginning - measure lead in takes care of that
			if (newTimePositionDelta - largestLeftExtension - prevRightExtension < minWhiteSpace) {
				cPosition += minWhiteSpace - (newTimePositionDelta - largestLeftExtension - prevRightExtension);
				for (var previousNG in notesAtCurrentPos) {
					previousNG.idealHPos = cPosition;
				}
			}
		}
		
		//compute the ideal width of the measure stack
		if (stack.endTime > cTime) { //this should always be the case
			//compute the space at the end of the measure, based on the time of the end of the measure vs. the start of the last note.
			num endSpace = repeatSpaceAtEnd + (_qNoteWidth * math.pow(SPACING_FACTOR, 
			                math.log(stack.endTime - cTime) / math.log(2)));
			//if that space is smaller than the right margin requirement of the last notegroup, update it
			if (endSpace < largestRightExtension) {
				endSpace = largestRightExtension;
			}
			stack.idealWidth = stack.indent + cPosition + endSpace;
		}
		else {
			stack.idealWidth = (cPosition + stack.indent > _minMeasureWidth)? cPosition + stack.indent : _minMeasureWidth;
			print("probably shouldn't get here... MusicSpacer.computeIdealSpacingForStack()");
		}
	}
	
	
}