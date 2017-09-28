part of score_data.formatting;

class ScoreFormatter {
	MusicSpacer _musicSpacer; //handles spacing duties
	MusicBeamer _beamer; //handles beaming duties
	NoteGroupFormatter _ngFormatter; //handles formatting of NoteGroups
	AttachmentFormatter _attachmentFormatter; //handles formatting of attachments
	
	Score _score; //the Score data object
	List<Part> _parts; //the Part objects which should be operated upon - can be all the parts from the score or a subset

	
	ScoreFormatter([Score score = null]) {
		_score = score;

		if (score != null){
			init();
		}
	}
	
	void init() {
		_musicSpacer = new MusicSpacer(_score);
		_beamer = new MusicBeamer();
		_ngFormatter = new NoteGroupFormatter(_score.scoreProperties);
		_attachmentFormatter = new AttachmentFormatter(_score);

		//position all of the Grace Notes in the score
		_parts = _score.parts;
		if (_score.graceNotesNeedFixing){
			correctGraceNoteStartTimes(); //THIS SHOULD ONLY BE CALLED FOR MUSICXML CONTENT
			_score.graceNotesNeedFixing = false;
		}

		//set the Parts list
		setPartList(null);
	}
	
	/**
	 * Sets the parts that will be worked with for formatting
	 * @param	partNames the names of the parts - if null, all parts in the score will be used
	 */
	void setPartList([List<String> partNames = null]) {
		if (partNames != null) {
			if (partNames != null){
    			partNames = partNames.sublist(0); //we're going to modify this, so create a copy first
    		}
			_parts = new List<Part>();
			for (var part in _score.parts) {
				int index = partNames.indexOf(part.name);
				if (index != -1) {
					_parts.add(part);
					part.visible = true;
					partNames.removeAt(index); //ensure that the same part name doesn't count twice
				}
				else {
					part.visible = false;
				}
			}
		}
		else {
			_parts = _score.parts;
			for (var part in _parts){
				part.visible = true;
			}
		}
		
		if (_parts.length == 0){ _parts = _score.parts; }

		//set the notes for the measure stacks to reflect the current set of parts (for music spacing purposes)
		updateMeasureStackNoteGroupsAndMeasures();

		//calculate the ideal spacing positions for notes and the ideal widths of the measures
		//_musicSpacer.computeIdealSpacingValues(null);
	}

	/**
	 * performs spacing and positioning algorithms on entire Score. This method is "intelligent," only updating the
	 * measures that need it.
	 * @param	reflowMeasuresAcrossSystems if true, the engine will calculate how many measures should fit on each system
	 * @param	measuresPerSystem if greater than 0, this many measures will be enforced per system (reflowMeasuresAcrossSystems must also be true)
	 */
	void formatScore2(bool reflowMeasuresAcrossSystems, [int measuresPerSystem = 0]) {
		//make sure musicSpacer has latest ScoreProperty values
		_musicSpacer.initializeScoreSettings();
		
		//first find any measures that have been marked as needing updating.
		_processUpdateRequests();

		//now we have our ideal spacing values. We next run the Reflow Measure routine to potentially move measures between systems. Whatever systems
		//this affects will be marked as needing re-rendering (in addition to the ones that already are marked as such). We'll
		//compute the actual spacing for those systems after the reflow procedure.
		if (reflowMeasuresAcrossSystems) {
			_musicSpacer.groupMeasuresIntoSystems(measuresPerSystem);
		}

		_getActualSpacingAndPositioning();
		
	}

	void _processUpdateRequests() {
		//first find any measures that have been marked as needing updating. We'll reprocess the note attributes
		//and ideal spacing for these measures
		var systems = _score.getSystems();
		for (var system in systems){
			if (system.needsRendering){
				var stacks = system.measureStacks;
				for (var stack in stacks){
					if (stack.needsRendering){
						var measures = stack.measures;
						for (var measure in measures){
							if (measure.notesNeedRendering){
								//get beam groups
								_beamer.getMeasureBeamGroupings(measure);
							
								//get stem directions
								_ngFormatter.getMeasureStemDirections(measure);
							
								//place noteheads on correct side of stem
								_ngFormatter.getMeasureNoteheadOffsets(measure);
							}
						}

						//now that we've updated the pieces that can affect ideal music spacing values,
						//update the ideal spacing for the stack
						_musicSpacer.computeIdealSpacingValues(stack);
					}
				}
			}
		}
	}

	void _getActualSpacingAndPositioning() {
		//compute actual note spacing and get positioning of objects that depend on this spacing
		var systems = _score.getSystems(); //the reflow may have added or removed systems, so we grab them freshly.
		for (var system in systems){
			if (system.needsRendering){
				//space the music
				_musicSpacer.computeActualSpacingValues(system);

				//compute stem end positions (for both beamed and unbeamed notes)
				_ngFormatter.getSystemStemEndPositions(system);
				
				_attachmentFormatter.formatAttachments(system);
			}
		}

		//position the slurs and other line attachments
		_attachmentFormatter.formatLines();
	}

	
	/**
	 * adjusts the start times of grace notes so that they aren't identical to the notes they precede
	 */
	void correctGraceNoteStartTimes() {
		for (var part in _parts) {
			for (var staff in part.staves) {
				for (var measure in staff.measures) {
					//num measureStartTime = measure.stack.startTime;
					for (var voice in measure.voices) {
						List<NoteGroup> noteGroups = voice.noteGroups;
						int consecutiveGraceNotes = 0;
						int i = noteGroups.length - 1;
						NoteGroup attachmentNG; //a normal NoteGroup a gracenote will be associated with
						while (i >= 0) {
							var ng = noteGroups[i];
							if (ng.isGrace) {
								consecutiveGraceNotes++;
								ng.qNoteTime -= consecutiveGraceNotes * 0.1;
								ng.attachmentNG = attachmentNG;
//								if (ng.qNoteTime < measureStartTime){
//									ng.qNoteTime = measureStartTime;
//								}
							}
							else {
								consecutiveGraceNotes = 0;
								attachmentNG = ng;
							}
							i--;
						}
					}
				}
			}
		}
		
		//we have to reorder the notes now
		//updateMeasureStackNoteGroupsAndMeasures();
	}
	
	
	
	void updateMeasureStackNoteGroupsAndMeasures() {
		//measure stacks contain all the notes in the current set of parts in order by time
		List<MeasureStack> stacks = _score.getMeasureStacks();
		int numMeasures = stacks.length;
		
		for (var stack in stacks) {
			stack.clearNoteGroups();
			stack.clearMeasures();
			stack.maxKeySize = 0;
		}
		
		MeasureStack stack;
		for (var part in _parts) {
			for (var staff in part.staves) {
				if (!staff.visible) continue;
				List<Measure> measures = staff.measures;
				for (int i = 0; i < numMeasures; i++) {
					stack = stacks[i];
					Measure measure = measures[i];

					//add the note groups and measures to the stack
					stack.addNoteGroupsFromMeasure(measure);
					stack.addMeasure(measure);

					//update the max key size for the stack
					int totalKeySize = PitchUtils.getTotalKeySize(measure.displayKey, measure.outgoingKey);
					if (totalKeySize > stack.maxKeySize){
						stack.maxKeySize = totalKeySize;
					}
					/*int keySize = measure.displayKey;
					if (keySize < 0){
						keySize *= -1;
					}
					int outgoingSize = measure.outgoingKey;
					if (outgoingSize < 0){
						outgoingSize *= -1;
					}
					if (keySize + outgoingSize > stack.maxKeySize){
						stack.maxKeySize = keySize + outgoingSize;
					}*/
				}
			}
		}
	}



	/**
	 * performs spacing and positioning algorithms on entire Score
	 * @param	reflowMeasuresAcrossSystems if true, the engine will calculate how many measures should fit on each system
	 * @param	measuresPerSystem if greater than 0, this many measures will be enforced per system (reflowMeasuresAcrossSystems must also be true)
	 */
	void formatScore(bool reflowMeasuresAcrossSystems, [int measuresPerSystem = 0]) {


		/////////////////OBSOLETE///////////////////////////


		//reflow the measures
		if (reflowMeasuresAcrossSystems) {
			//TEST - calculate ideal spacing for each stack WITHOUT considering extra indentation that only occurs because a stack starts a new system.
			//The MusicSpacer will account for the extra indent as it figures out which measures should go on a line. After we're done figuring out
			//measure distribution, we'll run this again (in formatSystem()) and include the system start clef and key sigs into our ideal calculations.
			//_musicSpacer.computeIdealSpacingValues(null);

			//int startTime =  getTimer();
			_musicSpacer.groupMeasuresIntoSystems(measuresPerSystem);
			//int endTime = getTimer();
			//trace("group measure " time, endTime - startTime);

			//NOT RELEVANT NOW - at this point in time, computeIdealSpacingValues has already been run once (in setPartList). It was run with the option
			//to take system key/clef/time space into account. This is sort of a hack approach, as it assumes the measures that start each
			//system will require that same space even after the measures have been reflowed. Ideally the reflow algorithm would just consider the indentation
			//that a stack WOULD require if it was first on a system. In other words, we probably need to store a new property in stacks that define
			//how much space they would need if they were first on a system. And we would likely then not store that value with the ideal spacing requirement
			//for the stack itself (since we don't know that it will be first).
			//_musicSpacer.groupMeasuresIntoSystems(measuresPerSystem);

			//reset the ideal spacing positions - now we know which measure is first in each system, so we can compute the ideal spacing with the system
			//keys/clefs/time sigs counted - we rerun this here because measures may be on new systems, and thus the leading space hasn't been counted for them.
			//_musicSpacer.computeIdealSpacingValues(null, true);
		}

		//space the music - note that we don't need to computeIdealSpacingValues, because this was already done in setPartList()
		List<System> systems = _score.getSystems();
		for (var system in systems) {
			formatSystem(system);
		}
	}

	/**
	 * performs spacing and positioning algorithms on one System
	 */
	void formatSystem(System system) {



		/////////////////OBSOLETE///////////////////////////





		//get beam groups
		_beamer.getSystemBeamGroupings(system);

		//get stem directions
		_ngFormatter.getSystemStemDirections(system);

		//place noteheads on correct side of stem
		_ngFormatter.getSystemNoteheadOffsets(system);

		//TEST - compute the ideal positions for the note spacing
		/*List<MeasureStack> stacks = system.measureStacks;
		for (var stack in stacks){
			_musicSpacer.computeIdealSpacingValues(stack);
		}*/

		//space the music
		_musicSpacer.computeActualSpacingValues(system);

		//compute stem end positions (for both beamed and unbeamed notes)
		_ngFormatter.getSystemStemEndPositions(system);
	}




	/**
	 * gets and sets the Score object - running initialization tasks when set
	 */
	Score get score { return _score; }
	void set score(Score value) {
		_score = value;
		init();
	}
}
