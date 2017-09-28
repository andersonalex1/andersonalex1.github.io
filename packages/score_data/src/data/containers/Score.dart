part of score_data.data;

class Score extends BaseDataObject {

	ScoreProperties _scoreProperties;
	
	List<Part> _parts = []; //contains Part objects (container hierarchy: Parts >> Staves >> Measures >> Voices >> NoteGroups >> Notes)
	
	List<Page> _pages = []; //contains the Page objects (container hierarchy: Pages >> Systems >> MeasureStacks)

	bool _graceNotesNeedFixing = false; //true when grace notes have not been offset properly (MusicXML files don't have them positioned)
	
	///contains a list of qNoteTimes in from/to pairings. If no repeats exist, this will be 
	///from 0 to the qNoteTime of the end of the song.
	List<num> playbackPath;
	
	Score() {
		
	}
	
	/**
	 * adds the Part
	 * @param	part a Part object
	 */
	void addPart(Part part) {
		_parts.add(part);
	}
	
	/**
	 * adds the Page
	 * @param	page a Page object
	 */
	void addPage(Page page) {
		if (_pages.length > 0) {
			Page prevPage = _pages[_pages.length - 1];
			prevPage.next = page;
			page.previous = prevPage;
		}
		_pages.add(page);			
	}
	
	/**
	 * gets all of the System objects found in the score (looks through each page)
	 * @return a list of System objects
	 */
	List<System> getSystems() {
		//int counter = 0;
		List<System> systems = [];
		for (var page in _pages) {
			for (var system in page.systems) {
				systems.add(system);
				//counter++;
			}
		}
		return systems;
	}
	
	/**
	 * gets all of the MeasureStack objects found in the score (looks through each page and system
	 * @return a list of MeasureStack objects
	 */
	List<MeasureStack> getMeasureStacks() {
		//int counter = 0;
		List<MeasureStack> stacks = [];
		for (var page in _pages) {
			for (var system in page.systems) {
				for (var stack in system.measureStacks){
					stacks.add(stack);
					//counter++;
				}
			}
		}
		return stacks;
	}
	
	/**
	 * gets the dpq position for every beat in the score, returning them in an array and also writing them to the MeasureStack objects
	 * @return a list of the dpq positions
	 */
	List<num> getBeatDPQPositions() {
		List<num> allBeatDPQPositions = [];
		int totalBeats = 0;
		
		List<MeasureStack> stacks = getMeasureStacks();
		for (var stack in stacks) {
			Measure measure = stack.measures[0];
			int numBeats = measure.numBeats;
			int numBigBeats = 0; //the number of real beats in the measure (doesn't include sub division beats in compound meters)
			List<num> beatDPQPositions = [];
			for (int i = 0; i < numBeats; i++) {
				//in compound meters, we only return the first of every 3 beats.
				if (measure.beatType == 8 || measure.beatType == 16) {
					if (i % 3 == 0) {
						num position = i * (4 / measure.beatType) + stack.startTime;
						beatDPQPositions[numBigBeats] = position;
						allBeatDPQPositions[totalBeats] = position;
						totalBeats++;
						numBigBeats++;
					}
				}
				else {
					num position = i * (4 / measure.beatType) + stack.startTime;
					beatDPQPositions[numBigBeats] = position;
					allBeatDPQPositions[totalBeats] = position;
					totalBeats++;
					numBigBeats++;
				}					
			}
			stack.beatQNotePositions = beatDPQPositions;
		}
		
		return allBeatDPQPositions;
	}

	/**
	 * removes the Page from the Score. The Page MUST have no remaining Systems for this to go through
	 * @param page the empty Page to remove
	 */
	void removePage(Page page) {
		if (page.systems.length == 0){
			for (int i = _pages.length - 1; i >= 0; i--){
				if (_pages[i] == page){
					if (i > 0 && _pages[i - 1].next == page){
						_pages[i - 1].next = (i < _pages.length - 1)? _pages[i + 1] : null;
					}
					if (i < _pages.length - 1 && _pages[i + 1].previous == page){
						_pages[i + 1].previous = (i > 0)? _pages[i - 1] : null;
					}
					_pages.removeAt(i);
					return;
				}
			}
		}
		else {
			print("Attempted to remove a Page that still contains Systems!");
		}
	}
	
	void setPageSize(num pageWidth, num pageHeight){
		_scoreProperties.pageWidth = pageWidth;
		_scoreProperties.pageHeight = pageHeight;
		var systems = getSystems();
		for (var sys in systems){
			sys.getSettingsFromScoreProperties();
		}
	}
	
	void updatePlaybackPath(){
		var stacks = getMeasureStacks();
		
		//create a pass counter map for each MeasureStack to keep track of how many times it has been reached
		Map<MeasureStack, int> passMap = {};
		for (var stack in stacks){
			if (stack.repeatDOs != null){
				passMap[stack] = 0;
			}
		}
		
		playbackPath = [];
		
		//begin recursive calls to create the playback path pairs
		_createPlaybackPathPair(stacks, passMap, 0);
	}
	
	void _createPlaybackPathPair(List<MeasureStack> stacks, Map<MeasureStack, int> passMap, int startIndex){
		//go forward through the stacks and look for any repeat markers
		int lastForwardRepeatIndex;
		for (int i = startIndex; i < stacks.length; i++){
			var stack = stacks[i];
			if (stack.repeatDOs != null){
				passMap[stack]++;
				for (var rdo in stack.repeatDOs){
					
					if (rdo.repeatDirection == RepeatDirection.FORWARD){
						//keep track of most recent forward repeat sign
						lastForwardRepeatIndex = i;
					}
					if (rdo.repeatDirection == RepeatDirection.BACKWARD && passMap[stack] <= rdo.repeatTimes){
						//we'll need to jump back - if we don't already have a forward repeat, look backwards for one
						if (lastForwardRepeatIndex == null){
							lastForwardRepeatIndex = _findPrecedingForwardRepeat(stacks, startIndex - 1);
						}
						//add the playback path entry
						playbackPath.add(stacks[startIndex].startTime);
						playbackPath.add(stack.endTime);
						
						//jump back and call the routine again
						_createPlaybackPathPair(stacks, passMap, lastForwardRepeatIndex);
						return;
					}
					if (rdo.endingType == EndingType.START && rdo.endingNumber.indexOf("1") != -1){
						//beginning (and maybe also end) of a first ending. We don't process other endings, because
						//the # of passes for the start of the first ending is used to select which ending we jump to.
						//choose the ending we should jump to (or determine we should stay in the first ending)
						int endingTargetIndex = _chooseEnding(stacks, passMap, i);
						if (endingTargetIndex != i){
							//add the playback path entry
							playbackPath.add(stacks[startIndex].startTime);
                            playbackPath.add(stack.startTime); //we don't actually play this bar
                            
							//jump forward and call the routine again
							_createPlaybackPathPair(stacks, passMap, endingTargetIndex);
							return;
						}
					}
				}
			}
		}
		
		//okay, we made it to the end without finding any required jumps. Create the playback path and we're done.
		playbackPath.add(stacks[startIndex].startTime);
        playbackPath.add(stacks.last.endTime);
	}
	
	int _findPrecedingForwardRepeat(List<MeasureStack> stacks, int startIndex){
		for (int i = startIndex; i >= 0; i--){
			var stack = stacks[i];
			if (stack.repeatDOs != null){
				for (var rdo in stack.repeatDOs){
					if (rdo.repeatDirection == RepeatDirection.FORWARD){
						return i;
					}
				}
			}
		}
		return 0;
	}
	
	int _chooseEnding(List<MeasureStack> stacks, Map<MeasureStack, int> passMap, int startIndex){
		//get the number of the ending we should be looking for. This will be the pass # of the stack
		//containing the start of the first-ending. (on the first pass (pass #1) we stick with the first
		//ending... on the second pass (pass #2) we jump to the second ending, etc.)
		String endingTargetNum = passMap[stacks[startIndex]].toString();
		int lastEndingCloseIndex;
		for (int i = startIndex; i < stacks.length; i++){
			var stack = stacks[i];
			if (stack.repeatDOs != null){
				for (var rdo in stack.repeatDOs){
					if (rdo.endingType == EndingType.START){
						if (rdo.endingNumber != null && rdo.endingNumber.indexOf(endingTargetNum) != -1){
							//we found the ending with the target number text
							return i;
						}
						lastEndingCloseIndex = null;
					}
					else if (rdo.endingType == EndingType.DISCONTINUE || rdo.endingType == EndingType.STOP){
						lastEndingCloseIndex = i;
					}
				}
				if (lastEndingCloseIndex != null && lastEndingCloseIndex < i){
					//we found an ending close in the previous measure, and the current measure didn't start a new
					//ending. This situation could happen if the user created a score with a first
					//ending but never marked the second ending. We essentially treat the first bar after the
					//first ending as the intended second ending
					return i;
				}
			}
		}
		//we didn't find a suitable target. Just return the original measure
		return startIndex;
	}
	
	
	ScoreProperties get scoreProperties { return _scoreProperties; }		
	void set scoreProperties(ScoreProperties value) { _scoreProperties = value;	}
	
	List<Part> get parts { return _parts; }
	
	List<Page> get pages {	return _pages; }
	


	/**
	 * true when grace notes have not been offset properly (MusicXML files don't have them positioned)
	 */
	bool get graceNotesNeedFixing { return _graceNotesNeedFixing; }
	void set graceNotesNeedFixing(bool value) { _graceNotesNeedFixing = value; }
}
