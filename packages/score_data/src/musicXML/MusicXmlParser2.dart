part of score_data.music_xml;

class MusicXmlParser2 {

	html.Element _musicXML;
	Score _score;
	
	Page _currentPage; //the Page object that Systems are currently being added to
	System _currentSystem; //the System object that MeasureStacks are currently being added to
	MeasureStack _currentStack; //the current MeasureStack object

	////////params passed to parseXML//////
	String _musicXMLString;
	bool _overrideScoreProps;
	
	//if true, max key sizes will be computed for each measure stack - needed if 
	//going straight to rendering without formatting
	bool _computeMaxKeySizeForRendering; 
	ScoreProperties _requestedScoreProps;
	///////////////////////////////////////

	Completer<Score> _parsingCompleter;
	DateTime _lastPauseTime;

	/**
	 * Dispatched when the xml file finishes parsing.
	 * The MusicXMLParser.FINISHED_PARSING constant defines the value of the 
	 * <code>type</code> property of the event object 
	 * for a <code>finishedParsing</code> event.
	 * 
	 * @eventType finishedParsing
	 */
	static const FINISHED_PARSING = "finishedParsing";


	MusicXmlParser2() {
		
	}

	/**
	 * parses the passed in Music XML file into a nEngine.data.containers.Score object
	 * Dispatches a FINISHED_PARSING event when done - access score via score property
	 * @param	musicXML an XML object in the Music XML format
	 * @param 	computeMaxKeySizeForRendering if true, max key sizes will be computed for each measure stack - 
	 * 		leave false if you plan on using the formatter (which does this anyway)
	 * @param	overrideScoreProps if true, when a score is loaded, default score properties are set before 
	 * 		parsing instead of the settings from the XML
	 */
	Future<Score> parseXML(String musicXMLString, [bool computeMaxKeySizeForRendering = true,
							bool overrideScoreProps = false, ScoreProperties scoreProps = null]) {
		_musicXMLString = musicXMLString;
		_computeMaxKeySizeForRendering = computeMaxKeySizeForRendering;
		_overrideScoreProps = overrideScoreProps;
		_requestedScoreProps = scoreProps;
		
		_parsingCompleter = new Completer();
		
		//new Timer(const Duration(milliseconds: 20), _getMusicXMLObject);
		Timer.run(_getMusicXMLObject);
		
		return _parsingCompleter.future;
	}

	ScoreProperties getScoreProperties(html.Element defEl) {
		if (defEl == null) {
			return ScoreProperties.getNewScoreProperties();
		}

		ScoreProperties sProps = ScoreProperties.getNewScoreProperties();

		sProps.mmHeight = _enum(defEl, "scaling millimeters");
		sProps.mmHeight = _enum(defEl, "scaling millimeters");
		sProps.tenths = _enum(defEl, "scaling tenths");


		sProps.pageHeight = _enum(defEl, "page-layout page-height");
		sProps.pageWidth = _enum(defEl, "page-layout page-width");
		sProps.leftPageMargin = _enum(defEl, "page-layout page-margins left-margin");
		sProps.rightPageMargin = _enum(defEl, "page-layout page-margins right-margin");
		sProps.topPageMargin = _enum(defEl, "page-layout page-margins top-margin");
		sProps.bottomPageMargin = _enum(defEl, "page-layout page-margins bottom-margin");

		sProps.systemSpacing = _enum(defEl, "system-layout system-distance");
		sProps.topSystemDistance = _enum(defEl, "system-layout top-system-distance");
		sProps.leftSystemMargin = _enum(defEl, "system-layout system-margins left-margin");
		sProps.rightSystemMargin = _enum(defEl, "system-layout system-margins right-margin");

		sProps.staffSpacing = _enum(defEl, "staff-layout staff-distance");
		if (sProps.staffSpacing == 0) {
			sProps.staffSpacing = 80;
		}

		defEl.querySelectorAll("appearance line-width").forEach((html.Element el){
			switch(el.attributes['type']){
				case 'stem' : sProps.stemWidth = _s2n(el.text); break;
				case 'beam' : sProps.beamWidth = _s2n(el.text); break;
				case 'staff' : sProps.staffLineWidth = _s2n(el.text); break;
				case 'light barline' : sProps.lightBarlineWidth = _s2n(el.text); break;
				case 'heavy barline' : sProps.heavyBarlineWidth = _s2n(el.text); break;
				case 'leger' : sProps.legerLineWidth = _s2n(el.text); break;
				case 'ending' : sProps.repeatEndingWidth = _s2n(el.text); break;
				case 'wedge' : sProps.hairpinLineWidth = _s2n(el.text); break;
				case 'enclosure' : sProps.enclosureWidth = _s2n(el.text); break;
				case 'tuplet bracket' : sProps.tupletBracketWidth = _s2n(el.text); break;
			}
		});		

		defEl.querySelectorAll("appearance note-size").forEach((html.Element el){
			switch(el.attributes['type']){
				case 'grace' : sProps.graceNoteSize = _s2n(el.text); break;
				case 'cue' : sProps.cueNoteSize = _s2n(el.text); break;
			}
		});
		

		//set music spacing values
		sProps.qNoteWidth = 7.4083 * (sProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT); //shorter
		sProps.keySigWidth = 2.0 * (sProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT);
		sProps.timeSigWidth = 4 * (sProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT);
		sProps.clefWidth = 5 * (sProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT);
		sProps.measureLeadIn = 4 * (sProps.tenths / ScoreProperties.STANDARD_MM_HEIGHT);


		return sProps;
	}
	
//		var domParser = new html.DomParser();
//		var doc = domParser.parseFromString(xmlString, "application/xml");
//		print(doc.firstChild.attributes['version']); //2.0  (['house'] == null)
//		print(doc.querySelector('page-height').text); //7.1967
//		print(doc.querySelectorAll("*").where((e) => e.attributes['type'] == 'stem').first.nodeName); //'line-width'
//		print(doc.querySelectorAll('line-width').where((e) => e.attributes['type'] == 'ending').first.text); //1.4583
//		
//		
//		_parsePartwiseScore(doc.querySelector('score-partwise'));
	void _getMusicXMLObject(){
		try {
			var parser = new html.DomParser();
			_musicXML =
				parser.parseFromString(_musicXMLString, 'application/xml')
					.querySelector('score-partwise');
			_musicXMLString = null;
		}
		catch(e){
			_parsingCompleter.completeError(e);
			return;
		}

		////////For memory testing/////////
		//after calling parser.parseFromString(), the memory the XML parser uses
		//is never freed, even after the parser object is set to null. Not sure
		//if this is a Chrome bug or what.
		//_parsingCompleter.complete(_score); //score null at this point
		//return;
		/////////////////
		Timer.run(_parseXML);
	}
	
	void _parseXML(){
		try {
			_lastPauseTime = new DateTime.now();

			//reset vars
			_midiInstrumentsXMLList = null;
			_measureStacks = null;
			_currentTuplets = null;
			_currentSlurs = null;
			_currentPage = null;
			_currentSystem = null;
			_currentStack = null;

			//create the new score
			_score = new Score();


			var defaultsEl = _musicXML.querySelector('defaults');
			_score.scoreProperties = getScoreProperties(defaultsEl);

			var rightsEl = _musicXML.querySelector('identification > rights');
			_score.scoreProperties.rights =
			(rightsEl != null) ? rightsEl.text : null;


			if (_overrideScoreProps) {
				_score.scoreProperties =
				(_requestedScoreProps != null) ? _requestedScoreProps :
				ScoreProperties.getNewScoreProperties();
			}
			//get name of software used to create the XML, if it is available
			var softwareEl = _musicXML.querySelector(
				'identification > encoding > software');
			if (softwareEl != null) {
				_score.scoreProperties.software = softwareEl.text;
			}

			_score.graceNotesNeedFixing = true;

			_getMusicData();
		}
		catch(e){
			_parsingCompleter.completeError(e);
		}
	}

	
	html.ElementList _midiInstrumentsXMLList;
	List<MeasureStack> _measureStacks; //the MeasureStacks that have been created
	//if a tuplet is in the process of being defined, this variable holds that object until 
	//the last note of the tuplet is added
	List<Tuplet> _currentTuplets;
	//if a slur is in the process of being defined, this holds the Slur until the last note of the slur is added
    List<Slur> _currentSlurs; 
    num _partVol;    
    html.ElementList _partXMLList;
    int _cPartIndex;
    
	void _getMusicData() {
		_buildInstrumentsXMLList();

		_measureStacks = [];
		_currentTuplets = [];
		_currentSlurs = [];

		_calculatePartVolumes();
		
		_cPartIndex = 0;
		
		_partXMLList = _musicXML.querySelectorAll("score-partwise > part");

		_processNextPart();
		
	}
	
	void _buildInstrumentsXMLList(){
		_midiInstrumentsXMLList = _musicXML.querySelectorAll("part-list score-part midi-instrument");
	}
	
	void _calculatePartVolumes(){
		_partVol = math.min(1 / _musicXML.querySelectorAll("score-partwise > part").length, 0.15);
	}
	
	html.Element _partXML;
	Part _cPart;
	int _cPartDPQ;
	int _passedTimeDPQ;
	void _processNextPart(){
		if (_cPartIndex >= _partXMLList.length){
			//done processing parts - 
			if (_computeMaxKeySizeForRendering) {
    			computeMaxKeySizes(); //for rendering we need to know how much space the key signatures will take up
    		}
			
			//fix incomplete/overfilled measures
			_adjustMeasureLengthsToFitNotes();
			
			//fix any other score errors
			_checkScoreForErrors();
			
			//send notification we're done
			//html.window.alert('parsing complete');
			_parsingCompleter.complete(_score);
			
			return;
		}
		
		_partXML = _partXMLList[_cPartIndex];
		_cPartIndex++;
		
		_removeIncompleteSlurs();

		_cPart = _createPartObj();

		//ex. 8 divisions per quarter note would imply the shortest duration in the part is a 32nd note
		_cPartDPQ = _eint(_partXML, "measure attributes divisions"); 

		//we'll also time stamp each note with the total number of divisionsPerQuarterNote that have 
		//passed up to its starting point. This will be stored as a number property with the 
		//note (totalDivisions / divisionsPerQuarterNote). But to avoid rounding errors, we'll keep a simple 
		//sum of the divisions that have passed for the given part and use that each time in the calculation
		_passedTimeDPQ = 0; //passed time Divisions Per Quarter note

		if (_createStavesForPart() == false){
			//no measures/staves
			_processNextPart();
			return;
		}
		
		//populate the part with music data		
		//int staffIndex = 0; //MOVED THIS - DOES THIS CAUSE ANY PROBLEMS?
		
		_measureIndex = 0; //the index of the current measure/stack
		_measureXMLList = _partXML.querySelectorAll("measure");
		_measure = null;
		
		_processNextMeasure();
	}
	
	void _removeIncompleteSlurs(){
		//clear out any slurs from the last part which weren't ended properly
		for (var slur in _currentSlurs) {
			int index = slur.firstNote.slurs.indexOf(slur);
			slur.firstNote.slurs.removeAt(index);
			if (slur.firstNote.slurs.length == 0) {
				slur.firstNote.slurs = null;
			}
		}
		_currentSlurs = [];
	}
	
	Part _createPartObj(){
		//create Part object with name and id info
		String staffName = "";
		String abbrName = "";
		int midiPreset = 0;
		int midiChannel = 1;
		_musicXML.querySelectorAll("part-list score-part")
				.where((html.Element el) => el.attributes['id'] == _partXML.attributes['id'])
				.forEach((html.Element scorePartEl){
					staffName = _estr(scorePartEl, "part-name");
					abbrName = _estr(scorePartEl, "part-abbreviation");
					midiPreset = _eint(scorePartEl, "midi-instrument midi-program");
					var channel = _eint(scorePartEl, "midi-instrument midi-channel");
					if (channel > 0) { midiChannel = channel; }
				});

		var cPart = new Part(_partXML.attributes["id"], staffName, abbrName); //the current Part
		cPart.volume = _partVol;
		cPart.midiChannel = midiChannel;
		cPart.midiPreset = midiPreset;

		_score.addPart(cPart);
		
		return cPart;
	}
	
	bool _createStavesForPart(){
		//create the staves and initial clefs for the part
		var measuresXML = _partXML.querySelectorAll("part > measure");
		if (measuresXML.length > 0) {
			html.Element measureXML = measuresXML.first;
			//the first measure defines the number of staves. If it has no <staves> element, there 
			//is 1 staff. Otherwise, the <staves> element indicates the staff count
			int numStaves = _eint(measureXML, "attributes staves");
			if (numStaves < 1) {
				numStaves = 1;
			}

			for (int i = 0; i < numStaves; i++) {
				_cPart.addStaff(new Staff()); //create the staves
			}
			//the first measure also may define a transposition
			if (_estr(measureXML, "attributes transpose") != '') {
				int diatonicTrans = -1 * _eint(measureXML, "attributes transpose diatonic");
				int chromaticTrans = -1 * _eint(measureXML, "attributes transpose chromatic");
				
				//set transposition - use false as no measures exist, so no need to update them
				_cPart.setTransposition(diatonicTrans, chromaticTrans, false); 
			}
			return true;
		} 
		else {
			return false;
		}
	}
	
	int _measureIndex;
	html.ElementList _measureXMLList;
	Measure _measure;
	
	void _processNextMeasure(){

		try {
			if (_measureIndex >= _measureXMLList.length) {
				//done processing measures for this part - go on to the next part
				_checkPartForErrors(_cPart);
				_processNextPart();
				return;
			}

			html.Element measureXML = _measureXMLList[_measureIndex];

			//for each staff we must create a measure
			for (var staff in _cPart.staves) {
				//the previous measure created
				Measure prevMeasure = (staff.measures.length > 0) ? staff
					.measures[staff.measures.length - 1] : null;
				_measure =
					createNewMeasure(measureXML, prevMeasure, _measureIndex);
				if (_score.parts.length == 1) {
					_measure.stack.startTime = _passedTimeDPQ /
						_cPartDPQ; //mark the start DPQ time of the measure
					_measure.stack.endTime = _measure.stack.startTime +
						(_measure.numBeats * (4 / _measure.beatType));
				}
				staff.addMeasure(_measure);
			}


			Voice cVoice = null; //the current Voice
			NoteGroup cNoteGroup = null; //the current NoteGroup

			//holds the last mid-measure clef that has been added to the measure (if any) and
			//has not been assigned to a note.
			Clef midMeasureClef = null;

			//When backup commands are invoked, we set this value to mark our latest point. When we're finished with
			//the entries for the measure, we compare our current passedTimeDPQ value to this stored number to make
			//sure we've filled out the measure. If we haven't, we forward ourselves back up to this value.
			num dpqPositionBeforeBackup = 0;

			int staffIndex = 0;
			//note: measureXML.children fails on iOS
			for (var node in measureXML.childNodes) {
				if (!(node is html.Element)) {
					continue;
				}
				var element = node as html.Element;
				//at this point we're concerned with <note> and <backup> elements - other elements
				//will be handled separately. So only capture these 2 for now.
				String elemName = element.tagName.toString();
				html.Element noteXML;
				if (elemName == "note") {
					noteXML = element;
				} else if (elemName == "backup") {
					//keep track of the duration/time stamping position - <backup> elements imply a voice or
					//staff/voice change, so we subtract the indicated time
					dpqPositionBeforeBackup = _passedTimeDPQ;
					_passedTimeDPQ -= _eint(element, "duration");
					continue;
				} else if (elemName == "forward") {
					/*<forward>
					<duration>1</duration>
					<voice>2</voice> //do we need to pay attention to this?
				  </forward>*/
					//keep track of the duration/time stamping position - <forward> elements imply a voice
					//leaves part of the measure blank, so we add the time to jump forward
					_passedTimeDPQ += _eint(element, "duration");
					continue;
				} else if (_estr(element, "clef") != "") {
					//this is an <attributes> element with one or more <clef> tags. Clefs in MusicXML are either
					//placed at the start of the measureXML element, if they are meant to start the measure, or
					//between notes, if they are meant to be mid-measure. For parts with more than one staff,
					//the clef's have a number attribute (1 for the first staff, 2 for the second, etc.
					//Each Measure object is given a list of all Clef objects it contains. When we first create a
					//Measure (in createMeasure()), the Measure receives a Clef object that matches the last clef
					//in the preceding Measure (if it exists). If a new Clef is declared in the musicXML which falls
					//at the beginning of this Measure, it replaces that copied clef.
					for (html.Element clefXML in element.querySelectorAll(
						"clef")) {
						Clef clef = new Clef();
						int line = _eint(clefXML, "line");
						clef.type =
							ClefType.getClefType(_estr(clefXML, "sign"), line);
						clef.isNew = true;
						clef.show = true;

						staffIndex = (clefXML.attributes["number"] != null)
							? int.parse(clefXML.attributes["number"]) - 1 : 0;
						var targetMeasure = _cPart.staves[staffIndex].measures
							.last;
						//Measure targetMeasure = _cPart.staves[staffIndex].measures[_cPart.staves[staffIndex].measures.length - 1];

						//we decide whether this clef gets added to the list of clefs in the measure or replaces the first
						//based on whether or not any notes have yet been added to this measure. If no notes exist,
						//it should replace any first clef that has been added to the measure
						bool noteHasBeenAdded = false;
						for (var voice in targetMeasure.voices) {
							if (voice.noteGroups.length > 0) {
								noteHasBeenAdded = true;
								break;
							}
						}
						if (noteHasBeenAdded) {
							targetMeasure.clefs.add(clef);
							midMeasureClef = clef;
							clef.qNoteTime =
								_passedTimeDPQ / _cPartDPQ; //3/8/2015
						}
						else {
							clef.qNoteTime = targetMeasure.stack.startTime;
							if (targetMeasure.clefs.length == 0) {
								targetMeasure.clefs.add(clef);
							} else {
								targetMeasure.clefs[0] = clef;
							}
							//make note that this Stack has at least one measure with a new start-of-measure clef
							targetMeasure.stack.newClef = true;

							//since we already created the Measure for this stack, the routine run to make sure new
							//systems always show a full sized clef has been run before this point. We need to do
							//that check again with this new clef (which may be the first clef)
							if (targetMeasure.stack.newSystem) {
								clef.show = true;
								clef.smallSize = false;
							}
						}
					}

					continue;
				} else if (elemName == "sound") {
					//check to see if there is a tempo marker here
					if (element.attributes["tempo"] != null) {
						//MeasureStack targetStack = _cPart.staves[staffIndex].measures[_cPart.staves[staffIndex].measures.length - 1].stack;
						var targetStack = _cPart.staves[staffIndex].measures
							.last.stack;
						createTempoMarker(
							element, _passedTimeDPQ / _cPartDPQ, targetStack,
							null);
					}
					continue;
				} else if (elemName == "direction") {
					//for now we'll only support dynamics
					if (element
						.querySelectorAll("direction-type dynamics")
						.length > 0) {
						staffIndex = (_estr(element, "staff") != "") ? _eint(
							element, "staff") - 1 : 0;
						//Measure targetMeasure = _cPart.staves[staffIndex].measures[_cPart.staves[staffIndex].measures.length - 1];
						var targetMeasure = _cPart.staves[staffIndex].measures
							.last;

						//create the dynamic
						Dynamic dyn = new Dynamic();
						dyn.type = element
							.querySelector("direction-type dynamics *")
							.tagName;
						dyn.isAbove =
						(element.attributes["placement"] == "above");
						//dyn.qNoteTime = _eint(element, "offset") + _passedTimeDPQ / _cPartDPQ;
						dyn.qNoteTime =
							(_eint(element, "offset") + _passedTimeDPQ) /
								_cPartDPQ;
						//dyn.volume = math.pow(_anum(element, "sound dynamics") / 127, 2);
						//if (dyn.volume == 0) dyn.volume = 0.5;
						//if (dyn.volume == 0) dyn.volume = DynamicType.getVolumeByType(dyn.type);
						dyn.volume = DynamicType.getVolumeByType(dyn.type);

						dyn.measure = targetMeasure;
						dyn.width = _score.scoreProperties.noteheadWidth *
							dyn.type.length;
						dyn.height =
							_score.scoreProperties.staffLineSpacing * 2;

						//print('${dyn.type}  ${dyn.qNoteTime}');

						//add it to the measure
						if (targetMeasure.attachments != null) {
							targetMeasure.attachments.add(dyn);
						} else {
							targetMeasure.attachments = [dyn];
						}
					}
					else if (element.querySelector("sound[tempo]") != null) {
						//else if (X.a(element, "sound tempo") != null) {
						var targetStack = _cPart.staves[staffIndex].measures
							.last.stack;
						var metronomeEl = element.querySelector(
							"direction-type > metronome");
						createTempoMarker(element.querySelector("sound"),
							_passedTimeDPQ / _cPartDPQ,
							targetStack, metronomeEl);
					}

					continue;
				} else
				if (elemName == "barline" && _cPart == _score.parts.first) {
					var targetStack = _cPart.staves[staffIndex].measures.last
						.stack;
					if (targetStack.barline == null) {
						var barline = new Barline();
						barline.location = BarlineLocation.getLocation(
							element.attributes['location']);
						var styleEl = element.querySelector('bar-style');
						barline.style = (styleEl != null)
							? BarlineStyle.getStyle(styleEl.text)
							: BarlineStyle.getStyle(null);
						targetStack.barline = barline;
					}
					var repeatEl = element.querySelector('repeat');
					var endingEl = element.querySelector('ending');

					if ((repeatEl != null || endingEl != null) &&
						targetStack.repeatDOs == null) {
						targetStack.repeatDOs = [];
					}

					if (repeatEl != null) {
						var repeatDO = new RepeatDO();
						repeatDO.repeatDirection = RepeatDirection.getDirection(
							repeatEl.attributes['direction']);
						String repeatTimesStr = repeatEl.attributes['times'];
						repeatDO.repeatTimes = (repeatTimesStr != null)
							? int.parse(repeatTimesStr)	: 1;
						//repeatDO.repeatTimes = repeatEl.attributes['times'];
						//if (repeatDO.repeatTimes == null) {
						//	repeatDO.repeatTimes = 1;
						//}
						targetStack.repeatDOs.add(repeatDO);
					}
					if (endingEl != null) {
						var repeatDO = new RepeatDO();
						repeatDO.endingNumber = endingEl.attributes['number'];
						repeatDO.endingType =
							EndingType.getType(endingEl.attributes['type']);
						targetStack.repeatDOs.add(repeatDO);
					}

					continue;
				}
				else {
					continue;
				}
				//figure out which Staff the note goes on
				int staffNum = (noteXML.querySelector("staff") == null)
					? 1
					: _eint(noteXML, "staff");
				Staff cStaff = _cPart.staves[staffNum - 1]; //the current staff

				//get the current measure
				var cMeasure = cStaff.measures[cStaff.measures.length - 1];

				//get or create the current Voice in the current measure
				int voiceNum = _eint(noteXML, "voice");
				cVoice = cMeasure.getVoiceByNumber(voiceNum);


				//get or create the current NoteGroup
				if (noteXML.querySelector("chord") == null) {
					cNoteGroup = createNoteGroup(noteXML, cMeasure);
					cVoice.addNoteGroup(cNoteGroup);

					//add the time stamp info to the note and increment the passedTime
					cNoteGroup.qNoteTime =
						_passedTimeDPQ / _cPartDPQ; //qnote time
					cNoteGroup.qNoteDuration = cNoteGroup.duration / _cPartDPQ;
					_passedTimeDPQ += cNoteGroup.duration;
					//we now change the duration value to be in terms of our duration units (1024
					//per quarter note). This must happen AFTER calculating the qNoteDuration from the
					//original cNoteGroup.duration (which has tuplet ratio modification built into it)
					cNoteGroup.duration = DurationType.getDurationValue(
						cNoteGroup.durationType, cNoteGroup.numDots);

					//check if a mid-measure clef has been defined - if so, assign it to this note and then set
					//it to null so that it won't be assigned to another NoteGroup.
					//3/8/2015 - modified to check qNoteTime of clef equals or precedes NoteGroup (in case we backed up)
					if (midMeasureClef != null &&
						midMeasureClef.qNoteTime <= cNoteGroup.qNoteTime) {
						//midMeasureClef.qNoteTime = cNoteGroup.qNoteTime; //3/8/2015
						cNoteGroup.clef = midMeasureClef;
						midMeasureClef = null;
					}
				}

				//create the new note and add it to the NoteGroup
				if (!cNoteGroup.isRest) {
					Note cNote = createNote(noteXML, cNoteGroup, cMeasure);
					//slightly faster - depends on musicXML putting notes in bottom up order (I've found an exception)
					//cNoteGroup.addNote(cNote);

					//safer method
					cNoteGroup.insertNote(cNote);

					//also check to see if the stem position needs to be updated
					if (cNoteGroup.notes.length == 1) {
						cNoteGroup.stemStartPos = cNote.vPos;
					} else {
						if (cNote.hPos != 0) {
							cNoteGroup.stemHPos =
								_score.scoreProperties.noteheadWidth;
						}
						cNoteGroup.stemStartPos =
						(cNoteGroup.stemDirection == StemDirection.UP)
							? cNoteGroup.notes[0].vPos
							: cNoteGroup.notes[cNoteGroup.notes.length - 1]
							.vPos;
					}
				}
			}

			//make sure passedTimeDPQ has been forwarded to the end of the measure - a
			//partially complete layer could have left it in the middle of the measure
			if (!_measure.stack.isPickup) {
				_passedTimeDPQ = (_measure.stack.endTime * _cPartDPQ).round();
			} else if (_passedTimeDPQ <
				dpqPositionBeforeBackup) { //EXPERIMENTAL ADDITION
				_passedTimeDPQ = dpqPositionBeforeBackup.round();
			}

			//update the end time and duration of the stack with the info from the measure
			if (_score.parts.length == 1) {
				_measure.stack.endTime = _passedTimeDPQ / _cPartDPQ;
			}

			_measureIndex++;

			//Timer.run(_processNextMeasure);
			DateTime currentTime = new DateTime.now();
			if (currentTime
				.difference(_lastPauseTime)
				.inMilliseconds > 100) {
				_lastPauseTime = currentTime;
				//new Timer(const Duration(milliseconds: 20), _processNextMeasure);
				Timer.run(_processNextMeasure);
			}
			else {
				_processNextMeasure();
			}
		}
		catch(e){
			print('parse fail on measureIndex: ${_measureIndex}');
			_parsingCompleter.completeError(e);
			return;
		}
	}

	Measure createNewMeasure(html.Element measureXML, Measure previousMeasure, int measureIndex) {
		//create the measure
		Measure measure = new Measure();

		//initialize key, time and clef with settings from previous measure and then override 
		//them if there are new values in the XML
		bool reParentedMidMeasureClef = false;
		if (previousMeasure != null) {
			//measure.transposition = previousMeasure.transposition;
			measure.diatonicTransposition = previousMeasure.diatonicTransposition;
			measure.chromaticTransposition = previousMeasure.chromaticTransposition;
			measure.concertKey = previousMeasure.concertKey;
			measure.displayKey = previousMeasure.displayKey;
			measure.isMajorKey = previousMeasure.isMajorKey;
			measure.numBeats = previousMeasure.numBeats;
			measure.beatType = previousMeasure.beatType;
			measure.beatGroups = previousMeasure.beatGroups.sublist(0);
			
			var prevClef = previousMeasure.clefs.last;
			//check for the unusual situation where the previous clef was a mid-measure clef assigned 
			//to the very end of the bar. It won't have been assigned to a note (which is necessary), 
			//so we're going to reparent it to the start of this bar.
			if (prevClef.qNoteTime == previousMeasure.stack.endTime){
				measure.clefs.add(previousMeasure.clefs.removeLast());
				prevClef.qNoteTime = previousMeasure.stack.endTime;
				prevClef.isNew = true;
				reParentedMidMeasureClef = true;
			}
			else {
				//create the first clef for the measure to match the last clef's type from the previous measure
				Clef clef = new Clef(); 
				clef.type = prevClef.type;
				clef.qNoteTime = previousMeasure.stack.endTime;
				if (measure.clefs.length == 0) {
					measure.clefs.add(clef);
				}
				else {
					measure.clefs[0] = clef;
				}
			}
			
		}
		else {
			//EXPERIMENTAL - give measure a default clef. This SHOULD get overwritten, except with bad xml files
			Clef clef = new Clef();
			clef.type = ClefType.TREBLE;
			clef.qNoteTime = 0;
			clef.show = true;
			clef.smallSize = false;
			measure.clefs.add(clef);
		}


		//get the measure stack for the current index, or create one
		MeasureStack stack = null;
		if (_measureStacks.length > measureIndex) {
			stack = _measureStacks[measureIndex];
		} 
		else {
			stack = new MeasureStack();
			try {
				stack.number = int.parse(measureXML.attributes["number"]);
			}
			catch (e){
				if ((_measureStacks.length > 1 && _measureStacks[0].isPickup) ||
						measureXML.attributes["implicit"] == "yes"){
					stack.number = measureIndex;
				}
				else {
					stack.number = measureIndex + 1;
				}
			}
			//see if it's a pickup measure - measure 0 is probably a better guide than "implicit"
			if (measureXML.attributes["implicit"] == "yes" && stack.number == 0) { 
				stack.isPickup = true;
			}
			stack.startPosition = (previousMeasure != null) 
									? previousMeasure.stack.width + previousMeasure.stack.startPosition : 0;
			stack.width = (measureXML.attributes["width"] != null)? num.parse(measureXML.attributes["width"]) : 0;

			if (_currentStack != null) { //update the linked list properties
				_currentStack.next = stack;
				stack.previous = _currentStack;
			}

		}

		_currentStack = stack;

		//give the measure a reference to the stack it belongs to
		measure.stack = stack;
		
		//handle the special case of a clef that was re-parented from previous measure to this one
		if (reParentedMidMeasureClef){
			stack.newClef = true;
		}

		//add the measure to the stack
		stack.addMeasure(measure);

		if (stack.systemRef != null) {
			_currentSystem = stack.systemRef;
		}

		//handle the properties set in <print/> tags - includes info for new pages and systems
		Page page;
		System system;
		//we ALWAYS have to make sure the first stack is set to new page and new system - 
		//NoteFlight doesn't add these markers
		if (measureXML.querySelector("print") != null || _measureStacks.length == 0) { 
			//check for situations where there are new pages and/or new systems
			//note that we special case the first system in the piece in case it isn't marked (I'm finding 
			//this when re-saving a MusicXML file after opening the xml in Finale)
			
			if (_estr(measureXML, "print page-number") != "" || 
					measureXML.querySelectorAll("print").where((e)=>e.attributes['new-page'] == 'yes').length > 0 ||
						//measureXML.querySelector("print[new-page='yes'") != null || 
						measureIndex == 0) { //the standard tag for new page
				if (stack.systemRef == null || !stack.systemRef.newPage) {
					//create a new page and a new system - update their linked list properties
					page = new Page();
					system = new System(_score.scoreProperties);
					page.addSystem(system);
					_score.addPage(page);
					if (_currentPage != null) {
						_currentPage.next = page;
						_currentSystem.next = system;
						page.previous = _currentPage;
						system.previous = _currentSystem;
					}
					_currentPage = page;
					_currentSystem = system;

					system.newPage = true;
					stack.newSystem = true;
					stack.startPosition = 0;
				}
			}
			else if (measureXML.querySelectorAll('print').where((e)=>e.attributes['new-system'] == 'yes').length > 0){
			//else if (measureXML.querySelector("print[new-system='yes']") != null) { //the standard tag for new system
				if (!stack.newSystem) {
					//create a new system - update the linked list properties
					system = new System(_score.scoreProperties);
					_currentPage.addSystem(system);
					if (_currentSystem != null) {
						_currentSystem.next = system;
						system.previous = _currentSystem;
					}
					_currentSystem = system;

					stack.newSystem = true;
					stack.startPosition = 0;
				}
			}

			//check to see if this system is indented
			num val = _enum(measureXML, "system-layout system-margins left-margin");
			if (val != 0) {
				//print('indent: $val');
				_currentSystem.indent = val;
			}

		}

		//add the stack to the current system (necessary to do it here, because if it goes on a new system, 
		//the system won't be created until this point.
		if (_measureStacks.length <= measureIndex) {
			_currentSystem.addMeasureStack(stack, false);
			_measureStacks.add(stack);
		}


		//always show clef and key at beginning of new system. These don't show in XML unless they are 
		//new to this staff, so we have to infer that they should be here.
		//if (measure.newSystem) {
		if (stack.newSystem) {
			//measure.showClef = true;
			if (measure.clefs.length > 0) {
				measure.clefs[0].show = true;
				measure.clefs[0].smallSize = false;
			}
			measure.showKey = true;
		}

		//handle the properties set in <attributes/> tags, including key, time and clef info
		html.Element attXML = measureXML.querySelector("attributes");
		if (attXML != null) {
			//transposition
			if (attXML.querySelector("transpose") != null) {
				measure.diatonicTransposition = -1 * _eint(attXML, "transpose diatonic");
				measure.chromaticTransposition = -1 * _eint(attXML, "transpose chromatic");
			}
			//key signature
			if (_estr(attXML, "key fifths") != "") {
				html.Element keyXML = attXML.querySelector("key");
				measure.displayKey = _eint(keyXML, "fifths");
				measure.concertKey = measure.displayKey - 
						PitchUtils.getKeySigAlterationForTransposition(measure.diatonicTransposition, 
																		measure.chromaticTransposition);
				measure.outgoingKey = (previousMeasure != null) ? previousMeasure.displayKey : 0;
				
				if (keyXML.querySelector("mode") != null) {
					String mode = _estr(keyXML, "mode").toLowerCase();
					measure.isMajorKey = (mode == "major" || mode == "(unknown)");
				} else {
					measure.isMajorKey = true;
				}

				measure.showKey = true;
				stack.newKey = true; //make note now that this stack has started a new key signature
			}

			//time signature
			if (_estr(attXML, "time beats") != "") {
				html.Element timeXML = attXML.querySelector("time");
				measure.numBeats = _eint(timeXML, "beats");
				measure.beatType = _eint(timeXML, "beat-type");
				measure.showTime = true;
				//stack.newTime = true;

				_updateMeasureBeatGroups(measure);
			}
		}

		return measure;
	}
	
	void _updateMeasureBeatGroups(Measure measure){
		//create a beatGroupings Array that lists the counts of the primary 
		//beats ([0,1,2,3] in 4/4, [0,1.5] in 6/8, etc.)
		List<num> beatGroups = [];
		for (int i = 0; i < measure.numBeats; i++) {
			//if it's not compound, or if it is compound and this is the third beat (first, fourth, 7th, etc.)
			if (measure.beatType % 8 != 0 || i % 3 == 0) { 
				beatGroups.add(i * (4 / measure.beatType));
			}
		}
		measure.beatGroups = beatGroups;
	}

	NoteGroup createNoteGroup(html.Element noteXML, Measure cMeasure) {
		NoteGroup noteGroup = new NoteGroup();
		
		//check to see if this noteGroup is visible
		if (noteXML.attributes["print-object"] == "no"){
			noteGroup.visible = false;
  		}

		//get properties shared between notes and rests
		if (noteXML.querySelector("duration") != null) {
			noteGroup.duration = _eint(noteXML, "duration");
		} else {
			noteGroup.duration = 0;
		}
		//the duration type of the note - if not present, it's a whole rest
		noteGroup.durationType = (noteXML.querySelector("type") != null) 
											? DurationType.getDurationType(_estr(noteXML, "type")) 
											: DurationType.WHOLE; 
		noteGroup.isGrace = ((noteXML.querySelector("grace") != null) || noteGroup.duration == 0);
		//if no horizontal placement is specified, it's a default rest
		noteGroup.hPos = (noteXML.attributes["default-x"] != null) 
											? num.parse(noteXML.attributes["default-x"]) 
											: cMeasure.stack.width / 2; 

		//augmentation dots
		noteGroup.numDots = noteXML.querySelectorAll("dot").length;

		//tuplets - for a tuplet, we create a Tuplet object, fill in properties for appearance, and 
		//assign it to the first note of the tuplet. We keep track of the tuplet in a member variable 
		//here, and then when the last note of the tuplet comes, we add that note to the Tuplet object.
		List<Tuplet> tupletsToRemove = [];
		html.Element notationsXML = noteXML.querySelector("notations");
		html.ElementList tupletsXML = (notationsXML == null)? null : notationsXML.querySelectorAll("tuplet");
		if (tupletsXML != null) {
			//do this as a loop, as it's possible to have a one note tuplet that serves as start and stop
			for (html.Element tupletXML in tupletsXML) { 
				if (tupletXML.attributes["type"] == "start") {
					Tuplet tuplet = new Tuplet();
					tuplet.tupletID = (tupletXML.attributes['number'] != null)
													? int.parse(tupletXML.attributes["number"]) : 0;
					tuplet.firstNote = noteGroup;
					tuplet.above = (tupletXML.attributes["placement"] == "above");

					//get the tuplet numerator (the 3 for 3 in the space of 2)
					int numDots;
					int tupletDurType;
					if (tupletXML.querySelector("tuplet-actual") != null) {
						html.Element tupActualXML = tupletXML.querySelector("tuplet-actual");
						tuplet.numerator = _eint(tupActualXML, "tuplet-number");
						numDots = (tupActualXML.querySelector("tuplet-dot") != null)
													? tupActualXML.querySelectorAll("tuplet-dot").length : 0;
						tupletDurType = DurationType.getDurationType(_estr(tupActualXML, "tuplet-type"));
						tuplet.numeratorDuration = DurationType.getDurationValue(tupletDurType, numDots);
					} else {
						tuplet.numerator = _eint(noteXML, "time-modification actual-notes");
						tuplet.numeratorDuration = DurationType.getDurationValue(noteGroup.durationType, 
																					noteGroup.numDots);
					}

					//get the tuplet denominator (the 2 for 3 in the space of 2)
					if (tupletXML.querySelector("tuplet-normal") != null) {
						html.Element tupNormalXML = tupletXML.querySelector("tuplet-normal");
						tuplet.denominator = _eint(tupNormalXML, "tuplet-number");
						numDots = (tupNormalXML.querySelector("tuplet-dot") != null) 
													? tupNormalXML.querySelectorAll("tuplet-dot").length : 0;
						tupletDurType = DurationType.getDurationType(_estr(tupNormalXML, "tuplet-type"));
						tuplet.denominatorDuration = DurationType.getDurationValue(tupletDurType, numDots);
					} else {
						tuplet.denominator = _eint(noteXML, "time-modification normal-notes");
						numDots = noteXML.querySelectorAll("time-modification normal-dot").length;
						var durString = _estr(noteXML, "time-modification normal-type");
						tupletDurType = (durString != "")? DurationType.getDurationType(durString) : noteGroup.durationType;
						
						tuplet.denominatorDuration = DurationType.getDurationValue(tupletDurType, numDots);
					}

					_currentTuplets.add(tuplet);

				} else if (tupletXML.attributes["type"] == "stop" && _currentTuplets.length > 0) {
					int tupletID = _aint(tupletXML, 'number');
					Tuplet tuplet = _currentTuplets[0];
					for (var tup in _currentTuplets) {
						if (tup.tupletID == tupletID) {
							tuplet = tup;
							break;
						}
					}
					tuplet.endNote = noteGroup;

					tupletsToRemove.add(tuplet);
				}
			}
		}
		//add our tuplets to each of the NoteGroups and then remove any tuplets from the list that have been finished
		if (_currentTuplets.length > 0) {
			noteGroup.tuplets = _currentTuplets.sublist(0);

			if (tupletsToRemove.length > 0) {
				for (var tupletToRemove in tupletsToRemove) {
					for (int i = 0; i < _currentTuplets.length; i++) {
						if (tupletToRemove == _currentTuplets[i]) {
							_currentTuplets.removeAt(i);
						}
					}
				}
			}
		}

		//slurs
		html.ElementList slursXML = (notationsXML != null) ? notationsXML.querySelectorAll("slur") : null;
		if (slursXML != null) {
			for (html.Element slurXML in slursXML) {
				Slur slur = null;
				if (slurXML.attributes["type"] == TieState.START) {
					//create the slur and add set its firstNote property to the current NoteGroup
					slur = new Slur();
					slur.slurID = int.parse(slurXML.attributes["number"]);
					slur.firstNote = noteGroup;
					_currentSlurs.add(slur);
				} else if (slurXML.attributes["type"] == TieState.STOP) {
					//this is the last note of the slur - find the slur with matching ID and mark its 
					//end note property as this NoteGroup
					int slurID = int.parse(slurXML.attributes["number"]);

					//go through slurs in reverse order to find most recent (and likely) match
					int numSlurs = _currentSlurs.length;
					int slurIndex = numSlurs - 1;
					while (slurIndex >= 0) {
						if (_currentSlurs[slurIndex].slurID == slurID) {
							slur = _currentSlurs[slurIndex];
							break;
						}
						slurIndex--;
					}

					if (slur != null) {
						slur.endNote = noteGroup;
						//remove the slur from our current slurs
						int index = _currentSlurs.indexOf(slur);
						_currentSlurs.removeAt(index);
					}
				}

				//assign this slur to the slurs list for the NoteGroup, creating the list if it doesn't exist
				if (slur != null) {
					if (noteGroup.slurs == null) {
						noteGroup.slurs = [slur];
					} else {
						noteGroup.slurs.add(slur);
					}
				}
			}
		}
		
		//articulations
		html.ElementList notationsElements = noteXML.querySelectorAll('notations');
		if (notationsElements.length > 0){
			html.ElementList articulationElements = notationsElements[0].querySelectorAll('articulations');
			if (articulationElements != null && articulationElements.length > 0) {
				for (html.Node node in articulationElements[0].childNodes) {
					if (!(node is html.Element)){
						continue;
					}
					var articXML = node as html.Element;
					var articulation = new Articulation();
					articulation.type = ArticulationType.getTypeFromName(articXML.tagName);
					String hPos = articXML.attributes['default-x'];
					String vPos = articXML.attributes['default-y'];
					articulation.hPos = (hPos != null) ? num.parse(hPos) : 0;
					articulation.vPos = (vPos != null) ? -1 * num.parse(vPos) : 0;
					articulation.isAbove = articXML.attributes["placement"] == "above";
					articulation.noteGroup = noteGroup;
					articulation.getWidthHeight();

					if (noteGroup.articulations == null) {
						noteGroup.articulations = [];
					}
					noteGroup.articulations.add(articulation);
				}
			}
		}

		//add the lyric syllable if this notegroup has one
		if (noteXML.querySelector("lyric") != null) {
			html.Element lyricXML = noteXML.querySelector("lyric");
			var lyric = new Lyric(_estr(lyricXML, "syllabic"), _estr(lyricXML, "text"), 
									_aint(lyricXML, "number"), 0, _aint(lyricXML, "default-y", false));
			if (lyric.vPos == null){
				lyric.vPos = _score.scoreProperties.staffLineSpacing * -8;
			}
			noteGroup.lyric = lyric;
		}

		if (noteXML.querySelector("rest") != null) {
			noteGroup.isRest = true;
			
			//this property exists only if the rest is not in default position
			if (_estr(noteXML, "rest display-step") != "") { 
				//get staff number (for sake of knowing the clef) and vertical placement of rest
				//var staffNum:Int = (noteXML.staff == undefined)? 1 : int(noteXML.staff[0]);
				//to position the rest vertically, we need to know what the current clef is 
				//at this note's point in time
				String clefType = (cMeasure.clefs.length > 0) 
											? cMeasure.clefs[cMeasure.clefs.length - 1].type 
											: ClefType.TREBLE;

				String pitchName = _estr(noteXML, "rest display-step") + _estr(noteXML, "rest display-octave");
				//the number of steps above or below the top staff line
				int stepsFromTopStaffLine = PitchUtils.getStepsFromTopStaffLine(pitchName, clefType); 
				noteGroup.restVPos = (_score.scoreProperties.staffLineSpacing / 2) * stepsFromTopStaffLine;
			} else { //it's a normal rest, centered vertically
				noteGroup.restVPos = _score.scoreProperties.staffLineSpacing * 2;
			}
			if (noteGroup.durationType == DurationType.WHOLE) {
				noteGroup.restVPos -= 0.5 * _score.scoreProperties.staffLineSpacing;
			} else if (noteGroup.durationType == DurationType.HALF) {
				noteGroup.restVPos -= 0.3 * _score.scoreProperties.staffLineSpacing;
			}

			return noteGroup; //rests have no more properties
		}

		//get properties unique to notes
		html.ElementList beamsXML = noteXML.querySelectorAll("beam");
		for (html.Element beamXML in beamsXML) {
			noteGroup.beamStates.add(beamXML.text);
		}

		if (noteXML.attributes["default-x"] != null) {
			noteGroup.hPos = num.parse(noteXML.attributes["default-x"]);
		}

		String stemDirection;
		if (noteXML.querySelector("stem") != null) {
			stemDirection = _estr(noteXML, "stem");
			if (noteXML.querySelector("stem[default-y]") != null) {
				noteGroup.stemEndPos = -1 * num.parse(noteXML.querySelector("stem[default-y]").attributes['default-y']);
			}
		} else if (noteGroup.durationType == DurationType.WHOLE) {
			stemDirection = StemDirection.NO_STEM;
		} else {
			//it's not a whole note, but the musicXML was evidently still missing a stem 
			//declaration (Noteflight leaves it out)
			stemDirection = StemDirection.UP; //just default to up - we'll correct it later
		}
		noteGroup.stemDirection = stemDirection;
		noteGroup.stemHPos = (stemDirection == StemDirection.UP) ? _score.scoreProperties.noteheadWidth : 0;

		return noteGroup;
	}

	Note createNote(html.Element noteXML, NoteGroup noteGroup, Measure measure) {
		Note note = new Note();

		//basic note stats...
		//check if note is visible
		if (noteXML.attributes["print-object"] == "no"){
			//3/31/2015 this creates problems, because we depend on at least one note being visible
			//the NoteGroup can be invisible, but the notes should not be, by default
			//note.visible = false; 
		}
		else if (noteGroup.visible == false){
			//if the noteGroup was invisible because of a hidden note, we'll leave that note invisible
			//but make the noteGroup container visible
			noteGroup.visible = true;
		}
		
		//notes either are pitched or unpitched and have either a <pitch> element or <unpitched> element
		if (noteXML.querySelector("pitch") != null) {
			note.pitchName = _estr(noteXML, "pitch step") + _estr(noteXML, "pitch octave");
		} else if (noteXML.querySelector("unpitched") != null) {
			note.pitchName = _estr(noteXML, "unpitched display-step") + _estr(noteXML, "unpitched display-octave");
			if (noteXML.querySelector("instrument") != null && _midiInstrumentsXMLList != null) {
				String instID = noteXML.querySelector("instrument").attributes['id'];
				for (html.Element miXML in _midiInstrumentsXMLList) {
					if (miXML.attributes["id"] == instID) {
						note.playbackCents = _eint(miXML, "midi-unpitched") * 100 - 100;
						break;
					}
				}
			}
		} else {
			print("unknown note pitch format! $noteXML");
			note.pitchName = "C4";
		}

		int alteration = _eint(noteXML, "pitch alter");
		note.alteration = alteration;
        note.displayCents = PitchUtils.pitchNameToDiatonicCents(note.pitchName) + (100 * alteration);
		int accidental;
		if (alteration < 3 && alteration > -3){
			accidental = (noteXML.querySelector("accidental") != null) 
									? AccidentalType.getAccidentalFromString(_estr(noteXML, "accidental")) 
									: AccidentalType.NONE;
		}
		else {
			//this note is starting with a huge alteration - let's change it to an enharmonic equivalent
			String newPitchName = PitchUtils.getCommonPitchNameFromCents(note.displayCents);
			note.alteration = PitchUtils.getAlterationForCents(note.displayCents, newPitchName);
			note.pitchName = newPitchName;
			accidental = AccidentalType.NONE;
		}
		if (accidental != AccidentalType.NONE){
			note.accidental = accidental;
			note.showAccidental = true;
		}
		else {
			note.accidental = AccidentalType.getAccidentalType(note.alteration);
		}
		note.accidentalPos = -1 * _score.scoreProperties.noteheadWidth; //we won't bother formatting this correctly here

		//get staff number (for sake of knowing the clef) and vertical placement of note
		//to position the note vertically, we need to know what the current clef is at this note's point in time
		String clefType = "";
		for (var clef in measure.clefs) {
			if (noteGroup.qNoteTime + 0.0001 > clef.qNoteTime) {
				clefType = clef.type;
			} else {
				break;
			}
		}
		
		//the number of steps above or below the top staff line
		note.stepsFromTopStaffLine = PitchUtils.getStepsFromTopStaffLine(note.pitchName, clefType);
		if (noteXML.attributes["default-x"] != null) {
			note.hPos = num.parse(noteXML.attributes["default-x"]) - noteGroup.hPos;
		}
		note.vPos = (_score.scoreProperties.staffLineSpacing / 2) * note.stepsFromTopStaffLine;

		//compute leger lines
		if (note.stepsFromTopStaffLine < -1) { //if the note is above the staff 2 steps or more...
			//one leger line for every 2 steps. Integer division works in our favor here, since 3 / 2 == 1 
			//(high Bb is 3 steps above but has only one leger)
			note.legerLines = note.stepsFromTopStaffLine ~/ 2; 
		} else if (note.stepsFromTopStaffLine > 9) { //if the note is below the staff 2 steps or more...
			note.legerLines = (note.stepsFromTopStaffLine - 8) ~/ 2;
		}

		//get tie state
		html.ElementList tieXMLs = noteXML.querySelectorAll('tie');
		if (tieXMLs.length > 0) {
			//depending on whether there are 2 tie indications or just one...
			note.tieState = (tieXMLs.length == 1) ? tieXMLs.first.attributes["type"] : TieState.CONTINUE;
		}

		return note;
	}

	void createTempoMarker(html.Element element, num qNoteTime, MeasureStack targetStack, 
	                       html.Element metronomeEl) {
		TempoMarker tempoMarker = new TempoMarker();
		num tempoFac = 1.0;
		if (metronomeEl != null){
			if (metronomeEl.querySelector('beat-unit') != null){
				int durationType = DurationType.getDurationType(metronomeEl.querySelector('beat-unit').text);
				int numDots = (metronomeEl.querySelector('dotted') != null)? 1 : 0;
				int duration = DurationType.getDurationValue(durationType, numDots);
				tempoFac = duration / 1024;
			}
		}
		//create the tempo marker, add it to the current MeasureStack, and time stamp it with the current qNoteTime
		tempoMarker.qNoteTime = qNoteTime;
		tempoMarker.tempo = num.parse(element.attributes["tempo"]) * tempoFac;

		if (targetStack.tempoMarkers == null) {
			targetStack.tempoMarkers = [tempoMarker];
		} else {
			//make sure we haven't already added this tempo marker - only add a tempo marker if it 
			//comes after the last one we've already got
			if (targetStack.tempoMarkers[targetStack.tempoMarkers.length - 1].qNoteTime < tempoMarker.qNoteTime) {
				targetStack.tempoMarkers.add(tempoMarker);
			}
		}
	}

	void computeMaxKeySizes() {
		List<MeasureStack> stacks = _score.getMeasureStacks();
		int numStacks = stacks.length;
		for (int i = 0; i < numStacks; i++) {
			MeasureStack stack = stacks[i];
			List<Measure> measures = stack.measures;
			int numMeasures = measures.length;
			int maxKeySize = 0;
			for (int j = 0; j < numMeasures; j++) {
				Measure measure = measures[j];
				int totalKeySize = PitchUtils.getTotalKeySize(measure.displayKey, measure.outgoingKey);
				if (totalKeySize > maxKeySize) {
					maxKeySize = totalKeySize;
				}
			}
			stack.maxKeySize = maxKeySize;
		}
	}
	
	void _checkPartForErrors(Part part){
		for (var staff in part.staves){
			for (var measure in staff.measures){
				if (measure.voices.length == 0){
					//make sure measures have at least one voice
					measure.getVoiceByNumber(1);
				}
				for (var voice in measure.voices){
					for (var ng in voice.noteGroups){
						if (ng.isRest) { continue; }
						for (var note in ng.notes){
							if (note.tieState == TieState.START || note.tieState == TieState.CONTINUE){
								var nextNG = ng.next;
								if (nextNG == null || nextNG.isRest){
									//tied to a rest or is last note? kill the tie
									note.tieState = TieState.NONE;
								}
								else {
									bool matchFound = false;
									for (var nextNote in nextNG.notes){
										if ((nextNote.tieState == TieState.CONTINUE ||
												nextNote.tieState == TieState.STOP) &&
												nextNote.pitchName == note.pitchName &&
												nextNote.alteration == note.alteration){
											matchFound = true;
											break;
										}
									}
									if (!matchFound){
										//no matching tie found - kill the tie
										note.tieState = TieState.NONE;
									}
								}
							}
						}
					}
				}
			}
		}
	}
	
	void _checkScoreForErrors(){
		var firstStack = _score.parts[0].staves[0].measures[0].stack;
		if (firstStack.newKey == false){
			//make sure first measure is set to have a new key
			firstStack.newKey = true;
			for (var measure in firstStack.measures){
				measure.showKey = true;
			}
		}
	}
	
	void _adjustMeasureLengthsToFitNotes(){
		var stacks = _score.getMeasureStacks();
		num currentQNoteOffset = 0;
		for (var stack in stacks){
			//update the stacks and NoteGroups with the current offset and
			//find the latest note in any measure of the stack
			stack.startTime += currentQNoteOffset;
			stack.endTime += currentQNoteOffset;
			num stackStartTime = stack.startTime;
			num latestNoteEndTime = stackStartTime; //qNoteEndTime of latest note in bar
			for (var measure in stack.measures){
				for (var voice in measure.voices){
					for (var ng in voice.noteGroups){
						ng.qNoteTime += currentQNoteOffset;
						if (ng.tuplets != null && ng.tuplets.length > 0){
							//for tuplets, we base get the duration of the outer-most tuplet and use
							//that in place of the NoteGroup's qNoteDuration to prevent rounding errors
							var tuplet = ng.tuplets[0];
							num tupletQNoteEndTime = tuplet.firstNote.qNoteTime + 
										tuplet.denominator * tuplet.denominatorDuration / DurationType.QUARTER;
							if (tupletQNoteEndTime > latestNoteEndTime){
								latestNoteEndTime = tupletQNoteEndTime;
							}
						}
						else if (ng.qNoteTime + ng.qNoteDuration > latestNoteEndTime){
							latestNoteEndTime = ng.qNoteTime + ng.qNoteDuration;
						}
					}
				}
				if (currentQNoteOffset != 0){
					for (var clef in measure.clefs){
						clef.qNoteTime += currentQNoteOffset;
					}
					for (var attachment in measure.attachments){
						attachment.qNoteTime += currentQNoteOffset;
					}
				}
			}
			//update tempo marker positions
			if (currentQNoteOffset != 0 && stack.tempoMarkers != null){
				for (var tm in stack.tempoMarkers){
					tm.qNoteTime += currentQNoteOffset;
				}
			}
			
			//edit the time signature of the measures if necessary and adjust the offset
			if (latestNoteEndTime != stack.endTime){
				if (latestNoteEndTime == stack.startTime){
					//special case the situation where no notes existed in the bars
					continue;
				}
				else {
					//determine if we can fit the notes evenly into a new time signature
					int newNumerator;
					int newDenominator;
					
					num stackNewQNoteDur = latestNoteEndTime - stackStartTime;
					//print('stackQNoteDur: $stackNewQNoteDur');
					num qNoteRemainder = (stackNewQNoteDur >= 1)
									? stackNewQNoteDur.remainder(stackNewQNoteDur.floor())
				      				: stackNewQNoteDur;
					//print('qNoteRemainder: $qNoteRemainder');
					if (qNoteRemainder == 0){
						//time sig = stackQNoteDur / 4
						newNumerator = stackNewQNoteDur.floor();
						//print('newNumerator: $newNumerator');
						newDenominator = 4;
					}
					else {
						num mult = 1 / qNoteRemainder;
						if (mult.floor() == mult){
							//we can only adjust time signatures if the final note's end time can be upscaled
							//to an integer, which will be the case if 1 / remainder is an integer. 
							//ex. 2.25 in a 4/4 bar - remainder is 0.25,  1 / 0.25 == 4, so we'd multiple 2.25 * 4
							// to get 9/16
							newNumerator = (stackNewQNoteDur * mult).floor();
							newDenominator = (4 * mult).floor();
						}
					}
					
					if (newNumerator != null){
						//we have a valid time change
						currentQNoteOffset += latestNoteEndTime - stack.endTime;
						stack.endTime = latestNoteEndTime;
						//var nextStack = stack.next;
						
						for (var measure in stack.measures){
							measure.displayNumBeats = measure.numBeats;
							measure.displayBeatType = measure.beatType;
							measure.numBeats = newNumerator;
							measure.beatType = newDenominator;
							_updateMeasureBeatGroups(measure);
						}
					}
					
				}
			}
		}
	}
	
	Score get score {
		return _score;
	}
	
	html.Element get musicXML { return _musicXML; }
	
	
	//////////////////////////XML UTILITY METHODS////////////////////////
	
	///get element's text as number
	num _enum(html.Element el, String selector, [bool zeroIfNull = true]){
		var e = el.querySelector(selector);
		if (e == null){
			return (zeroIfNull)? 0 : null;
		}
		else {
			//return 0 for an empty string
			return (e.text != "")? num.parse(e.text) : 0;
		}
	}
	
	///get element's text as an integer
	num _eint(html.Element el, String selector, [bool zeroIfNull = true]){
		var e = el.querySelector(selector);
		if (e == null){
			return (zeroIfNull)? 0 : null;
		}
		else {
			//return 0 for an empty string
			return (e.text != "")? int.parse(e.text) : 0;
		}
	}
	
	///get element's text as String
	String _estr(html.Element el, String selector, [bool emptyStringIfNull = true]){
		var e = el.querySelector(selector);
		if (e == null){
			return (emptyStringIfNull)? "" : null;
		}
		else {
			return e.text;
		}
	}
	
	///get the attribute text as an integer
	num _aint(html.Element el, String attribute, [bool zeroIfNull = true]){
		var val = el.attributes[attribute];
		if (val == null){
			return (zeroIfNull)? 0 : null;
		}
		else {
			//return 0 for an empty string
			return (val != "")? int.parse(val) : 0;
		}
	}
	
	///get the attribute text as a number
	/*num _anum(html.Element el, String attribute, [bool zeroIfNull = true]){
		var val = el.attributes[attribute];
		if (val == null){
			return (zeroIfNull)? 0 : null;
		}
		else {
			//return 0 for an empty string
			return (val != "")? num.parse(val) : 0;
		}
	}*/
	
	///returns the numeric equivalent of a string, returning 0 if the string is null or ""
	num _s2n(String str){
		return (str != null && str != "")? num.parse(str) : 0;
	}
	
	
	
	
	/////////////////////////////////////////////////////////////////////
}


class Dlog {
	static void log(dynamic data){
		var div = html.document.querySelector('#divLog');
		if (div == null){
			div = new html.DivElement();
			div.id = 'divLog';
			div.style.height = '300px';
			div.style.width = '300px';
			div.style.overflow = 'auto';
			html.document.body.append(div);
		}
		
		if (data is List){
			for (var item in data){
				var p = new html.ParagraphElement();
				p.setInnerHtml((item == null)? "null" : item.toString());
				div.append(p);
			}
		}
		else {
			var p = new html.ParagraphElement();
			p.setInnerHtml((data == null)? "null" : data.toString());
			div.append(p);
		}
		div.scrollTop = 100000;
	}
}