part of score_render.stagexl.linear2;

class Linear2VisualNoteGroup extends Sprite {
	NoteGroup _noteGroup;
	//String _clefType;
	ScoreProperties _scoreProps;
	
	//contains all visual objects that have been tied to this note (not necessarily as children). Typically these should be removed from the screen if the note note is removed.
	//examples include beams and ties
	List<DisplayObject> _visualAttachments;
	
	bool _assessmentMatch; //can be set to true to indicate note has been marked correct by assessment
	
	Point _originalPosition;
	
	//public function VisualNoteGroup(NoteGroup noteGroup, String clefType, ScoreProperties scoreProps, VisualSystem systemRef) {
	Linear2VisualNoteGroup(NoteGroup noteGroup, ScoreProperties scoreProps) {
		
		_noteGroup = noteGroup;
		if (_noteGroup == null) {
			print("here");
		}
		
		//_clefType = clefType;
		_scoreProps = scoreProps;
		
		_assessmentMatch = false;
		
		init();
	}
	
	void init() {
		_visualAttachments = [];
		draw();
	}
	
	void draw() {
		if (_noteGroup.isRest) {
			drawRest();
		}
		else {
			drawNotes();
			drawStem();
		}
		
		addAttachments();
	}
	
	void drawRest() {
		Bitmap restShape;
		var verticalOffset = 0.0;
		switch (_noteGroup.durationType) {
			case DurationType.WHOLE:
				restShape = (new Bitmap(MusicTextures.wholeRest));
				restShape.width = _scoreProps.noteheadWidth * 2.4;
				verticalOffset = -0.75 * _scoreProps.staffLineSpacing;
				break;
			case DurationType.HALF:
				restShape = (new Bitmap(MusicTextures.halfRest));
				restShape.width = _scoreProps.noteheadWidth * 2.4;
				verticalOffset = -0.25 * _scoreProps.staffLineSpacing;
				break;
			case DurationType.QUARTER:
				restShape = (new Bitmap(MusicTextures.quarterRest));
				restShape.width = _scoreProps.noteheadWidth * 1;
				break;
			case DurationType.EIGHTH:
				restShape = (new Bitmap(MusicTextures.eighthRest));
				restShape.width = _scoreProps.noteheadWidth * 1;
				break;
			case DurationType.SIXTEENTH:
				restShape = (new Bitmap(MusicTextures.sixteenthRest));
				restShape.width = _scoreProps.noteheadWidth * 1.1;
				break;
			case DurationType.THIRTY_SECOND:
				restShape = (new Bitmap(MusicTextures.thirtySecondRest));
				restShape.width = _scoreProps.noteheadWidth * 1.2;
				break;
			case DurationType.SIXTY_FOURTH:
				restShape = (new Bitmap(MusicTextures.sixtyFourthRest));
				restShape.width = _scoreProps.noteheadWidth * 1.2;
				break;
			default:
				restShape = (new Bitmap(MusicTextures.quarterRest));
				restShape.width = _scoreProps.noteheadWidth * 1;
				print("Unsupported rest duration! $_noteGroup.durationType VisualNoteGroup.drawRest()");
		}
		restShape.scaleY = restShape.scaleX;
		restShape.y = _noteGroup.restVPos - restShape.height / 2 + verticalOffset;
		//restShape.x = -0.5 * restShape.width;
		//most rests are at 0, but default whole rests must be offset by half their width to be centered properly
		if (_noteGroup.durationType == DurationType.WHOLE){
			if (_noteGroup.qNoteDuration == _noteGroup.voice.measure.stack.dpqLength){
				restShape.x = -0.5 * restShape.width;
			}
		}
		this.addChild(restShape);
		
		//add augmentation dots
		for (int i = 0; i < _noteGroup.numDots; i++) {
			this.graphics.beginPath();
			this.graphics.circle(restShape.x + restShape.width + 3 + 8 * i, restShape.y + 0.3 * restShape.height, _scoreProps.noteheadWidth / 5);
			this.graphics.fillColor(0xFF000000);
			this.graphics.closePath();
		}
	}
	
	void drawNotes() {
		for (var note in _noteGroup.notes) {
			//get the correct notehead shape based on the duration
			Bitmap noteShape;
			switch (_noteGroup.durationType) {
				case DurationType.WHOLE:
					noteShape = new Bitmap(MusicTextures.wholeNoteHead);
					noteShape.width = _scoreProps.noteheadWidth * 1.25; //whole notes are 25% wider than quarter or half noteheads
					break;
				case DurationType.HALF:
					noteShape = (new Bitmap(MusicTextures.halfNoteHead));
					noteShape.width = _scoreProps.noteheadWidth;
					break;
				case DurationType.QUARTER:
					noteShape = (new Bitmap(MusicTextures.quarterNoteHead));
					noteShape.width = _scoreProps.noteheadWidth;
					break;
				case DurationType.EIGHTH:
					noteShape = (new Bitmap(MusicTextures.quarterNoteHead));
					noteShape.width = _scoreProps.noteheadWidth;
					break;
				case DurationType.SIXTEENTH:
					noteShape = (new Bitmap(MusicTextures.quarterNoteHead));
					noteShape.width = _scoreProps.noteheadWidth;
					break;
				case DurationType.THIRTY_SECOND:
					noteShape = (new Bitmap(MusicTextures.quarterNoteHead));
					noteShape.width = _scoreProps.noteheadWidth;
					break;
				case DurationType.SIXTY_FOURTH:
					noteShape = (new Bitmap(MusicTextures.quarterNoteHead));
					noteShape.width = _scoreProps.noteheadWidth;
					break;
				default:
					print("Unsupported durationType! $_noteGroup.durationType VisualNoteGroup.drawNoteheads()");
					noteShape = (new Bitmap(MusicTextures.quarterNoteHead));
					noteShape.width = _scoreProps.noteheadWidth;
			}
			
			//make the height adjust the same amount as the width did
			noteShape.scaleY = noteShape.scaleX;
			
			//adjust for grace note size
			if (_noteGroup.isGrace) {
				noteShape.scaleX *= 0.65;
				noteShape.scaleY *= 0.65;
			}
			
			//center the notehead
			//noteShape.x = note.hPos - noteShape.width / 2;
			//noteShape.y = note.vPos - noteShape.height / 2;
			noteShape.x = note.hPos;
			noteShape.y = note.vPos  - noteShape.height / 2;

			this.addChild(noteShape);
			
			//add augmentation dots
			for (int i = 0; i < _noteGroup.numDots; i++) {
				this.graphics.beginPath();
				this.graphics.circle(note.hPos + 2 * _scoreProps.noteheadWidth + i * 8, note.vPos - 
										(0.5 * _scoreProps.staffLineSpacing * ((note.stepsFromTopStaffLine.abs() + 1) % 2)), _scoreProps.noteheadWidth / 5);
				this.graphics.fillColor(0xFF000000);
				this.graphics.closePath();
			}
			
    		int accidentalType = AccidentalType.getAccidentalType(note.alteration);
        	if (accidentalType != AccidentalType.NONE && accidentalType != AccidentalType.NATURAL){
        		note.accidental = accidentalType;
        	}
			
			//add accidental
			Bitmap accidental = null;
			num vertOffset = 0;
			switch(note.accidental) {
				case AccidentalType.NONE:
					break;
				case AccidentalType.SHARP:
					accidental = (new Bitmap(MusicTextures.sharp));
					break;
				case AccidentalType.FLAT:
					accidental = (new Bitmap(MusicTextures.flat));
					vertOffset = -0.5 * _scoreProps.staffLineSpacing;
					break;
				case AccidentalType.NATURAL:
					accidental = (new Bitmap(MusicTextures.natural));
					break;
				case AccidentalType.DOUBLE_SHARP:
					accidental = (new Bitmap(MusicTextures.doubleSharp));
					break;
				case AccidentalType.DOUBLE_FLAT:
					accidental = (new Bitmap(MusicTextures.doubleFlat));
					break;
				default:
					print("Unrecognized accidental! $note.accidental VisualNoteGroup.drawNotes()");
			}
			
			if (accidental != null) {
				accidental.scaleX = noteShape.scaleX;
				accidental.scaleY = noteShape.scaleY;
				//accidental.x = noteShape.x - accidental.width - 5;
				accidental.y = noteShape.y - accidental.height / 4 + vertOffset;
				accidental.x = note.accidentalPos;
				this.addChild(accidental);
			}
		}
		
		//draw leger lines
		Note bottomNote = _noteGroup.notes[0];
		Note topNote = _noteGroup.notes[_noteGroup.notes.length - 1]; //this could be the same note, but we're only checking for above leger lines with the topNote, and only for below lines with the bottom
		if (bottomNote.legerLines > 0) { //if the bottom note has leger lines below the staff...
			this.graphics.beginPath();
			for (int i = 0; i < bottomNote.legerLines; i++) {
				this.graphics.moveTo( -0.5 * _scoreProps.noteheadWidth, _scoreProps.staffLineSpacing * (5 + i));
				this.graphics.lineTo(  1.5 * _scoreProps.noteheadWidth + bottomNote.hPos, _scoreProps.staffLineSpacing * (5 + i));
			}
			this.graphics.strokeColor(0xFF000000, _scoreProps.legerLineWidth);
			this.graphics.closePath();
		}
		if (topNote.legerLines < 0) {//if the top note has leger lines above the staff...
			this.graphics.beginPath();
			int i = 0;
			while (i > topNote.legerLines) {
				this.graphics.moveTo( -0.5 * _scoreProps.noteheadWidth, _scoreProps.staffLineSpacing * ( -1 + i));
				this.graphics.lineTo(  1.5 * _scoreProps.noteheadWidth + topNote.hPos, _scoreProps.staffLineSpacing * ( -1 + i));
				i--;
			}
			this.graphics.strokeColor(0xFF000000, _scoreProps.legerLineWidth);
			this.graphics.closePath();
		}
		
	}

	void drawStem() {
		//make sure a stem exists
		if (_noteGroup.stemDirection == StemDirection.NO_STEM) {
			return;
		}

		//draw the stem
		this.graphics.beginPath();
		this.graphics.moveTo(_noteGroup.stemHPos, _noteGroup.stemStartPos);
		this.graphics.lineTo(_noteGroup.stemHPos, _noteGroup.stemEndPos);
		this.graphics.strokeColor(0xFF000000, _scoreProps.stemWidth);
		this.graphics.closePath();
		
		//add the flag (if it exists)
		//make sure there is no beam already...
		if (_noteGroup.beamStates.length == 0 || _noteGroup.beamStates[0] == BeamState.NONE) {
			Bitmap flagShape = null;
			switch (_noteGroup.durationType) {
				case DurationType.EIGHTH:
					flagShape = ((_noteGroup.stemDirection == StemDirection.UP)? new Bitmap(MusicTextures.eighthFlagUp) : new Bitmap(MusicTextures.eighthFlagDown));
					break;
				case DurationType.SIXTEENTH:
					flagShape = ((_noteGroup.stemDirection == StemDirection.UP)? new Bitmap(MusicTextures.sixteenthFlagUp) : new Bitmap(MusicTextures.sixteenthFlagDown));
					break;
				case DurationType.THIRTY_SECOND:
					flagShape = ((_noteGroup.stemDirection == StemDirection.UP)? new Bitmap(MusicTextures.thirtySecondFlagUp) : new Bitmap(MusicTextures.thirtySecondFlagDown));
					break;
				case DurationType.SIXTY_FOURTH:
					flagShape = ((_noteGroup.stemDirection == StemDirection.UP)? new Bitmap(MusicTextures.sixteenthFlagUp) : new Bitmap(MusicTextures.sixteenthFlagDown));
					break;
				case DurationType.QUARTER:
					break;
				case DurationType.HALF:
					break;
				case DurationType.WHOLE:
					break;
				default:
					print("Unknown duration! $_noteGroup.durationType VisualNoteGroup.drawStem()");
			}
			if (flagShape != null) {
				flagShape.width = (!_noteGroup.isGrace)? _scoreProps.noteheadWidth : 0.6 * _scoreProps.noteheadWidth;
				//flagShape.width = _scoreProps.noteheadWidth;
				flagShape.scaleY = flagShape.scaleX;
				flagShape.x = _noteGroup.stemHPos;
				flagShape.y = (_noteGroup.stemDirection == StemDirection.UP)? _noteGroup.stemEndPos : _noteGroup.stemEndPos - flagShape.height;
				this.addChild(flagShape);
			}
		}
	}
	
	void addAttachments() {
		//add lyric syllable (if it exists)
		if (_noteGroup.lyric != null) {
			Lyric lyric = _noteGroup.lyric;
			TextField lyricTF = new TextField();
			lyricTF.autoSize = TextFieldAutoSize.LEFT;
			lyricTF.defaultTextFormat = new TextFormat("arial", 17, 0x000000);
			lyricTF.text = lyric.text;
			
			lyricTF.y = -1 * lyric.vPos - (lyricTF.height) + 4; //add a tiny bit to make it match Finale's positioning
			lyricTF.x = lyricTF.textWidth / -2;
			this.addChild(lyricTF);
			_visualAttachments.add(lyricTF);
			
			/*Bitmap lyricBmp = new Bitmap(new BitmapData(lyricTF.textWidth, lyricTF.textHeight));
			lyricBmp.bitmapData.draw(lyricTF);
			
			lyricBmp.y = -1 * lyric.vPos;
			lyricBmp.x = lyricBmp.width / -2;
			this.addChild(lyricBmp);
			_visualAttachments.add(lyricBmp);*/
		}
	}
	
	
	NoteGroup get noteGroup { return _noteGroup; }
	
	
	List<DisplayObject> get visualAttachments { return _visualAttachments; }
	void set visualAttachments(List<DisplayObject> value) { _visualAttachments = value; }
	
	bool get assessmentMatch { return _assessmentMatch; }		
	void set assessmentMatch(bool value) { _assessmentMatch = value;	}
	
	/**
	 * the X/Y position of the VisualNoteGroup as it is originally set. This can be used to save the note's position before it gets moved during assessment, etc.
	 */
	Point get originalPosition { return _originalPosition; }
	void set originalPosition(Point value) { _originalPosition = value; }


}