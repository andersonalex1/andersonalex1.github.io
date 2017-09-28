part of score_render.stagexl.linear2;

class Linear2ScoreRenderer {
	ScoreProperties _scoreProps; //ScoreProperties object for the score
	
	Linear2Score _vScore;

	//when re-rendering the music, we can re-use VisualNoteGroups from the previous render. We store a list of those previously rendered VNG's
	//and an index to keep track of which one we're currently on.
	//List<Linear2VisualNoteGroup> _legacyVNoteGroups;
	//int _legacyVNGIndex;
	
	static num PIXELS_PER_QNOTE = 100; //the follow distance in pixels awarded to a quarter note 
	static const num FIRST_NOTE_START_POS = 50;

	static List<int> TC_FLAT_POSITIONS;
	static List<int> BC_FLAT_POSITIONS;
	static List<int> TC_SHARP_POSITIONS;
	static List<int> BC_SHARP_POSITIONS;
	static List<int> TENOR_FLAT_POSITIONS;
	static List<int> TENOR_SHARP_POSITIONS;
	static List<int> ALTO_FLAT_POSITIONS;
	static List<int> ALTO_SHARP_POSITIONS;

	Linear2ScoreRenderer(this._scoreProps) {
		
		//_legacyVNGIndex = 0;
		
		if (TC_FLAT_POSITIONS == null) {
			TC_FLAT_POSITIONS = [4, 1, 5, 2, 6, 3, 7];
			BC_FLAT_POSITIONS = [6, 3, 7, 4, 8, 5, 9];
			TC_SHARP_POSITIONS = [0, 3, -1, 2, 5, 1, 4];
			BC_SHARP_POSITIONS = [2, 5, 1, 4, 7, 3, 6];
			TENOR_FLAT_POSITIONS = [3, 0, 4, 1, 5, 2, 6];
			TENOR_SHARP_POSITIONS = [6, 2, 5, 1, 4, 0, 3];
			ALTO_FLAT_POSITIONS = [5, 2, 6, 3, 7, 4, 8];
			ALTO_SHARP_POSITIONS = [1, 4, 0, 3, 6, 2, 5];
		}
	}

	void renderScore(Linear2Score linearScore, List<Part> parts) {
		_vScore = linearScore;
		_vScore.pixelsPerQNote = PIXELS_PER_QNOTE;
		_vScore.firstNoteStartPos = FIRST_NOTE_START_POS;

		num staffSpacing = (_scoreProps.staffLineSpacing * 4) + _scoreProps.staffSpacing; //distance from top staff line of one staff to top staff line of next staff
		num qNoteEndTime = parts[0].staves[0].measures.last.stack.endTime;
		
		num vStaffPos = 0; //current staff's vertical position (top line of staff)

		//go through every measure in every stack, horizontally first and then down (all measures in a staff before going to next staff)
		for (var part in parts){
			for (var staff in part.staves){
				//draw the staff lines for this staff
				drawStaff(qNoteEndTime, vStaffPos);
				
				//add the notes - create a list of lists of VisualNoteGroups to hold onto the notes - we'll use this to add the ties
				List<List<Linear2VisualNoteGroup>> vngLists = [];
				
				for (var measure in staff.measures){
					drawNotes(measure, vngLists, vStaffPos);
				}
	
				//add the beams
				drawBeams(vngLists, vStaffPos);
	
				//add the tuplets
				drawTuplets(vngLists, vStaffPos);
	
				//add the ties
				drawTies(vngLists, vStaffPos);
	
				//increment the vertical staff position
				vStaffPos += staffSpacing;
			}
		}		

	}




	void drawStaff(num qNoteEndTime, num vStaffPos) {
		num endPos = qNoteEndTime * PIXELS_PER_QNOTE + FIRST_NOTE_START_POS + 20;
		
		//draw a white background
//		_vScore.graphics.beginPath();
//		_vScore.graphics.moveTo(0, 0);
//		_vScore.graphics.rect(0, 0, endPos, 4 * _scoreProps.staffLineSpacing + vStaffPos);
//		_vScore.graphics.fillColor(0xFFFFFFFF);
//		_vScore.graphics.closePath();
		
		//draw the lines
		_vScore.graphics.beginPath();
		for (int i = 0; i < 5; i++) {
			_vScore.graphics.moveTo(0, i * _scoreProps.staffLineSpacing + vStaffPos);
			_vScore.graphics.lineTo(endPos, i * _scoreProps.staffLineSpacing + vStaffPos);
		}
		_vScore.graphics.strokeColor(0xFF000000, _scoreProps.staffLineWidth);
		_vScore.graphics.closePath();
	}


	void drawNotes(Measure measure, List<List<Linear2VisualNoteGroup>> vngLists, num vStaffPos) {

		Linear2VisualNoteGroup visNoteGroup;
	
		//go through every voice and create VisualNoteGroup objects for the notes in them. 

		for (int i = 0; i < measure.voices.length; i++) {
			//keep track of all of the notes added and the voices they are added to.
			if (vngLists.length < i + 1){
				//vngLists[i] = new List<VisualNoteGroup>();
				vngLists.add(new List<Linear2VisualNoteGroup>());
			}

			for (var noteGroup in measure.voices[i].noteGroups) {
				visNoteGroup = new Linear2VisualNoteGroup(noteGroup, _scoreProps);
				visNoteGroup.x = noteGroup.qNoteTime * PIXELS_PER_QNOTE + FIRST_NOTE_START_POS;
				visNoteGroup.y += vStaffPos;
				visNoteGroup.originalPosition = new Point(visNoteGroup.x, visNoteGroup.y);
				_vScore.addChild(visNoteGroup);
				_vScore.addVisualNoteGroup(visNoteGroup);
				vngLists[i].add(visNoteGroup);
			}
		}
		
	}

	void drawBeams(List<List<Linear2VisualNoteGroup>> vngLists, num vStaffPos) {
		Map<int, Point> currentBeams = {}; //holds Point objects which contain the starting coordinates for beams
		num beamWidth = _scoreProps.beamWidth;
		num stemEndPos = 0;
		num hPos = 0;
		num vPos = 0;
		//Shape beam;
		for (var vngList in vngLists){
			for (var vng in vngList) {
				NoteGroup noteGroup = vng.noteGroup;
				num scale = (!noteGroup.isGrace)? 1 : 0.65;
				beamWidth = _scoreProps.beamWidth * scale;
				//num halfNoteheadWidth = scale * _scoreProps.noteheadWidth / 2;
				for (int i = 0; i < noteGroup.beamStates.length; i++) {
					//find the vertical attach point for a beam
					if (noteGroup.beamStates[i] != BeamState.CONTINUE && noteGroup.beamStates[i] != BeamState.NONE) {
						stemEndPos = noteGroup.stemEndPos;
						hPos = vng.x + noteGroup.stemHPos;
						vPos = (noteGroup.stemDirection == StemDirection.UP)? stemEndPos + (beamWidth * 2 * i) : stemEndPos - (beamWidth * 2 * i);
						vPos += vStaffPos;
					}
					switch(noteGroup.beamStates[i]) {
						case BeamState.BEGIN:
							//store the starting point for the beam in an array. The outer most beam will be index 0, the second beam index 1, etc.
							currentBeams[i] = new Point(hPos, vPos);
							break;
						case BeamState.END:
							//retrieve the starting point for the beam with the matching index
							Point startingPoint = currentBeams[i];
							
							if (startingPoint != null) {
								//create the beam 
								
								_vScore.graphics.beginPath();
								_vScore.graphics.moveTo(startingPoint.x, startingPoint.y);
								_vScore.graphics.lineTo(hPos, vPos);
								_vScore.graphics.strokeColor(0xFF000000, beamWidth, JointStyle.ROUND, CapsStyle.SQUARE);
								_vScore.graphics.closePath();
							}
							break;
						case BeamState.CONTINUE:
							//do nothing
							break;
						case BeamState.FORWARD_HOOK:
							//draw a line straight to the right
							
							_vScore.graphics.beginPath();
							_vScore.graphics.moveTo(hPos, vPos);
							_vScore.graphics.lineTo(hPos + _scoreProps.noteheadWidth / 1.5, vPos);
							_vScore.graphics.strokeColor(0xFF000000, beamWidth, JointStyle.ROUND, CapsStyle.SQUARE);
							_vScore.graphics.closePath();
							
							break;
						case BeamState.BACKWARD_HOOK:
							//draw a line straight to the left
							
							_vScore.graphics.beginPath();
							_vScore.graphics.moveTo(hPos, vPos);
							_vScore.graphics.lineTo(hPos - _scoreProps.noteheadWidth / 1.5, vPos);
							_vScore.graphics.strokeColor(0xFF000000, beamWidth, JointStyle.ROUND, CapsStyle.SQUARE);
							_vScore.graphics.closePath();
							
							break;
						case BeamState.NONE:
							//do nothing
							break;
						default:
							print("Unrecognized Beam Stage! VisualSystem.drawBeams() ${noteGroup.beamStates[i]}");
					}
				}
			}
		}
	}

	void drawTuplets(List<List<Linear2VisualNoteGroup>> vngLists, num vStaffPos) {
		//go through every note on the system. If it has a Tuplet object, draw its value to a TextField and copy it onto a Bitmap object. Add the Bitmap in the location
		//at the middle of the notes that comprise the tuplet, positioned vertically above or below according to the definition
		TextField tupletTF = new TextField();

		for (var vngList in vngLists){
			for (var vng in vngList) {
				NoteGroup noteGroup = vng.noteGroup;
				if (noteGroup.tuplets == null) {
					continue;
				}
				for (var tuplet in noteGroup.tuplets) {
					if (tuplet.firstNote == vng.noteGroup) {

						tupletTF.text = tuplet.numerator.toString();
						BitmapData bd = new BitmapData(20, 20, 0x00000000);
						bd.draw(tupletTF);
						Bitmap bitmap = new Bitmap(bd);
						if (tuplet.above) {
							bitmap.x = vng.x + ((tuplet.endNote.hPos - vng.noteGroup.hPos) / 2);
							if (vng.noteGroup.isRest) {
								bitmap.y = vng.noteGroup.restVPos - 30 + vStaffPos;
							}
							else if (vng.noteGroup.stemDirection == StemDirection.UP) {
								bitmap.y = vng.noteGroup.stemEndPos - 20 + vStaffPos;
							}
							else {
								bitmap.y = vng.noteGroup.notes[vng.noteGroup.notes.length - 1].vPos - 20 + vStaffPos;
							}
						}
						else {
							bitmap.x = vng.x + ((tuplet.endNote.hPos - vng.noteGroup.hPos) / 2);
							if (vng.noteGroup.isRest) {
								bitmap.y = vng.noteGroup.restVPos + 20 + vStaffPos;
							}
							else if (vng.noteGroup.stemDirection == StemDirection.UP) {
								bitmap.y = vng.noteGroup.notes[0].vPos + 5 + vStaffPos;
							}
							else {
								bitmap.y = vng.noteGroup.stemEndPos + 5 + vStaffPos;
							}
						}
						_vScore.addChild(bitmap);
					}
				}
			}
		}
	}
	

	/**
	 * add the ties for the notes on the current staff
	 * @param	vngLists a list of lists of VisualNoteGroups (each voice is a list)
	 * @param	vStaffPos the offset from the top of the system that the current staff begins
	 */
	void drawTies(List<List<Linear2VisualNoteGroup>> vngLists, num vStaffPos) {
		//each voice is a list of VisualNoteGroup objects
		//we'll look in each list (voice) at the VisualNoteGroup objects and inside their respective notes to check the tie states
		num noteheadWidth = _scoreProps.noteheadWidth;
		num tieStartOffset = 0.8 * noteheadWidth;
		num tieEndOffset = 0.3 * noteheadWidth;
		Linear2VisualNoteGroup nextVNG;
		for (int i = 0; i < vngLists.length; i++){
			List<Linear2VisualNoteGroup> vngList = vngLists[i];
			int numNotes = vngList.length;
			for (int j = 0; j < numNotes; j++) {
				Linear2VisualNoteGroup cVNG = vngList[j]; //current VisualNoteGroup
				for (var note in cVNG.noteGroup.notes) {
					switch (note.tieState) {
						//for tie starts, we'll draw a tie either to the next note (if it's to the right on the same system), or just to the end of the system.
						case TieState.START:
							if (j < numNotes - 1) { //if the next note is to the right, draw the tie between the notes
								nextVNG = vngList[j + 1];
								drawTie(cVNG.x + note.hPos + tieStartOffset, nextVNG.x + tieEndOffset, note.vPos + vStaffPos, cVNG, note.vPos);
							}
							break;
						//for tie continues, we'll draw the forward tie with the same conditions as a START tie, but we also have to draw a backwards tie IF it's the first note on a system
						case TieState.CONTINUE:
							if (j < numNotes - 1) { //if the next note is to the right, draw the tie between the notes
								nextVNG = vngList[j + 1];
								drawTie(cVNG.x + note.hPos + tieStartOffset, nextVNG.x + tieEndOffset, note.vPos + vStaffPos, cVNG, note.vPos);
							}
							break;
						default:
							//no tie to draw
					}
				}
			}
		}

		
	}
	
	void drawTie(num x1Val, num x2Val, num yVal, Linear2VisualNoteGroup vng, num vPosInStaff) {
		bool curveDown = false;
		if (vng.noteGroup.stemDirection == StemDirection.UP ||
				(vng.noteGroup.stemDirection == StemDirection.NO_STEM && vPosInStaff > _scoreProps.staffLineSpacing * 3)) {
			curveDown = true;
		}

		Shape tieShape = new Shape();
		tieShape.graphics.beginPath();
		var yControl = (curveDown)? 7 : -7;
		var length = x2Val - x1Val;
		tieShape.graphics.moveTo(0, 0);
		tieShape.graphics.bezierCurveTo(length / 3, yControl, 2 * length / 3, yControl, length, 0);
		tieShape.graphics.moveTo(0, 0);
		tieShape.graphics.bezierCurveTo(length / 3, yControl - 2, 2 * length / 3, yControl - 2, length, 0);
		tieShape.graphics.strokeColor(0xFF000000, 1);
		tieShape.graphics.closePath();
		
		tieShape.x = (curveDown)? x1Val - 1 : x1Val - 0;
		tieShape.y = (curveDown)? yVal + 6 : yVal - 6;
		
		_vScore.addChild(tieShape);
		vng.visualAttachments.add(tieShape);
	}


	
	
	
}

