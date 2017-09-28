part of score_data.data;

class MeasureStack extends BaseDataObject {

	List<NoteGroup> _noteGroups = []; //all of the NoteGroup objects in the stack
	List<Measure> _measures = []; //all of the Measure objects in the stack
	
	////////////DPQ TIME MARKERS//////////
	num _startTime = 0.0; //the start time of the measure stack, in dpq
	num _endTime = 0.0; //the end time of the measure stack, in dpq
	num _dpqLength = 0.0; //the length of the measure stack, in dpq
	//the dpq position of each beat in the measure - similar to the startTime property for NoteGroups, 
	//this is used by Performer objects to know when beats have occurred.
	List<num> _beatQNotePositions;
	
	
	bool _newSystem = false; //begins a new system
			
	num _width = 200; //actual width of the measure
	num _indent = 0; //the indentation before the music - for keys, clefs, time sig, and standard offset. This doesn't scale with measure width when calculating actual positions.
	num _indentAsSystemLeader = 0; //the indentation before the music if this stack happens to be the first stack in its system (clef and key are required)
	num _startPosition = 0; //distance from the left edge of the system to the beginning of this measure
	int _number = 1; //the measure number
	
	
	//////////SPACING CONSIDERATION VALUES//////////////
	num _idealWidth = 0; //the amount of horizontal space the stack would consume if no other stacks or factors had to be considered
	int _maxKeySize = 0; //the highest number of sharps or flats any measure within the stack has (to account for transposing staves with differing key sigs)
	bool _newKey = false; //set to true if there is a new key in the bar that must be shown, regardless of whether this measure is first in a system.
	//bool _newTime = false; //set to true if there is a new time sig in the bar that must be shown, regardless of whether this measure is first in a system.
	bool _newClef = false; //set to true if there is a new clef in the bar that must be shown, regardless of whether this measure is first in a system.

	//Stack Attachments
	List<TempoMarker> _tempoMarkers; //holds list of TempoMarker objects that take effect starting with this stack
	
	Barline barline;
	///contains info about any repeat related objects for this stack (endings, repeat signs, repeat text)
	List<RepeatDO> repeatDOs;
	
	MeasureStack _previous; //the previous MeasureStack;
	MeasureStack _next; //the next MeasureStack;
	
	System _systemRef; //the containing System

	bool _isPickup = false; //true if the stack is a pickup measure stack

	bool _needsRendering = true; //true if there is at least one Measure in the stack that needs to be rendered again
	
	MeasureStack() {
		
	}
	
	/**
	 * adds the NoteGroup object to the stack in order by its time
	 * @param	noteGroup the NoteGroup to add - must have its startTime property set.
	 */
	void addNoteGroup(NoteGroup noteGroup) {
		int numNotes = _noteGroups.length;
		int i = 0;
		for (i = 0; i < numNotes; i++) {
			NoteGroup cNoteGroup = _noteGroups[i];
			if (noteGroup.qNoteTime < cNoteGroup.qNoteTime) {
				//insert the new note just before the note that comes after it in time (but after all notes that had the same time)
				_noteGroups.insert(i, noteGroup);
				return;
			}
		}
		
		//we haven't added the new note yet, so it came at the end.
		_noteGroups.add(noteGroup);
	}
	
	/**
	 * adds the Measure object to the stack - this does NOT add the NoteGroups to the noteGroups list - use addNoteGroupsFromMeasure() for that
	 * @param	measure
	 */
	void addMeasure(Measure measure) {
		_measures.add(measure);
	}
	
	/**
	 * adds all of the NoteGroup objects in the passed in measure. NoteGroups are sorted by time against pre-existing NoteGroups
	 * @param	measure the Measure object to scan for NoteGroup objects
	 */
	void addNoteGroupsFromMeasure(Measure measure) {
		for (var voice in measure.voices) {
			for (var noteGroup in voice.noteGroups) {
				this.addNoteGroup(noteGroup);
			}
		}
	}

	/**
	 * removes the passed in NoteGroup from the MeasureStack
	 * @param noteGroup the NoteGroup to remove
	 */
	void removeNoteGroup(NoteGroup noteGroup) {
		int numNoteGroups = _noteGroups.length;
		for (int i = 0; i < numNoteGroups; i++){
			if (_noteGroups[i] == noteGroup){
				_noteGroups.removeAt(i);
				break;
			}
		}
	}
	
	/**
	 * clears the NoteGroups (usually used prior to adding NoteGroup objects for the current set of parts)
	 */
	void clearNoteGroups() {
		_noteGroups = [];
	}
	
	/**
	 * clears the Measures (usually used prior to adding Measure objects for the current set of parts)
	 */
	void clearMeasures() {
		_measures = [];
	}
	
	
	
	List<NoteGroup> get noteGroups { return _noteGroups; }
	
	List<Measure> get measures { return _measures; }
	
	
	num get dpqLength { return _dpqLength;	}		
	void set dpqLength(num value) { _dpqLength = value; }
	
	
	num get startTime { return _startTime;	}	
	void set startTime(num value) {
		_startTime = value;
		_dpqLength = _endTime - _startTime;
	}
	
	num get endTime { return _endTime;	}		
	void set endTime(num value) {
		_endTime = value;
		_dpqLength = _endTime - _startTime;
	}
	
	List<num> get beatQNotePositions { return _beatQNotePositions; }
	void set beatQNotePositions(List<num> value) { _beatQNotePositions = value; }
	
	
	bool get newSystem { return _newSystem; }		
	void set newSystem(bool value) {	_newSystem = value;	}
	
	
	num get width { return _width; }		
	void set width(num value) { _width = value; }

	/**
	 * The normal indent for this stack if it is not the first stack in a system. Clefs and Keys are counted only if
	 * they are new (and thus must be shown)
	 */
	num get indent { return _indent; }		
	void set indent(num value) { _indent = value; }

	/**
	 * the indentation before the music if this stack happens to be the first stack in its system (clef and key are required)
	 */
	num get indentAsSystemLeader {	return _indentAsSystemLeader; }
	void set indentAsSystemLeader(num value) { _indentAsSystemLeader = value; }
	
	num get startPosition { return _startPosition; }		
	void set startPosition(num value) { _startPosition = value; }
	
	num get number { return _number; }		
	void set number(int value) { _number = value; }
	
	
	num get idealWidth { return _idealWidth; }		
	void set idealWidth(num value) { _idealWidth = value; }
	
	int get maxKeySize { return _maxKeySize; }		
	void set maxKeySize(int value) { _maxKeySize = value; }
	
	bool get newKey { return _newKey; }		
	void set newKey(bool value) { _newKey = value; }
	
	//bool get newTime { return _newTime; }		
	//void set newTime(bool value) { _newTime = value;	}
	
	bool get newClef { return _newClef; }		
	void set newClef(bool value) { _newClef = value;	}


	/**
	 * //holds list of TempoMarker objects that take effect starting with this stack
	 */
	List<TempoMarker> get tempoMarkers { return _tempoMarkers; }
	void set tempoMarkers(List<TempoMarker> value) { _tempoMarkers = value; }

	
	
	MeasureStack get previous { return _previous;	}	
	void set previous(MeasureStack value) {	_previous = value; }
	
	MeasureStack get next { return _next; }		
	void set next(MeasureStack value) {	_next = value; }
	
	System get systemRef { return _systemRef;	}		
	void set systemRef(System value) { _systemRef = value; }


	/**
	 * true if the stack is a pickup measure stack
	 */
	bool get isPickup { return _isPickup; }
	void set isPickup(bool value) { _isPickup = value; }

	/**
	 * true if there is at least one Measure in the stack that needs to be rendered again
	 */
	bool get needsRendering { return _needsRendering; }
	void set needsRendering(bool value) {
		_needsRendering = value;
		if (value == true && systemRef != null){
			systemRef.needsRendering = true;
		}
	}


}
