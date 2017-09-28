part of score_render.stagexl.bitmap_renderer;

/**
 * ...
 * @author Tyler
 */
class VisualNoteGroup extends Sprite {
	NoteGroup _noteGroup;
	//String _clefType;
	ScoreProperties _scoreProps;
	VisualSystem _vSystemRef; // a reference to the system this notegroup belongs to
	
	//contains all visual objects that have been tied to this note (not necessarily as children). Typically these should be removed from the screen if the note note is removed.
	//examples include beams and ties
	List<DisplayObject> _visualAttachments;
	
	//bool _assessmentMatch; //can be set to true to indicate note has been marked correct by assessment
	
	Point _originalPosition;
	
	Bitmap _colorOverlay;
	
	List<Bitmap> _noteheadList;
	NoteheadType _noteheadType;
	
	//public function VisualNoteGroup(NoteGroup noteGroup, String clefType, ScoreProperties scoreProps, VisualSystem systemRef) {
	VisualNoteGroup(NoteGroup noteGroup, ScoreProperties scoreProps, VisualSystem systemRef) {
		
		_noteGroup = noteGroup;
		if (_noteGroup == null) {
			print("NoteGroup null - VisualNoteGroup()");
		}
		
		//_clefType = clefType;
		_scoreProps = scoreProps;
		_vSystemRef = systemRef;
		
		//_assessmentMatch = false;
		
		_init();
	}
	
	///sets the color of the note.
	void setColor(int color){
		if (_noteheadList == null) return;
		
		for (var nh in _noteheadList){
			nh.bitmapData = MusicTextures.getColoredNoteheadBD(_noteheadType, color);
		}
	}
	
	///clears any color change made to the note
	void clearColor(){
		if (_noteheadList == null) return;
		
		for (var nh in _noteheadList){
			nh.bitmapData = MusicTextures.getColoredNoteheadBD(_noteheadType, 0);
		}
	}
	
	void _init() {
		_visualAttachments = [];
		
		if (_noteGroup.visible == false){
			return;
		}
		
		_draw();
	}
	
	void _draw() {
		if (_noteGroup.isRest) {
			_drawRest();
		}
		else {
			_drawNotes();
			_drawStem();
		}
		
		_addAttachments();
	}
	
	void _drawRest() {
		Bitmap restShape;
		var verticalOffset = 0.0;
		switch (_noteGroup.durationType) {
			case DurationType.WHOLE:
				restShape = (new Bitmap(MusicTextures.wholeRest));
				//restShape.width = _scoreProps.noteheadWidth * 2.4;
				verticalOffset = -0.75 * _scoreProps.staffLineSpacing;
				break;
			case DurationType.HALF:
				restShape = (new Bitmap(MusicTextures.halfRest));
				//restShape.width = _scoreProps.noteheadWidth * 2.4;
				verticalOffset = -0.25 * _scoreProps.staffLineSpacing;
				restShape.x = -0.35 * restShape.width;
				break;
			case DurationType.QUARTER:
				restShape = (new Bitmap(MusicTextures.quarterRest));
				//restShape.width = _scoreProps.noteheadWidth * 1;
				break;
			case DurationType.EIGHTH:
				restShape = (new Bitmap(MusicTextures.eighthRest));
				//restShape.width = _scoreProps.noteheadWidth * 1;
				break;
			case DurationType.SIXTEENTH:
				restShape = (new Bitmap(MusicTextures.sixteenthRest));
				//restShape.width = _scoreProps.noteheadWidth * 1.1;
				break;
			case DurationType.THIRTY_SECOND:
				restShape = (new Bitmap(MusicTextures.thirtySecondRest));
				//restShape.width = _scoreProps.noteheadWidth * 1.2;
				break;
			case DurationType.SIXTY_FOURTH:
				restShape = (new Bitmap(MusicTextures.sixtyFourthRest));
				//restShape.width = _scoreProps.noteheadWidth * 1.2;
				break;
			default:
				restShape = (new Bitmap(MusicTextures.quarterRest));
				//restShape.width = _scoreProps.noteheadWidth * 1;
				print("Unsupported rest duration! $_noteGroup.durationType VisualNoteGroup.drawRest()");
		}
		//restShape.scaleY = restShape.scaleX;
		restShape.y = _noteGroup.restVPos - restShape.height / 2 + verticalOffset;
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
	
	void _drawNotes() {
		Note bottomNote;
		Note topNote;
		_noteheadList = [];
		for (var note in _noteGroup.notes) {
			if (note.visible == false){
				continue;
			}
			if (bottomNote == null){
				//the first visible note is always the bottom note
				bottomNote = note;
			}
			//the last visible note is always the top note
			topNote = note;
			
			//get the correct notehead shape based on the duration
			Bitmap noteShape;
			switch (_noteGroup.durationType) {
				case DurationType.WHOLE:
					noteShape = new Bitmap(MusicTextures.wholeNoteHead);
					_noteheadType = NoteheadType.WHOLE;
					break;
				case DurationType.HALF:
					noteShape = (new Bitmap(MusicTextures.halfNoteHead));
					_noteheadType = NoteheadType.HALF;
					break;
				default:
					noteShape = (new Bitmap(MusicTextures.quarterNoteHead));
					_noteheadType = NoteheadType.QUARTER;
			}
			
			_noteheadList.add(noteShape);
			
			//make the height adjust the same amount as the width did
			//noteShape.scaleY = noteShape.scaleX;
			
			//adjust for grace note size
			if (_noteGroup.isGrace) {
				noteShape.scaleX *= 0.65;
				noteShape.scaleY *= 0.65;
			}
			
			//center the notehead
			//noteShape.x = note.hPos - noteShape.width / 2;
			//noteShape.y = note.vPos - noteShape.height / 2;
			noteShape.x = (_noteGroup.stemDirection == StemDirection.DOWN)? note.hPos - 1 : note.hPos;
			noteShape.y = note.vPos  - noteShape.height / 2;

			this.addChild(noteShape);
			
			//add augmentation dots
			for (int i = 0; i < _noteGroup.numDots; i++) {
				this.graphics.beginPath();
				//changed 2 * _scoreProps.noteheadWidth to 1.6 *  - 3/7/2015
				this.graphics.circle(note.hPos + 1.6 * _scoreProps.noteheadWidth + i * 8, note.vPos - 
										(0.5 * _scoreProps.staffLineSpacing * ((note.stepsFromTopStaffLine.abs() + 1) % 2)), _scoreProps.noteheadWidth / 5);
				this.graphics.fillColor(0xFF000000);
				this.graphics.closePath();
			}
			
			//add accidental
			DisplayObject accidental = null;
			num vertOffset = 0;
			if (note.showAccidental){
				switch(note.accidental) {
					case AccidentalType.NONE:
						break;
					case AccidentalType.SHARP:
						accidental = (new Bitmap(MusicTextures.sharp));
						vertOffset = -0.1 * _scoreProps.staffLineSpacing;
						break;
					case AccidentalType.FLAT:
						accidental = (new Bitmap(MusicTextures.flat));
						vertOffset = -0.5 * _scoreProps.staffLineSpacing;
						break;
					case AccidentalType.NATURAL:
						accidental = (new Bitmap(MusicTextures.natural));
						vertOffset = -0.1 * _scoreProps.staffLineSpacing;
						break;
					case AccidentalType.DOUBLE_SHARP:
						accidental = (new Bitmap(MusicTextures.doubleSharp));
						vertOffset = 0.2 * _scoreProps.staffLineSpacing;
						break;
					case AccidentalType.DOUBLE_FLAT:
						accidental = (new Bitmap(MusicTextures.doubleFlat));
						vertOffset = -0.5 * _scoreProps.staffLineSpacing;
						break;
					case AccidentalType.TRIPLE_SHARP:
						accidental = new Sprite();
						var sharp = new Bitmap(MusicTextures.sharp);
						sharp.x = -2.5 * _scoreProps.staffLineSpacing;
						var doubSharp = new Bitmap(MusicTextures.doubleSharp);
						doubSharp.y = 1.3 * _scoreProps.staffLineSpacing;
						(accidental as Sprite).addChild(sharp);
						(accidental as Sprite).addChild(doubSharp);
						break;
					case AccidentalType.TRIPLE_FLAT:
						accidental = new Sprite();
						var flat = new Bitmap(MusicTextures.flat);
						flat.x = -1 * _scoreProps.staffLineSpacing;
						var doubFlat = new Bitmap(MusicTextures.doubleFlat);
						(accidental as Sprite).addChild(flat);
						(accidental as Sprite).addChild(doubFlat);
						vertOffset = -0.5 * _scoreProps.staffLineSpacing;
						break;
					default:
						print("Unrecognized accidental! $note.accidental VisualNoteGroup.drawNotes()");
				}
			}
			
			if (accidental != null) {
				//the only scaling that should happen is for grace notes
				accidental.scaleX = noteShape.scaleX;
				accidental.scaleY = noteShape.scaleY;
				
				accidental.y = noteShape.y - accidental.height / 4 + vertOffset;
				accidental.x = note.accidentalPos;
				this.addChild(accidental);
			}
		}
		
		//draw leger lines
		//Note bottomNote = _noteGroup.notes[0];
		//this could be the same note, but we're only checking for above leger lines with the topNote, 
		//and only for below lines with the bottom
		//Note topNote = _noteGroup.notes[_noteGroup.notes.length - 1]; 
		if (bottomNote == null){
			//if we had no visible notes, there won't be any leger lines. 
			//(currently this should never happen)
			return;
		}
		if (bottomNote.legerLines > 0) { //if the bottom note has leger lines below the staff...
			this.graphics.beginPath();
			for (int i = 0; i < bottomNote.legerLines; i++) {
				this.graphics.moveTo( -0.2 * _scoreProps.noteheadWidth, _scoreProps.staffLineSpacing * (5 + i));
				this.graphics.lineTo(  1.2 * _scoreProps.noteheadWidth + bottomNote.hPos, _scoreProps.staffLineSpacing * (5 + i));
			}
			this.graphics.strokeColor(0xFF000000, _scoreProps.legerLineWidth);
			this.graphics.closePath();
		}
		if (topNote.legerLines < 0) {//if the top note has leger lines above the staff...
			this.graphics.beginPath();
			int i = 0;
			while (i > topNote.legerLines) {
				this.graphics.moveTo( -0.2 * _scoreProps.noteheadWidth, _scoreProps.staffLineSpacing * ( -1 + i));
				this.graphics.lineTo(  1.2 * _scoreProps.noteheadWidth + topNote.hPos, _scoreProps.staffLineSpacing * ( -1 + i));
				i--;
			}
			this.graphics.strokeColor(0xFF000000, _scoreProps.legerLineWidth);
			this.graphics.closePath();
		}
		
	}

	void _drawStem() {
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
					flagShape = ((_noteGroup.stemDirection == StemDirection.UP)
									? new Bitmap(MusicTextures.eighthFlagUp) 
									: new Bitmap(MusicTextures.eighthFlagDown));
					break;
				case DurationType.SIXTEENTH:
					flagShape = ((_noteGroup.stemDirection == StemDirection.UP)
									? new Bitmap(MusicTextures.sixteenthFlagUp) 
									: new Bitmap(MusicTextures.sixteenthFlagDown));
					break;
				case DurationType.THIRTY_SECOND:
					flagShape = ((_noteGroup.stemDirection == StemDirection.UP)
									? new Bitmap(MusicTextures.thirtySecondFlagUp) 
									: new Bitmap(MusicTextures.thirtySecondFlagDown));
					break;
				case DurationType.SIXTY_FOURTH:
					flagShape = ((_noteGroup.stemDirection == StemDirection.UP)
									? new Bitmap(MusicTextures.sixteenthFlagUp) 
									: new Bitmap(MusicTextures.sixteenthFlagDown));
					break;
				case DurationType.QUARTER:
					break;
				case DurationType.HALF:
					break;
				case DurationType.WHOLE:
					break;
				//TODO add support for BREVE, LONG, MAXIMA, 128th, 256th, 512th, 1024th
				default:
					print("Unknown duration! $_noteGroup.durationType VisualNoteGroup.drawStem()");
			}
			if (flagShape != null) {
				//flagShape.width = (!_noteGroup.isGrace)? _scoreProps.noteheadWidth : 0.6 * _scoreProps.noteheadWidth;
				if (_noteGroup.isGrace) { flagShape.scaleY = flagShape.scaleX = 0.6; }
				flagShape.x = _noteGroup.stemHPos;
				flagShape.y = (_noteGroup.stemDirection == StemDirection.UP)? _noteGroup.stemEndPos : _noteGroup.stemEndPos - flagShape.height;
				this.addChild(flagShape);
			}
		}
	}
	
	void _addAttachments() {
		//add lyric syllable (if it exists)
		if (_noteGroup.lyric != null) {
			Lyric lyric = _noteGroup.lyric;
			if (lyric.text != null && lyric.text != ""){
				TextField lyricTF = new TextField();
    			lyricTF.autoSize = TextFieldAutoSize.LEFT;
    			lyricTF.defaultTextFormat = new TextFormat("arial", _scoreProps.staffLineSpacing * 2, 0x000000);
    			lyricTF.text = lyric.text;
    			
    			lyricTF.y = -1 * lyric.vPos - (lyricTF.height) + 4; //add a tiny bit to make it match Finale's positioning
    			lyricTF.x = lyricTF.textWidth / -2 + _scoreProps.noteheadWidth / 2;
    			this.addChild(lyricTF);
    			_visualAttachments.add(lyricTF);
			}			
		}
		if (_noteGroup.articulations != null){
			for (var artic in _noteGroup.articulations){
				Bitmap articBmp;
				switch (artic.type){
					case ArticulationType.STACCATO:
						articBmp = new Bitmap(MusicTextures.staccato);
						break;
					case ArticulationType.ACCENT:
						articBmp = new Bitmap(MusicTextures.accent);
						break;
					case ArticulationType.LEGATO:
						articBmp = new Bitmap(MusicTextures.legato);
						break;
					default:
						continue;
				}
				if (articBmp != null){
					//articBmp.scaleX = articBmp.scaleY = 0.6;
					articBmp.x = artic.hPos;
					articBmp.y = (artic.isAbove)? artic.vPos - articBmp.height : artic.vPos;
					this.addChild(articBmp);
					_visualAttachments.add(articBmp);
				}
			}
		}
	}
	
	
	NoteGroup get noteGroup { return _noteGroup; }
	
	VisualSystem get vSystemRef { return _vSystemRef; }
	void set vSystemRef(VisualSystem value) { _vSystemRef = value; }
	
	
	List<DisplayObject> get visualAttachments { return _visualAttachments; }
	void set visualAttachments(List<DisplayObject> value) { _visualAttachments = value; }
	
	num get scoreX { return _vSystemRef.scoreX + this.x; }
	
	num get scoreY { return _vSystemRef.scoreY + this.y; }
	
	//bool get assessmentMatch { return _assessmentMatch; }
	//void set assessmentMatch(bool value) { _assessmentMatch = value;	}
	
	/// the X/Y position of the VisualNoteGroup as it is originally set. This can
	/// be used to save the note's position before it gets moved during assessment, etc.
	Point get originalPosition { return _originalPosition; }
	void set originalPosition(Point value) { _originalPosition = value; }


}