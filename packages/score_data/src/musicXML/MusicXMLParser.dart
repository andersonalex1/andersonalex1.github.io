//part of score_data.music_xml;
//
//class MusicXMLParser {
//
//	XmlElement _musicXML;
//	Score _score;
//	
//	Page _currentPage; //the Page object that Systems are currently being added to
//	System _currentSystem; //the System object that MeasureStacks are currently being added to
//	MeasureStack _currentStack; //the current MeasureStack object
//
//	////////params passed to parseXML//////
//	String _musicXMLString;
//	bool _overrideScoreProps;
//	
//	//if true, max key sizes will be computed for each measure stack - needed if 
//	//going straight to rendering without formatting
//	bool _computeMaxKeySizeForRendering; 
//	ScoreProperties _requestedScoreProps;
//	///////////////////////////////////////
//
//	Completer<Score> _parsingCompleter;
//	DateTime _lastPauseTime;
//
//	/**
//	 * Dispatched when the xml file finishes parsing.
//	 * The MusicXMLParser.FINISHED_PARSING constant defines the value of the 
//	 * <code>type</code> property of the event object 
//	 * for a <code>finishedParsing</code> event.
//	 * 
//	 * @eventType finishedParsing
//	 */
//	static const FINISHED_PARSING = "finishedParsing";
//
//
//	MusicXMLParser() {
//		
//	}
//
//	/**
//	 * parses the passed in Music XML file into a nEngine.data.containers.Score object
//	 * Dispatches a FINISHED_PARSING event when done - access score via score property
//	 * @param	musicXML an XML object in the Music XML format
//	 * @param 	computeMaxKeySizeForRendering if true, max key sizes will be computed for each measure stack - 
//	 * 		leave false if you plan on using the formatter (which does this anyway)
//	 * @param	overrideScoreProps if true, when a score is loaded, default score properties are set before 
//	 * 		parsing instead of the settings from the XML
//	 */
//	Future<Score> parseXML(String musicXMLString, [bool computeMaxKeySizeForRendering = true,
//							bool overrideScoreProps = false, ScoreProperties scoreProps = null]) {
//		_musicXMLString = musicXMLString;
//		_computeMaxKeySizeForRendering = computeMaxKeySizeForRendering;
//		_overrideScoreProps = overrideScoreProps;
//		_requestedScoreProps = scoreProps;
//		
//		_parsingCompleter = new Completer();
//		
//		new Timer(const Duration(milliseconds: 20), _getMusicXMLObject);
//		
//		return _parsingCompleter.future;
//	}
//
//
//	ScoreProperties getScoreProperties(XmlElement defaults) {
//		if (defaults == null) {
//			return ScoreProperties.getNewScoreProperties();
//		}
//
//		ScoreProperties sProps = ScoreProperties.getNewScoreProperties();
//
//		sProps.mmHeight = X.eNum(defaults, "scaling millimeters", true);
//		sProps.tenths = X.eNum(defaults, "scaling tenths", true);
//
//
//		sProps.pageHeight = X.eNum(defaults, "page-layout page-height", true);
//		sProps.pageWidth = X.eNum(defaults, "page-layout page-width", true);
//		sProps.leftPageMargin = X.eNum(defaults, "page-layout page-margins left-margin", true);
//		sProps.rightPageMargin = X.eNum(defaults, "page-layout page-margins right-margin", true);
//		sProps.topPageMargin = X.eNum(defaults, "page-layout page-margins top-margin", true);
//		sProps.bottomPageMargin = X.eNum(defaults, "page-layout page-margins bottom-margin", true);
//
//		sProps.systemSpacing = X.eNum(defaults, "system-layout system-distance", true);
//		sProps.topSystemDistance = X.eNum(defaults, "system-layout top-system-distance", true);
//		sProps.leftSystemMargin = X.eNum(defaults, "system-layout system-margins left-margin", true);
//		sProps.rightSystemMargin = X.eNum(defaults, "system-layout system-margins right-margin", true);
//
//		sProps.staffSpacing = X.eNum(defaults, "staff-layout staff-distance", true);
//		if (sProps.staffSpacing == 0) {
//			sProps.staffSpacing = 80;
//		}
//
//		sProps.stemWidth = X.eNum(defaults, "appearance line-width(@type==stem)", true);
//		sProps.beamWidth = X.eNum(defaults, "appearance line-width(@type==beam", true);
//		sProps.staffLineWidth = X.eNum(defaults, "appearance line-width(@type==staff", true);
//		sProps.lightBarlineWidth = X.eNum(defaults, "appearance line-width(@type==light barline", true);
//		sProps.heavyBarlineWidth = X.eNum(defaults, "appearance line-width(@type==heavy barline", true);
//		sProps.legerLineWidth = X.eNum(defaults, "appearance line-width(@type==leger", true);
//		sProps.repeatEndingWidth = X.eNum(defaults, "appearance line-width(@type==ending", true);
//		sProps.hairpinLineWidth = X.eNum(defaults, "appearance line-width(@type==wedge", true);
//		sProps.enclosureWidth = X.eNum(defaults, "appearance line-width(@type==enclosure", true);
//		sProps.tupletBracketWidth = X.eNum(defaults, "appearance line-width(@type==tuplet bracket", true);
//
//		sProps.graceNoteSize = X.eNum(defaults, "appearance note-size(@type==grace", true);
//		sProps.cueNoteSize = X.eNum(defaults, "appearance note-size(@type==cue", true);
//
//		//set music spacing values
//		sProps.qNoteWidth = 7.4083 * (sProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT); //shorter
//		sProps.keySigWidth = 2.0 * (sProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT);
//		sProps.timeSigWidth = 4 * (sProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT);
//		sProps.clefWidth = 5 * (sProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT);
//		sProps.measureLeadIn = 4 * (sProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT);
//
//
//		return sProps;
//	}
//	
//	void _getMusicXMLObject(){
//		_musicXML = parse(_musicXMLString).rootElement;
//		_musicXMLString = null;
//		//html.window.alert('string converted');
//		new Timer(const Duration(milliseconds: 20), _parseXML);
//	}
//	
//	void _parseXML(){
//		_lastPauseTime = new DateTime.now();
//		
//		//reset vars
//		_midiInstrumentsXMLList = null;
//		_measureStacks = null;
//		_currentTuplets = null;
//		_currentSlurs = null;
//		_currentPage = null;
//		_currentSystem = null;
//		_currentStack = null;
//
//		//create the new score
//		_score = new Score();
//		
//
//		var defaultsXML = _musicXML.findElements('defaults');
//		_score.scoreProperties = (defaultsXML.length > 0)
//										? getScoreProperties(defaultsXML.first)
//	      								: getScoreProperties(null);
//										
//		var idXML = _musicXML.findElements('identification');
//		if (idXML.length > 0 && idXML.first.findElements('rights').length > 0){
//		//if (_musicXML.findElements('identification').first.findElements('rights').length > 0) {
//			_score.scoreProperties.rights = X.e(_musicXML, "identification rights");
//		}
//
//		if (_overrideScoreProps) {
//			_score.scoreProperties = (_requestedScoreProps != null)? _requestedScoreProps : 
//									ScoreProperties.getNewScoreProperties();
//		}
//
//		_score.graceNotesNeedFixing = true;
//		
//		_getMusicData();
//	}
//
//	
//	List<XmlElement> _midiInstrumentsXMLList;
//	List<MeasureStack> _measureStacks; //the MeasureStacks that have been created
//	//if a tuplet is in the process of being defined, this variable holds that object until 
//	//the last note of the tuplet is added
//	List<Tuplet> _currentTuplets;
//	//if a slur is in the process of being defined, this holds the Slur until the last note of the slur is added
//    List<Slur> _currentSlurs; 
//    num _partVol;    
//    List<XmlElement> _partXMLList;
//    int _cPartIndex;
//    
//	void _getMusicData() {
//		_buildInstrumentsXMLList();
//
//		_measureStacks = [];
//		_currentTuplets = [];
//		_currentSlurs = [];
//
//		_calculatePartVolumes();
//		
//		_cPartIndex = 0;
//		
//		_partXMLList = _musicXML.findElements("part").toList(growable: false);
//
//		_processNextPart();
//		
//	}
//	
//	void _buildInstrumentsXMLList(){
//		if (_musicXML.findElements("part-list").length > 0) {
//			var scoreParts = _musicXML.findElements("part-list").first.findElements("score-part");
//			_midiInstrumentsXMLList = [];
//			for (XmlElement scorePart in scoreParts) {
//				if (scorePart.findElements("midi-instrument") != null && 
//							scorePart.findElements("midi-instrument").length > 0){
//					for (var midiInstXML in scorePart.findElements("midi-instrument")){
//						_midiInstrumentsXMLList.add(midiInstXML);
//					}
//					//_midiInstrumentsXMLList.add(scorePart.findElements("midi-instrument").first);
//				}
//			}
//		}
//	}
//	
//	void _calculatePartVolumes(){
//		_partVol = 0.15;
//		if (X.e(_musicXML, "part") != null) {
//			//base volume of the part - dynamics can't exceed this
//			_partVol = math.min(1 / _musicXML.findElements("part").length, 0.15); 
//		}
//	}
//	
//	XmlElement _partXML;
//	Part _cPart;
//	int _cPartDPQ;
//	int _passedTimeDPQ;
//	void _processNextPart(){
//		if (_cPartIndex >= _partXMLList.length){
//			//done processing parts - 
//			if (_computeMaxKeySizeForRendering) {
//    			computeMaxKeySizes(); //for rendering we need to know how much space the key signatures will take up
//    		}
//			//send notification we're done
//			//html.window.alert('parsing complete');
//			_parsingCompleter.complete(_score);
//			
//			return;
//		}
//		
//		_partXML = _partXMLList[_cPartIndex];
//		_cPartIndex++;
//		
//		_removeIncompleteSlurs();
//
//		_cPart = _createPartObj();
//
//		//ex. 8 divisions per quarter note would imply the shortest duration in the part is a 32nd note
//		_cPartDPQ = X.eInt(_partXML, "measure attributes divisions"); 
//
//		//we'll also time stamp each note with the total number of divisionsPerQuarterNote that have 
//		//passed up to its starting point. This will be stored as a number property with the 
//		//note (totalDivisions / divisionsPerQuarterNote). But to avoid rounding errors, we'll keep a simple 
//		//sum of the divisions that have passed for the given part and use that each time in the calculation
//		_passedTimeDPQ = 0; //passed time Divisions Per Quarter note
//
//		if (_createStavesForPart() == false){
//			//no measures/staves
//			_processNextPart();
//			return;
//		}
//		
//		//populate the part with music data		
//		//int staffIndex = 0; //MOVED THIS - DOES THIS CAUSE ANY PROBLEMS?
//		
//		_measureIndex = 0; //the index of the current measure/stack
//		_measureXMLList = _partXML.findElements("measure").toList(growable: false);
//		_measure = null;
//		
//		_processNextMeasure();
//	}
//	
//	void _removeIncompleteSlurs(){
//		//clear out any slurs from the last part which weren't ended properly
//		for (var slur in _currentSlurs) {
//			int index = slur.firstNote.slurs.indexOf(slur);
//			slur.firstNote.slurs.removeAt(index);
//			if (slur.firstNote.slurs.length == 0) {
//				slur.firstNote.slurs = null;
//			}
//		}
//		_currentSlurs = [];
//	}
//	
//	Part _createPartObj(){
//		//create Part object with name and id info
//		String staffName = "";
//		String abbrName = "";
//		int midiPreset = 0;
//		int midiChannel = 1;
//		if (_musicXML.findElements("part-list").first.findElements("score-part").length > 0) {
//			var scoreParts = _musicXML.findElements("part-list").first.findElements("score-part");
//			for (XmlElement scorePart in scoreParts) {
//				if (scorePart.getAttribute("id") == _partXML.getAttribute("id")) {
//					staffName = X.e(scorePart, "part-name", true);
//					abbrName = X.e(scorePart, "part-abbreviation", true);
//
//					if (scorePart.findElements("midi-instrument").length > 0) {
//						var midiXMLList = scorePart.findElements("midi-instrument");
//						midiPreset = X.eInt(midiXMLList, "midi-program");
//						if (midiXMLList.first.findElements("midi-channel").length > 0) {
//							midiChannel = X.eInt(midiXMLList, "midi-channel");
//						}
//					}
//
//				}
//			}
//		}
//
//		var cPart = new Part(_partXML.getAttribute("id"), staffName, abbrName); //the current Part
//		cPart.volume = _partVol;
//		cPart.midiChannel = midiChannel;
//		cPart.midiPreset = midiPreset;
//
//		_score.addPart(cPart);
//		
//		return cPart;
//	}
//	
//	bool _createStavesForPart(){
//		//create the staves and initial clefs for the part
//		var measuresXML = _partXML.findElements("measure");
//		XmlElement measureXML = null;
//		if (measuresXML.length > 0) {
//			measureXML = measuresXML.first;
//			//the first measure defines the number of staves. If it has no <staves> element, there 
//			//is 1 staff. Otherwise, the <staves> element indicates the staff count
//			int numStaves = X.eInt(measureXML, "attributes staves", true);
//			if (numStaves < 1) {
//				numStaves = 1;
//			}
//
//			for (int i = 0; i < numStaves; i++) {
//				_cPart.addStaff(new Staff()); //create the staves
//			}
//			//the first measure also may define a transposition
//			if (X.e(measureXML, "attributes transpose") != null) {
//				int diatonicTrans = (X.e(measureXML, "attributes transpose diatonic") != null)? 
//									-1 * X.eInt(measureXML, "attributes transpose diatonic") : 0;
//				int chromaticTrans = (X.e(measureXML, "attributes transpose chromatic") != null)? 
//									-1 * X.eInt(measureXML, "attributes transpose chromatic") : 0;
//				//set transposition - use false as no measures exist, so no need to update them
//				_cPart.setTransposition(diatonicTrans, chromaticTrans, false); 
//			}
//			return true;
//		} 
//		else {
//			return false;
//		}
//	}
//	
//	int _measureIndex;
//	List<XmlElement> _measureXMLList;
//	Measure _measure;
//	void _processNextMeasure(){
//		if (_measureIndex >= _measureXMLList.length){
//			//done processing measures for this part - go on to the next part
//			_checkPartForErrors(_cPart);
//			_processNextPart();
//			return;
//		}
//		
//		var measureXML = _measureXMLList[_measureIndex];
//		
//		//for each staff we must create a measure
//		for (var staff in _cPart.staves) {
//			//the previous measure created
//			Measure prevMeasure = (staff.measures.length > 0) ? staff.measures[staff.measures.length - 1] : null;
//			_measure = createNewMeasure(measureXML, prevMeasure, _measureIndex);
//			if (_score.parts.length == 1) {
//				_measure.stack.startTime = _passedTimeDPQ / _cPartDPQ; //mark the start DPQ time of the measure
//				_measure.stack.endTime = _measure.stack.startTime + (_measure.numBeats * (4 / _measure.beatType));
//			}
//			staff.addMeasure(_measure);
//
//		}
//
//
//		Voice cVoice = null; //the current Voice
//		NoteGroup cNoteGroup = null; //the current NoteGroup
//		
//		//holds the last mid-measure clef that has been added to the measure (if any) and 
//		//has not been assigned to a note.
//		Clef midMeasureClef = null; 
//
//		//When backup commands are invoked, we set this value to mark our latest point. When we're finished with 
//		//the entries for the measure, we compare our current passedTimeDPQ value to this stored number to make 
//		//sure we've filled out the measure. If we haven't, we forward ourselves back up to this value.
//		num dpqPositionBeforeBackup = 0;
//
//		int staffIndex = 0;
//		for (XmlElement element in measureXML.children.where((n)=>n is XmlElement)) {
//			//at this point we're concerned with <note> and <backup> elements - other elements 
//			//will be handled separately. So only capture these 2 for now.
//			String elemName = element.name.toString();
//			XmlElement noteXML = null;
//			if (elemName == "note") {
//				noteXML = element;
//			} else if (elemName == "backup") {
//				//keep track of the duration/time stamping position - <backup> elements imply a voice or 
//				//staff/voice change, so we subtract the indicated time
//				dpqPositionBeforeBackup = _passedTimeDPQ;
//				_passedTimeDPQ -= X.eInt(element, "duration");
//				continue;
//			} else if (elemName == "forward") {
//				/*<forward>
//					<duration>1</duration>
//					<voice>2</voice> //do we need to pay attention to this?
//				  </forward>*/
//				//keep track of the duration/time stamping position - <forward> elements imply a voice 
//				//leaves part of the measure blank, so we add the time to jump forward
//				_passedTimeDPQ += X.eInt(element, "duration");
//				continue;
//			} else if (X.e(element, "clef") != null) {
//				//this is an <attributes> element with one or more <clef> tags. Clefs in MusicXML are either 
//				//placed at the start of the measureXML element, if they are meant to start the measure, or 
//				//between notes, if they are meant to be mid-measure. For parts with more than one staff,
//				//the clef's have a number attribute (1 for the first staff, 2 for the second, etc. 
//				//Each Measure object is given a list of all Clef objects it contains. When we first create a 
//				//Measure (in createMeasure()), the Measure receives a Clef object that matches the last clef 
//				//in the preceding Measure (if it exists). If a new Clef is declared in the musicXML which falls 
//				//at the beginning of this Measure, it replaces that copied clef.
//				for (XmlElement clefXML in element.findElements("clef")) {
//					Clef clef = new Clef();
//					int line = X.eInt(clefXML, "line");
//					clef.type = ClefType.getClefType(X.e(clefXML, "sign"), line);
//					clef.isNew = true;
//					clef.show = true;
//
//					staffIndex = (clefXML.getAttribute("number") != null) 
//												? int.parse(clefXML.getAttribute("number")) - 1 : 0;
//					var targetMeasure = _cPart.staves[staffIndex].measures.last;
//					//Measure targetMeasure = _cPart.staves[staffIndex].measures[_cPart.staves[staffIndex].measures.length - 1];
//
//					//we decide whether this clef gets added to the list of clefs in the measure or replaces the first
//					//based on whether or not any notes have yet been added to this measure. If no notes exist,
//					//it should replace any first clef that has been added to the measure
//					bool noteHasBeenAdded = false;
//					for (var voice in targetMeasure.voices) {
//						if (voice.noteGroups.length > 0) {
//							noteHasBeenAdded = true;
//							break;
//						}
//					}
//					if (noteHasBeenAdded) {
//						targetMeasure.clefs.add(clef);
//						midMeasureClef = clef;
//						clef.qNoteTime = _passedTimeDPQ / _cPartDPQ; //3/8/2015
//					} 
//					else {
//						clef.qNoteTime = targetMeasure.stack.startTime;
//						if (targetMeasure.clefs.length == 0) {
//							targetMeasure.clefs.add(clef);
//						} else {
//							targetMeasure.clefs[0] = clef;
//						}
//						//make note that this Stack has at least one measure with a new start-of-measure clef
//						targetMeasure.stack.newClef = true; 
//
//						//since we already created the Measure for this stack, the routine run to make sure new 
//						//systems always show a full sized clef has been run before this point. We need to do 
//						//that check again with this new clef (which may be the first clef)
//						if (targetMeasure.stack.newSystem) {
//							clef.show = true;
//							clef.smallSize = false;
//						}
//					}
//
//				}
//
//				continue;
//			} else if (elemName == "sound") {
//				//check to see if there is a tempo marker here
//				if (element.getAttribute("tempo") != null) {
//					//MeasureStack targetStack = _cPart.staves[staffIndex].measures[_cPart.staves[staffIndex].measures.length - 1].stack;
//					var targetStack = _cPart.staves[staffIndex].measures.last.stack;
//					createTempoMarker(element, _passedTimeDPQ / _cPartDPQ, targetStack);
//				}
//				continue;
//			} else if (elemName == "direction") {
//				//for now we'll only support dynamics
//				if (element.findElements("direction-type").first.findElements("dynamics").length > 0) {
//					staffIndex = (X.e(element, "staff") != null) ? X.eInt(element, "staff") - 1 : 0;
//					//Measure targetMeasure = _cPart.staves[staffIndex].measures[_cPart.staves[staffIndex].measures.length - 1];
//					var targetMeasure = _cPart.staves[staffIndex].measures.last;
//
//					//create the dynamic
//					Dynamic dyn = new Dynamic();
//					dyn.type = (X.eCol(element, "direction-type dynamics *").first as XmlElement).name.toString();
//					//dyn.type = element.child("direction-type").child("dynamics").children()[0].name();
//					dyn.isAbove = (element.getAttribute("placement") == "above");
//					dyn.qNoteTime = X.eInt(element, "offset", true) + _passedTimeDPQ / _cPartDPQ;
//					dyn.volume = math.pow(X.aNum(element, "sound dynamics", true) / 127, 2);
//					if (dyn.volume == 0) dyn.volume = 0.5;
//
//					dyn.measure = targetMeasure;
//					dyn.width = _score.scoreProperties.noteheadWidth * dyn.type.length;
//					dyn.height = _score.scoreProperties.staffLineSpacing * 2;
//
//					//add it to the measure
//					if (targetMeasure.attachments != null) {
//						targetMeasure.attachments.add(dyn);
//					} else {
//						targetMeasure.attachments = [dyn];
//					}
//				} else if (X.a(element, "sound tempo") != null) {
//					//MeasureStack targetStack = _cPart.staves[staffIndex].measures[_cPart.staves[staffIndex].measures.length - 1].stack;
//					var targetStack = _cPart.staves[staffIndex].measures.last.stack;
//					createTempoMarker(element.findElements("sound").first, _passedTimeDPQ / _cPartDPQ, targetStack);
//				}
//
//				continue;
//			} else {
//				continue;
//			}
//			//figure out which Staff the note goes on
//			int staffNum = (noteXML.findElements("staff").length == 0) ? 1 : X.eInt(noteXML, "staff", true);
//			Staff cStaff = _cPart.staves[staffNum - 1]; //the current staff
//
//			//get the current measure
//			var cMeasure = cStaff.measures[cStaff.measures.length - 1];
//
//			//get or create the current Voice in the current measure
//			int voiceNum = X.eInt(noteXML, "voice", true);
//			cVoice = cMeasure.getVoiceByNumber(voiceNum);
//
//
//			//get or create the current NoteGroup
//			if (noteXML.findElements("chord").length == 0) {
//				cNoteGroup = createNoteGroup(noteXML, cMeasure);
//				cVoice.addNoteGroup(cNoteGroup);
//
//				//add the time stamp info to the note and increment the passedTime
//				cNoteGroup.qNoteTime = _passedTimeDPQ / _cPartDPQ; //qnote time
//				cNoteGroup.qNoteDuration = cNoteGroup.duration / _cPartDPQ;
//				_passedTimeDPQ += cNoteGroup.duration;
//				//we now change the duration value to be in terms of our duration units (1024 
//				//per quarter note). This must happen AFTER calculating the qNoteDuration from the 
//				//original cNoteGroup.duration (which has tuplet ratio modification built into it)
//				cNoteGroup.duration = DurationType.getDurationValue(cNoteGroup.durationType, cNoteGroup.numDots);
//
//				//check if a mid-measure clef has been defined - if so, assign it to this note and then set 
//				//it to null so that it won't be assigned to another NoteGroup.
//				//3/8/2015 - modified to check qNoteTime of clef equals or precedes NoteGroup (in case we backed up)
//				if (midMeasureClef != null && midMeasureClef.qNoteTime <= cNoteGroup.qNoteTime) {
//					//midMeasureClef.qNoteTime = cNoteGroup.qNoteTime; //3/8/2015
//					cNoteGroup.clef = midMeasureClef;
//					midMeasureClef = null;
//				}
//			}
//
//			//create the new note and add it to the NoteGroup
//			if (!cNoteGroup.isRest) {
//				Note cNote = createNote(noteXML, cNoteGroup, cMeasure);
//				//slightly faster - depends on musicXML putting notes in bottom up order (I've found an exception)
//				//cNoteGroup.addNote(cNote); 
//				
//				//safer method
//				cNoteGroup.insertNote(cNote); 
//
//				//also check to see if the stem position needs to be updated
//				if (cNoteGroup.notes.length == 1) {
//					cNoteGroup.stemStartPos = cNote.vPos;
//				} else {
//					if (cNote.hPos != 0) {
//						cNoteGroup.stemHPos = _score.scoreProperties.noteheadWidth;
//					}
//					cNoteGroup.stemStartPos = (cNoteGroup.stemDirection == StemDirection.UP) 
//												? cNoteGroup.notes[0].vPos 
//												: cNoteGroup.notes[cNoteGroup.notes.length - 1].vPos;
//				}
//			}
//		}
//
//		//make sure passedTimeDPQ has been forwarded to the end of the measure - a 
//		//partially complete layer could have left it in the middle of the measure
//		if (!_measure.stack.isPickup) {
//			_passedTimeDPQ = (_measure.stack.endTime * _cPartDPQ).round();
//		} else if (_passedTimeDPQ < dpqPositionBeforeBackup) { //EXPERIMENTAL ADDITION
//			_passedTimeDPQ = dpqPositionBeforeBackup.round();
//		}
//
//		//update the end time and duration of the stack with the info from the measure
//		if (_score.parts.length == 1) {
//			_measure.stack.endTime = _passedTimeDPQ / _cPartDPQ;
//		}
//
//		_measureIndex++;
//		
//		DateTime currentTime = new DateTime.now();
//		if (currentTime.difference(_lastPauseTime).inMilliseconds > 1000){
//			_lastPauseTime = currentTime;
//			new Timer(const Duration(milliseconds: 20), _processNextMeasure);
//		}
//		else {
//			_processNextMeasure();
//		}
//		
//	}
//
//	Measure createNewMeasure(XmlElement measureXML, Measure previousMeasure, int measureIndex) {
//
//		//create the measure
//		Measure measure = new Measure();
//
//		//initialize key, time and clef with settings from previous measure and then override 
//		//them if there are new values in the XML
//		bool reParentedMidMeasureClef = false;
//		if (previousMeasure != null) {
//			//measure.transposition = previousMeasure.transposition;
//			measure.diatonicTransposition = previousMeasure.diatonicTransposition;
//			measure.chromaticTransposition = previousMeasure.chromaticTransposition;
//			measure.concertKey = previousMeasure.concertKey;
//			measure.displayKey = previousMeasure.displayKey;
//			measure.isMajorKey = previousMeasure.isMajorKey;
//			measure.numBeats = previousMeasure.numBeats;
//			measure.beatType = previousMeasure.beatType;
//			measure.beatGroups = previousMeasure.beatGroups.sublist(0);
//			
//			var prevClef = previousMeasure.clefs.last;
//			//check for the unusual situation where the previous clef was a mid-measure clef assigned 
//			//to the very end of the bar. It won't have been assigned to a note (which is necessary), 
//			//so we're going to reparent it to the start of this bar.
//			if (prevClef.qNoteTime == previousMeasure.stack.endTime){
//				measure.clefs.add(previousMeasure.clefs.removeLast());
//				prevClef.qNoteTime = previousMeasure.stack.endTime;
//				prevClef.isNew = true;
//				reParentedMidMeasureClef = true;
//			}
//			else {
//				//create the first clef for the measure to match the last clef's type from the previous measure
//				Clef clef = new Clef(); 
//				clef.type = prevClef.type;
//				clef.qNoteTime = previousMeasure.stack.endTime;
//				if (measure.clefs.length == 0) {
//					measure.clefs.add(clef);
//				}
//				else {
//					measure.clefs[0] = clef;
//				}
//			}
//			
//		}
//		else {
//			//EXPERIMENTAL - give measure a default clef. This SHOULD get overwritten, except with bad xml files
//			Clef clef = new Clef();
//			clef.type = ClefType.TREBLE;
//			clef.qNoteTime = 0;
//			clef.show = true;
//			clef.smallSize = false;
//			measure.clefs.add(clef);
//		}
//
//
//		//get the measure stack for the current index, or create one
//		MeasureStack stack = null;
//		if (_measureStacks.length > measureIndex) {
//			stack = _measureStacks[measureIndex];
//		} 
//		else {
//			stack = new MeasureStack();
//			try {
//				stack.number = int.parse(measureXML.getAttribute("number"));
//			}
//			catch (e){
//				if ((_measureStacks.length > 1 && _measureStacks[0].isPickup) ||
//						measureXML.getAttribute("implicit") == "yes"){
//					stack.number = measureIndex;
//				}
//				else {
//					stack.number = measureIndex + 1;
//				}
//			}
//			//see if it's a pickup measure - measure 0 is probably a better guide than "implicit"
//			if (measureXML.getAttribute("implicit") == "yes" && stack.number == 0) { 
//				stack.isPickup = true;
//			}
//			stack.startPosition = (previousMeasure != null) 
//									? previousMeasure.stack.width + previousMeasure.stack.startPosition : 0;
//			stack.width = (measureXML.getAttribute("width") != null)? num.parse(measureXML.getAttribute("width")) : 0;
//
//			if (_currentStack != null) { //update the linked list properties
//				_currentStack.next = stack;
//				stack.previous = _currentStack;
//			}
//
//		}
//
//		_currentStack = stack;
//
//		//give the measure a reference to the stack it belongs to
//		measure.stack = stack;
//		
//		//handle the special case of a clef that was re-parented from previous measure to this one
//		if (reParentedMidMeasureClef){
//			stack.newClef = true;
//		}
//
//		//add the measure to the stack
//		stack.addMeasure(measure);
//
//		if (stack.systemRef != null) {
//			_currentSystem = stack.systemRef;
//		}
//
//		//handle the properties set in <print/> tags - includes info for new pages and systems
//		Page page;
//		System system;
//		//we ALWAYS have to make sure the first stack is set to new page and new system - 
//		//NoteFlight doesn't add these markers
//		if (measureXML.findElements("print").length > 0 || _measureStacks.length == 0) { 
//			//check for situations where there are new pages and/or new systems
//			//note that we special case the first system in the piece in case it isn't marked (I'm finding 
//			//this when re-saving a MusicXML file after opening the xml in Finale)
//			if (X.e(measureXML, "print page-number") != null || X.a(measureXML, "print new-page") == "yes" || 
//						measureIndex == 0) { //the standard tag for new page
//				if (stack.systemRef == null || !stack.systemRef.newPage) {
//					//create a new page and a new system - update their linked list properties
//					page = new Page();
//					system = new System(_score.scoreProperties);
//					page.addSystem(system);
//					_score.addPage(page);
//					if (_currentPage != null) {
//						_currentPage.next = page;
//						_currentSystem.next = system;
//						page.previous = _currentPage;
//						system.previous = _currentSystem;
//					}
//					_currentPage = page;
//					_currentSystem = system;
//
//					system.newPage = true;
//					stack.newSystem = true;
//					stack.startPosition = 0;
//				}
//			} else if (X.a(measureXML, "print new-system") == "yes") { //the standard tag for new system
//				if (!stack.newSystem) {
//					//create a new system - update the linked list properties
//					system = new System(_score.scoreProperties);
//					_currentPage.addSystem(system);
//					if (_currentSystem != null) {
//						_currentSystem.next = system;
//						system.previous = _currentSystem;
//					}
//					_currentSystem = system;
//
//					stack.newSystem = true;
//					stack.startPosition = 0;
//				}
//			}
//
//
//			//check to see if this system is indented
//			num val = X.eNum(measureXML, "system-layout system-margins left-margin", true);
//			if (val != 0) {
//				print('indent: $val');
//				_currentSystem.indent = val;
//			}
//
//		}
//
//		//add the stack to the current system (necessary to do it here, because if it goes on a new system, 
//		//the system won't be created until this point.
//		if (_measureStacks.length <= measureIndex) {
//			_currentSystem.addMeasureStack(stack, false);
//			_measureStacks.add(stack);
//		}
//
//
//		//always show clef and key at beginning of new system. These don't show in XML unless they are 
//		//new to this staff, so we have to infer that they should be here.
//		//if (measure.newSystem) {
//		if (stack.newSystem) {
//			//measure.showClef = true;
//			if (measure.clefs.length > 0) {
//				measure.clefs[0].show = true;
//				measure.clefs[0].smallSize = false;
//			}
//			measure.showKey = true;
//		}
//
//		//handle the properties set in <attributes/> tags, including key, time and clef info
//		if (measureXML.findElements("attributes").length > 0) {
//			XmlElement attXML = measureXML.findElements("attributes").first;
//			//transposition
//			if (attXML.findElements("transpose").length > 0) {
//				//measure.diatonicTransposition = -1 * X.eInt(attXML, "transpose diatonic");
//				measure.diatonicTransposition = (X.e(attXML, "transpose diatonic") != null)
//													? -1 * X.eInt(attXML, "transpose diatonic") : 0;
//				//measure.chromaticTransposition = -1 * X.eInt(attXML, "transpose chromatic");
//				measure.chromaticTransposition = (X.e(attXML, "transpose chromatic") != null)
//													? -1 * X.eInt(attXML, "transpose chromatic") : 0;
//			}
//			//key signature
//			if (X.e(attXML, "key fifths") != null) {
//				XmlElement keyXML = attXML.findElements("key").first;
//				measure.displayKey = X.eInt(keyXML, "fifths");
//				measure.concertKey = measure.displayKey - 
//						PitchUtils.getKeySigAlterationForTransposition(measure.diatonicTransposition, 
//																		measure.chromaticTransposition);
//				measure.outgoingKey = (previousMeasure != null) ? previousMeasure.displayKey : 0;
//				//if (measureXML.getAttribute(0].key.key.mode != undefined){
//				if (keyXML.findElements("mode").length > 0) {
//					String mode = X.e(keyXML, "mode").toLowerCase();
//					measure.isMajorKey = (mode == "major" || mode == "(unknown)");
//				} else {
//					measure.isMajorKey = true;
//				}
//
//				measure.showKey = true;
//				stack.newKey = true; //make note now that this stack has started a new key signature
//			}
//
//			//time signature
//			if (X.e(attXML, "time beats") != null) {
//				XmlElement timeXML = attXML.findElements("time").first;
//				measure.numBeats = X.eInt(timeXML, "beats");
//				measure.beatType = X.eInt(timeXML, "beat-type");
//				measure.showTime = true;
//				//stack.newTime = true;
//
//				//create a beatGroupings Array that lists the counts of the primary 
//				//beats ([0,1,2,3] in 4/4, [0,1.5] in 6/8, etc.)
//				List<num> beatGroups = [];
//				for (int i = 0; i < measure.numBeats; i++) {
//					//if it's not compound, or if it is compound and this is the third beat (first, fourth, 7th, etc.)
//					if (measure.beatType % 8 != 0 || i % 3 == 0) { 
//						beatGroups.add(i * (4 / measure.beatType));
//					}
//				}
//				measure.beatGroups = beatGroups;
//			}
//		}
//
//		return measure;
//	}
//
//	NoteGroup createNoteGroup(XmlElement noteXML, Measure cMeasure) {
//		NoteGroup noteGroup = new NoteGroup();
//		
//		//check to see if this noteGroup is visible
//		if (noteXML.getAttribute("print-object") == "no"){
//			noteGroup.visible = false;
//  		}
//
//		//get properties shared between notes and rests
//		if (noteXML.findElements("duration").length > 0) {
//			noteGroup.duration = X.eInt(noteXML, "duration");
//		} else {
//			noteGroup.duration = 0;
//		}
//		//the duration type of the note - if not present, it's a whole rest
//		noteGroup.durationType = (noteXML.findElements("type").length > 0) 
//											? DurationType.getDurationType(X.e(noteXML, "type")) 
//											: DurationType.WHOLE; 
//		noteGroup.isGrace = (noteXML.findElements("grace").length > 0);
//		//if no horizontal placement is specified, it's a default rest
//		noteGroup.hPos = (noteXML.getAttribute("default-x") != null) 
//											? num.parse(noteXML.getAttribute("default-x")) 
//											: cMeasure.stack.width / 2; 
//
//		//augmentation dots
//		noteGroup.numDots = noteXML.findElements("dot").length;
//
//		//tuplets - for a tuplet, we create a Tuplet object, fill in properties for appearance, and 
//		//assign it to the first note of the tuplet. We keep track of the tuplet in a member variable 
//		//here, and then when the last note of the tuplet comes, we add that note to the Tuplet object.
//
//		List<Tuplet> tupletsToRemove = [];
//		XmlElement notationsXML = (noteXML.findElements("notations").length > 0) 
//													? noteXML.findElements("notations").first : null;
//		Iterable<XmlNode> tupletsXML = X.eCol(notationsXML, "tuplet");
//		if (tupletsXML != null) {
//			//do this as a loop, as it's possible to have a one note tuplet that serves as start and stop
//			for (var tupletXML in tupletsXML) { 
//				if (tupletXML.getAttribute("type") == "start") {
//					Tuplet tuplet = new Tuplet();
//					tuplet.tupletID = (tupletXML.getAttribute('number') != null)
//													? int.parse(tupletXML.getAttribute("number")) : 0;
//					tuplet.firstNote = noteGroup;
//					tuplet.above = (tupletXML.getAttribute("placement") == "above");
//
//					//get the tuplet numerator (the 3 for 3 in the space of 2)
//					int numDots;
//					int tupletDurType;
//					if (tupletXML.findElements("tuplet-actual").length > 0) {
//						XmlElement tupActualXML = tupletXML.findElements("tuplet-actual").first;
//						tuplet.numerator = X.eInt(tupActualXML, "tuplet-number");
//						numDots = (tupActualXML.findElements("tuplet-dot") != null)
//													? tupActualXML.findElements("tuplet-dot").length : 0;
//						tupletDurType = DurationType.getDurationType(X.e(tupActualXML, "tuplet-type"));
//						tuplet.numeratorDuration = DurationType.getDurationValue(tupletDurType, numDots);
//					} else {
//						tuplet.numerator = X.eInt(noteXML, "time-modification actual-notes");
//						tuplet.numeratorDuration = DurationType.getDurationValue(noteGroup.durationType, 
//																					noteGroup.numDots);
//					}
//
//					//get the tuplet denominator (the 2 for 3 in the space of 2)
//					if (tupletXML.findElements("tuplet-normal").length > 0) {
//						XmlElement tupNormalXML = tupletXML.findElements("tuplet-normal").first;
//						tuplet.denominator = X.eInt(tupNormalXML, "tuplet-number");
//						numDots = (tupNormalXML.findElements("tuplet-dot").length > 0) 
//													? tupNormalXML.findElements("tuplet-dot").length : 0;
//						tupletDurType = DurationType.getDurationType(X.e(tupNormalXML, "tuplet-type"));
//						tuplet.denominatorDuration = DurationType.getDurationValue(tupletDurType, numDots);
//					} else {
//						tuplet.denominator = X.eInt(noteXML, "time-modification normal-notes");
//						numDots = noteXML.findElements("time-modification").first.findElements("normal-dot").length;
//						var durString = X.e(noteXML, "time-modification normal-type");
//						tupletDurType = (durString != null)? DurationType.getDurationType(durString) : noteGroup.durationType;
//						
//						tuplet.denominatorDuration = DurationType.getDurationValue(tupletDurType, numDots);
//					}
//
//					_currentTuplets.add(tuplet);
//
//				} else if (tupletXML.getAttribute("type") == "stop") {
//					int tupletID = (tupletXML.getAttribute('number') != null)
//													? int.parse(tupletXML.getAttribute("number")) : 0;
//					Tuplet tuplet = _currentTuplets[0];
//					for (var tup in _currentTuplets) {
//						if (tup.tupletID == tupletID) {
//							tuplet = tup;
//							break;
//						}
//					}
//					tuplet.endNote = noteGroup;
//
//					tupletsToRemove.add(tuplet);
//				}
//			}
//		}
//		//add our tuplets to each of the NoteGroups and then remove any tuplets from the list that have been finished
//		if (_currentTuplets.length > 0) {
//			noteGroup.tuplets = _currentTuplets.sublist(0);
//
//			if (tupletsToRemove.length > 0) {
//				for (var tupletToRemove in tupletsToRemove) {
//					for (int i = 0; i < _currentTuplets.length; i++) {
//						if (tupletToRemove == _currentTuplets[i]) {
//							_currentTuplets.removeAt(i);
//						}
//					}
//				}
//			}
//		}
//
//		//slurs
//		Iterable<XmlNode> slursXML = (notationsXML != null) ? notationsXML.findElements("slur") : null;
//		if (slursXML != null) {
//			for (var slurXML in slursXML) {
//				Slur slur = null;
//				if (slurXML.getAttribute("type") == TieState.START) {
//					//create the slur and add set its firstNote property to the current NoteGroup
//					slur = new Slur();
//					slur.slurID = int.parse(slurXML.getAttribute("number"));
//					slur.firstNote = noteGroup;
//					_currentSlurs.add(slur);
//				} else if (slurXML.getAttribute("type") == TieState.STOP) {
//					//this is the last note of the slur - find the slur with matching ID and mark its 
//					//end note property as this NoteGroup
//					int slurID = int.parse(slurXML.getAttribute("number"));
//
//					//go through slurs in reverse order to find most recent (and likely) match
//					int numSlurs = _currentSlurs.length;
//					int slurIndex = numSlurs - 1;
//					while (slurIndex >= 0) {
//						if (_currentSlurs[slurIndex].slurID == slurID) {
//							slur = _currentSlurs[slurIndex];
//							break;
//						}
//						slurIndex--;
//					}
//
//					if (slur != null) {
//						slur.endNote = noteGroup;
//						//remove the slur from our current slurs
//						int index = _currentSlurs.indexOf(slur);
//						_currentSlurs.removeAt(index);
//					}
//				}
//
//				//assign this slur to the slurs list for the NoteGroup, creating the list if it doesn't exist
//				if (slur != null) {
//					if (noteGroup.slurs == null) {
//						noteGroup.slurs = [slur];
//					} else {
//						noteGroup.slurs.add(slur);
//					}
//				}
//			}
//		}
//		
//		//articulations
//		var notationsElements = noteXML.findElements('notations');
//		if (notationsElements.length > 0){
//			var articulationsElement = notationsElements.first.findElements('articulations');
//			if (articulationsElement != null && articulationsElement.length > 0) {
//				for (var articXML in articulationsElement.first.children) {
//					if (articXML is XmlElement) {
//						var articulation = new Articulation();
//						articulation.type = ArticulationType.getTypeFromName(articXML.name.toString());
//						String hPos = articXML.getAttribute('default-x');
//						String vPos = articXML.getAttribute('default-y');
//						articulation.hPos = (hPos != null) ? num.parse(hPos) : 0;
//						articulation.vPos = (vPos != null) ? -1 * num.parse(vPos) : 0;
//						articulation.isAbove = articXML.getAttribute("placement") == "above";
//						articulation.noteGroup = noteGroup;
//						articulation.getWidthHeight();
//
//						if (noteGroup.articulations == null) {
//							noteGroup.articulations = [];
//						}
//						noteGroup.articulations.add(articulation);
//					}
//				}
//			}
//		}
//
//		//add the lyric syllable if this notegroup has one
//		if (noteXML.findElements("lyric").length > 0) {
//			var lyric = new Lyric(X.e(noteXML, "lyric syllabic"), X.e(noteXML, "lyric text"), 
//									X.aInt(noteXML, "lyric number"), 0, X.aInt(noteXML, "lyric default-y"));
//			if (lyric.vPos == null){
//				lyric.vPos = _score.scoreProperties.staffLineSpacing * -8;
//			}
//			noteGroup.lyric = lyric;
//		}
//
//		if (noteXML.findElements("rest").length > 0) {
//			noteGroup.isRest = true;
//			
//			//this property exists only if the rest is not in default position
//			if (X.e(noteXML, "rest display-step") != null) { 
//				//get staff number (for sake of knowing the clef) and vertical placement of rest
//				//var staffNum:Int = (noteXML.staff == undefined)? 1 : int(noteXML.staff[0]);
//				//to position the rest vertically, we need to know what the current clef is 
//				//at this note's point in time
//				String clefType = (cMeasure.clefs.length > 0) 
//											? cMeasure.clefs[cMeasure.clefs.length - 1].type 
//											: ClefType.TREBLE;
//
//				String pitchName = X.e(noteXML, "rest display-step") + X.e(noteXML, "rest display-octave");
//				//the number of steps above or below the top staff line
//				int stepsFromTopStaffLine = PitchUtils.getStepsFromTopStaffLine(pitchName, clefType); 
//				noteGroup.restVPos = (_score.scoreProperties.staffLineSpacing / 2) * stepsFromTopStaffLine;
//			} else { //it's a normal rest, centered vertically
//				noteGroup.restVPos = _score.scoreProperties.staffLineSpacing * 2;
//			}
//			if (noteGroup.durationType == DurationType.WHOLE) {
//				noteGroup.restVPos -= 0.5 * _score.scoreProperties.staffLineSpacing;
//			} else if (noteGroup.durationType == DurationType.HALF) {
//				noteGroup.restVPos -= 0.3 * _score.scoreProperties.staffLineSpacing;
//			}
//
//			return noteGroup; //rests have no more properties
//		}
//
//		//get properties unique to notes
//		Iterable<XmlNode> beamsXML = noteXML.findElements("beam");
//		for (var beamXML in beamsXML) {
//			noteGroup.beamStates.add(beamXML.text);
//		}
//
//		if (noteXML.getAttribute("default-x") != null) {
//			noteGroup.hPos = num.parse(noteXML.getAttribute("default-x"));
//		}
//
//		String stemDirection;
//		if (noteXML.findElements("stem").length > 0) {
//			stemDirection = X.e(noteXML, "stem");
//			if (X.a(noteXML, "stem default-y") != null) {
//				noteGroup.stemEndPos = -1 * X.aNum(noteXML, "stem default-y");
//			}
//		} else if (noteGroup.durationType == DurationType.WHOLE) {
//			stemDirection = StemDirection.NO_STEM;
//		} else {
//			//it's not a whole note, but the musicXML was evidently still missing a stem 
//			//declaration (Noteflight leaves it out)
//			stemDirection = StemDirection.UP; //just default to up - we'll correct it later
//		}
//		noteGroup.stemDirection = stemDirection;
//		noteGroup.stemHPos = (stemDirection == StemDirection.UP) ? _score.scoreProperties.noteheadWidth : 0;
//
//		return noteGroup;
//	}
//
//	Note createNote(XmlElement noteXML, NoteGroup noteGroup, Measure measure) {
//		Note note = new Note();
//
//		//basic note stats...
//		//check if note is visible
//		if (noteXML.getAttribute("print-object") == "no"){
//			note.visible = false;
//		}
//		else if (noteGroup.visible == false){
//			//if the noteGroup was invisible because of a hidden note, we'll leave that note invisible
//			//but make the noteGroup container visible
//			noteGroup.visible = true;
//		}
//		
//		//notes either are pitched or unpitched and have either a <pitch> element or <unpitched> element
//		if (noteXML.findElements("pitch").length > 0) {
//			note.pitchName = X.e(noteXML, "pitch step") + X.e(noteXML, "pitch octave");
//		} else if (noteXML.findElements("unpitched").length > 0) {
//			note.pitchName = X.e(noteXML, "unpitched display-step") + X.e(noteXML, "unpitched display-octave");
//			if (noteXML.findElements("instrument").length > 0 && _midiInstrumentsXMLList != null) {
//				String instID = X.a(noteXML, "instrument id");
//				for (var miXML in _midiInstrumentsXMLList) {
//					if (miXML.getAttribute("id") == instID) {
//						note.playbackCents = X.eInt(miXML, "midi-unpitched") * 100 - 100;
//						break;
//					}
//				}
//			}
//		} else {
//			print("unknown note pitch format! $noteXML");
//			note.pitchName = "C4";
//		}
//
//		note.alteration = X.eInt(noteXML, "pitch alter", true);
//		//note.displayCents = PitchTimeConverter.letterToCents(note.pitchName) + (100 * note.alteration);
//		note.displayCents = PitchUtils.pitchNameToDiatonicCents(note.pitchName) + (100 * note.alteration);
//		//note.accidental = (noteXML.findElements("accidental").length > 0) ? X.e(noteXML, "accidental") : AccidentalType.NONE;
//		int accidental = (noteXML.findElements("accidental").length > 0) 
//								? AccidentalType.getAccidentalFromString(X.e(noteXML, "accidental")) 
//								: AccidentalType.NONE;
//		if (accidental != AccidentalType.NONE){
//			note.accidental = accidental;
//			note.showAccidental = true;
//		}
//		else {
//			note.accidental = AccidentalType.getAccidentalType(note.alteration);
//		}
//		note.accidentalPos = -1 * _score.scoreProperties.noteheadWidth; //we won't bother formatting this correctly here
//
//		//get staff number (for sake of knowing the clef) and vertical placement of note
//		//to position the note vertically, we need to know what the current clef is at this note's point in time
//		String clefType = "";
//		for (var clef in measure.clefs) {
//			if (noteGroup.qNoteTime + 0.0001 > clef.qNoteTime) {
//				clefType = clef.type;
//			} else {
//				break;
//			}
//		}
//		
//		//the number of steps above or below the top staff line
//		note.stepsFromTopStaffLine = PitchUtils.getStepsFromTopStaffLine(note.pitchName, clefType);
//		if (noteXML.getAttribute("default-x") != null) {
//			note.hPos = num.parse(noteXML.getAttribute("default-x")) - noteGroup.hPos;
//		}
//		note.vPos = (_score.scoreProperties.staffLineSpacing / 2) * note.stepsFromTopStaffLine;
//
//		//compute leger lines
//		if (note.stepsFromTopStaffLine < -1) { //if the note is above the staff 2 steps or more...
//			//one leger line for every 2 steps. Integer division works in our favor here, since 3 / 2 == 1 
//			//(high Bb is 3 steps above but has only one leger)
//			note.legerLines = note.stepsFromTopStaffLine ~/ 2; 
//		} else if (note.stepsFromTopStaffLine > 9) { //if the note is below the staff 2 steps or more...
//			note.legerLines = (note.stepsFromTopStaffLine - 8) ~/ 2;
//		}
//
//		//get tie state
//		if (noteXML.findElements("tie").length > 0) {
//			//depending on whether there are 2 tie indications or just one...
//			note.tieState = (noteXML.findElements("tie").length == 1) ? X.a(noteXML, "tie type") : TieState.CONTINUE;
//		}
//
//		return note;
//	}
//
//	void createTempoMarker(XmlElement element, num qNoteTime, MeasureStack targetStack) {
//		TempoMarker tempoMarker = new TempoMarker();
//		//create the tempo marker, add it to the current MeasureStack, and time stamp it with the current qNoteTime
//		tempoMarker.qNoteTime = qNoteTime;
//		tempoMarker.tempo = num.parse(element.getAttribute("tempo"));
//
//		if (targetStack.tempoMarkers == null) {
//			targetStack.tempoMarkers = [tempoMarker];
//		} else {
//			//make sure we haven't already added this tempo marker - only add a tempo marker if it 
//			//comes after the last one we've already got
//			if (targetStack.tempoMarkers[targetStack.tempoMarkers.length - 1].qNoteTime < tempoMarker.qNoteTime) {
//				targetStack.tempoMarkers.add(tempoMarker);
//			}
//		}
//	}
//
//	void computeMaxKeySizes() {
//		List<MeasureStack> stacks = _score.getMeasureStacks();
//		int numStacks = stacks.length;
//		for (int i = 0; i < numStacks; i++) {
//			MeasureStack stack = stacks[i];
//			List<Measure> measures = stack.measures;
//			int numMeasures = measures.length;
//			int maxKeySize = 0;
//			for (int j = 0; j < numMeasures; j++) {
//				Measure measure = measures[j];
//				int totalKeySize = PitchUtils.getTotalKeySize(measure.displayKey, measure.outgoingKey);
//				if (totalKeySize > maxKeySize) {
//					maxKeySize = totalKeySize;
//				}
//			}
//			stack.maxKeySize = maxKeySize;
//		}
//	}
//	
//	void _checkPartForErrors(Part part){
//		for (var staff in part.staves){
//			for (var measure in staff.measures){
//				if (measure.voices.length == 0){
//					//make sure measures have at least one voice
//					measure.getVoiceByNumber(1);
//				}
//			}
//		}
//	}
//	
//	//Future _pause(Duration d) async => new Future.delayed(d);
//
//	Score get score {
//		return _score;
//	}
//	
//	XmlElement get musicXML { return _musicXML; }
//
//}
