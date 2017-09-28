part of score_data.data;

class System extends BaseDataObject {

	ScoreProperties _scoreProps;
	
	num _indent = 0; //the amount to indent the system, in tenths.
	num _systemWidth; //width of the system, in tenths

	num _staffSpacing; //default space between staves
	num _staffLineSpacing; //default space between staff lines
	List<num> _staffVPosOffsets = []; //vertical offset positions of the staves in the system (in tenths) (0 is default position)
	List<Part> _visibleParts; //the parts that are visible in this system
	
	List<MeasureStack> _measureStacks = [];
	
	System _previous; //the previous System
	System _next; //the next System
	
	Page _pageRef; //the containing page

	bool _newPage = false; //set to true if this system starts a new page

	bool _needsRendering = true; //set to true in order to force re-rendering of system on next render

	List<SlurSegment> _slurSegments; //list of SlurSegments that should be rendered for this system
	
	System(ScoreProperties scoreProps) {
		_scoreProps = scoreProps;
		init();
	}

	void init() {
		getSettingsFromScoreProperties();
	}
	
	void getSettingsFromScoreProperties(){
		_systemWidth = _scoreProps.pageWidth - _scoreProps.leftPageMargin - _scoreProps.rightPageMargin  - 
						_scoreProps.leftSystemMargin - _scoreProps.rightSystemMargin;
		_staffSpacing = _scoreProps.staffSpacing;
		_staffLineSpacing = _scoreProps.staffLineSpacing;
	}
	
	/**
	 * adds a single MeasureStack
	 * @param	stack the MeasureStack object to add
	 * @param	linkStacksBetweenSystems if true, the stacks in this system will be linked with the stacks in the surrounding systems (prev and next properties)
	 */
	void addMeasureStack(MeasureStack stack, [bool linkStacksBetweenSystems = true]) {
		stack.systemRef = this;
		if (_measureStacks.length > 0) {
			MeasureStack prevStack = _measureStacks[_measureStacks.length - 1];
			prevStack.next = stack;
			stack.previous = prevStack;
		}
		_measureStacks.add(stack);

		if (linkStacksBetweenSystems){
			linkStacksInSurroundingSystems();
		}
	}
	
	/**
	 * adds one or more MeasureStack objects
	 * @param	stacks a list of MeasureStack objects
	 * @param	linkStacksBetweenSystems if true, the stacks in this system will be linked with the stacks in the surrounding systems (prev and next properties)
	 */
	void addMeasureStacks(List<MeasureStack> stacks, [bool linkStacksBetweenSystems = true]) {
		MeasureStack prevStack;
		if (_measureStacks.length > 0) {
			prevStack = _measureStacks[_measureStacks.length - 1];
		}
		for (var stack in stacks) {
			stack.systemRef = this;
			prevStack.next = stack;
			stack.previous = prevStack;
			
			_measureStacks.add(stack);
			
			prevStack = stack;
		}

		if (linkStacksBetweenSystems){
			linkStacksInSurroundingSystems();
		}
	}
	
	/**
	 * inserts a single MeasureStack at the beginning of the system
	 * @param	stack the MeasureStack to insert
	 * @param	linkStacksBetweenSystems if true, the stacks in this system will be linked with the stacks in the surrounding systems (prev and next properties)
	 */
	void insertStack(MeasureStack stack, [bool linkStacksBetweenSystems = true]) {
		stack.systemRef = this;
		_measureStacks.insert(0, stack);
		if (_measureStacks.length > 1){
			MeasureStack nextStack = _measureStacks[1];
			nextStack.previous = stack;
			stack.next = nextStack;
		}

		if (linkStacksBetweenSystems){
			linkStacksInSurroundingSystems();
		}
	}
	
	/**
	 * inserts one or more MeasureStack objects at the beginning of the system, retaining their order
	 * @param	stacks a list of MeasureStack objects
	 * @param	linkStacksBetweenSystems if true, the stacks in this system will be linked with the stacks in the surrounding systems (prev and next properties)
	 */
	void insertMeasureStacks(List<MeasureStack> stacks, [bool linkStacksBetweenSystems = true]) {
		int index = 0;
		for (var stack in stacks) {
			stack.systemRef = this;
			_measureStacks.insert(index, stack);

			if (index > 0){
				MeasureStack prevStack = _measureStacks[index - 1];
				prevStack.next = stack;
				stack.previous = prevStack;
			}
			if (index < _measureStacks.length - 1){
				MeasureStack nextStack = _measureStacks[index + 1];
				nextStack.previous = stack;
				stack.next = nextStack;
			}

			index++;
		}

		if (linkStacksBetweenSystems){
			linkStacksInSurroundingSystems();
		}
	}
	
	/**
	 * removes the specified number of stacks from the front of the system and returns them as a list
	 * @param	count the number of stacks to remove. If less than or equal to 0, all of the stacks are removed.
	 * @return	the list of MeasureStacks that was removed
	 */
	List<MeasureStack> removeStacksFromBeginning(int count) {
		if (count >= _measureStacks.length || count <= 0){
			count = _measureStacks.length;
		}
		List<MeasureStack> removedStacks = _measureStacks.sublist(0, count);
		_measureStacks.removeRange(0, count);
		return removedStacks;
	}
	
	/**
	 * removes the specified number of stacks from the end of the system and returns them as a list
	 * @param	count the number of stacks to remove. If less than or equal to 0, all of the stacks are removed.
	 * @return	the list of MeasureStacks that was removed
	 */
	List<MeasureStack> removeStacksFromEnd(int count) {
		if (count >= _measureStacks.length || count <= 0) {
			count = _measureStacks.length;
		}
		List<MeasureStack> removedStacks = _measureStacks.sublist(_measureStacks.length - count, _measureStacks.length);
		_measureStacks.removeRange(_measureStacks.length - count, _measureStacks.length);
		return removedStacks;
	}
	
	/**
	 * adds the new stack directly after an existing stack (used to insert the stack in the middle of other stacks)
	 * @param	newStack the Stack to insert
	 * @param	stackToFollow the Stack to find and insert the new Stack after
	 * @param	linkStacksBetweenSystems if true, the stacks in this system will be linked with the stacks in the surrounding systems (prev and next properties)
	 * @return	returns true if the stackToFollow is found and the newStack is added
	 */
	bool addStackAfterExistingStack(MeasureStack newStack, MeasureStack stackToFollow, [bool linkStacksBetweenSystems = true]) {
		int numStacks = _measureStacks.length;
		for (int i = 0; i < numStacks; i++) {
			if (_measureStacks[i] == stackToFollow) {
				//link the new stack and the previous stack and give the new stack a reference to this system
				stackToFollow.next = newStack;
				newStack.previous = stackToFollow;
				newStack.systemRef = this;
				
				//check to see if there is a following stack
				if (i + 1 < numStacks) {
					MeasureStack nextStack = _measureStacks[i + 1];
					nextStack.previous = newStack;
					newStack.next = nextStack;
				}
				
				//insert the new stack
				_measureStacks.insert(i + 1, newStack);

				if (linkStacksBetweenSystems){
					linkStacksInSurroundingSystems();
				}

				return true;
			}
		}
		
		return false;
	}

	/**
	 * removes the MeasureStack at the requested index and recreates the MeasureStack links
	 * @param index the index of the stack to remove
	 */
	void removeStack(MeasureStack stack) {
		int index = _measureStacks.indexOf(stack);
		if (index == -1){
			return;
		}

		_measureStacks.removeAt(index);

		if (index == 0 || index == _measureStacks.length){
			linkStacksInSurroundingSystems();
		}
		else {
			_measureStacks[index - 1].next = _measureStacks[index];
			_measureStacks[index].previous = _measureStacks[index - 1];
		}
	}
	
	bool attemptStackDonation() {
		return false;
	}

	/**
	 * clears all MeasureStacks objects from the System. It does NOT modify the references in the MeasureStack objects,
	 * so they will still refer to this System as their owner and refer to surrounding Stacks as next and previous
	 */
	void clearAllStacks() {
		_measureStacks = [];
	}


	/**
	 * links the first stack of this system with the last stack of the previous system and links the last stack
	 * in this system with the first stack in the next system (assuming the surrounding systems exist)
	 */
	void linkStacksInSurroundingSystems() {
		if (_measureStacks.length <= 0){
			return;
		}

		MeasureStack firstStack = _measureStacks[0];
		MeasureStack lastStack = _measureStacks[_measureStacks.length - 1];

		/*if (firstStack.number == 12){
			trace("okay...");
		}*/

		//link the first stack with the last stack of the previous system
		System prevSystem = this.previous;
		if (prevSystem == null){
			firstStack.previous = null;
		}
		while (prevSystem != null){
			if (prevSystem.measureStacks.length > 0){
				MeasureStack prevStack = prevSystem.measureStacks[prevSystem.measureStacks.length - 1];
				prevStack.next = firstStack;
				firstStack.previous = prevStack;
				break;
			}
			prevSystem = prevSystem.previous;
		}

		//link the last stack with the first stack of the next system
		System nextSystem = this.next;
		if (nextSystem == null){
			lastStack.next = null;
		}
		while (nextSystem != null){
			if (nextSystem.measureStacks.length > 0){
				MeasureStack nextStack = nextSystem.measureStacks[0];
				nextStack.previous = lastStack;
				lastStack.next = nextStack;
				break;
			}
			nextSystem = nextSystem.next;
		}
	}


	
	/**
	 * returns the sum of the idealWidths of the measure stacks currently in the system (regardless of what the system's width is)
	 */
	num get requestedStackWidth {
		if (_measureStacks.length == 0) {
			return 0;
		}
		
		num totalWidth = 0;
		for (var stack in _measureStacks) {
			totalWidth += stack.idealWidth;
		}
		return totalWidth;
	}
	
	List<MeasureStack> get measureStacks { return _measureStacks; }
	
	num get indent { return _indent; }
	void set indent(num value) { _indent = value; }

	/**
	 * width of the system, in tenths
	 */
	num get systemWidth { return _systemWidth;	}
	void set systemWidth(num value) { _systemWidth = value; }


	/**
	 * default space between staves, in tenths
	 */
	num get staffSpacing {	return _staffSpacing; }
	void set staffSpacing(num value) { _staffSpacing = value; }

	/**
	 * default space between staff lines, in tenths
	 */
	num get staffLineSpacing { return _staffLineSpacing; }
	void set staffLineSpacing(num value) { _staffLineSpacing = value; }

	/**
	 * returns a list of the vertical offsets from default positions (in tenths)
	 * of all staves in the system - for any that haven't previously been set, it
	 * sets the offset to 0. We use this system instead of returning exact values
	 * to account for scores being rendered with only some parts present
	 */
	List<num> get staffVPosOffsets {
		if (_measureStacks.length == 0){
			return []; //check for the case where no measures have been added to this system
		}


		int staffIndex = _staffVPosOffsets.length;
		int numStaves = _measureStacks[0].measures.length;
		
		//first make sure we don't have more staffVPosOffsets than staves
		if (staffIndex > numStaves){
			//_staffVPosOffsets.removeRange(numStaves, numStaves + staffIndex);
			_staffVPosOffsets.removeRange(numStaves, staffIndex); //changed on 11/7/2016
			staffIndex = _staffVPosOffsets.length;
		}

		//then add any missing staffVPosOffsets so that we have one per staff
		while (staffIndex < numStaves){
			if (staffIndex >= _staffVPosOffsets.length){
				_staffVPosOffsets.add(0);
			}
			else {
				_staffVPosOffsets[staffIndex] = 0;
			}
			
			staffIndex++;
		}



		return _staffVPosOffsets;
	}
	void set staffVPosOffsets(List<num> value) { _staffVPosOffsets = value; }

	/**
	 * returns a list of the staff barline groupings according to the number of
	 * staves in each part. Ex. [1, 1, 1, 2] for flute, oboe, bassoon, piano
	 * Only returns groupings for visible parts and staves.
	 */
	List<int> get staffGroupings {
		if (_measureStacks.length == 0){
			return []; //check for the case where no measures have been added to this system
		}

		List<int> groupings = [];

		MeasureStack stack = _measureStacks[0];
		List<Measure> measures = stack.measures;
		int numMeasures = measures.length;
		int measureIndex = 0;
		while (measureIndex < numMeasures) {
			Measure measure = measures[measureIndex];
			int numVisibleStaves = 0;
			for (var staff in measure.staff.partRef.staves){
				if (staff.visible) numVisibleStaves++;
			}
			int numStaves = measure.staff.partRef.staves.length;
			if (_visibleParts.indexOf(measure.staff.partRef) != -1){
				//groupings.add(numStaves);
				groupings.add(numVisibleStaves);
			}
			measureIndex += numStaves;
		}

		return groupings;
	}

	/**
	 * the parts that are visible in this system
	 */
	List<Part> get visibleParts { return _visibleParts; }
	void set visibleParts(List<Part> value) { _visibleParts = value; }
	
	System get previous { return _previous; }	
	void set previous(System value) { _previous = value; }
	
	System get next { return _next; }		
	void set next(System value) { _next = value; }
	
	Page get pageRef { return _pageRef; }		
	void set pageRef(Page value) { _pageRef = value; }


	/**
	 * set to true if this system starts a new page
	 */
	bool get newPage { return _newPage; }
	void set newPage(bool value) { _newPage = value;	}


	/**
	 * set to true in order to force re-rendering of system on next render
	 */
	bool get needsRendering { return _needsRendering; }
	void set needsRendering(bool value) { _needsRendering = value; }


	/**
	 * list of SlurSegments that should be rendered for this system
	 */
	List<SlurSegment> get slurSegments { return _slurSegments; }
	void set slurSegments(List<SlurSegment> value) { _slurSegments = value; }
}

