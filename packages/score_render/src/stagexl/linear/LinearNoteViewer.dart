part of score_render.stagexl.linear;

class LinearNoteViewer extends Sprite {
	
	Sprite _container;
	num _staffLineSpacing = 10;
	
	num _topStaffLinePos = 50;
	
	num _scale = 0.4;
	
	num totalWidth;
	num totalHeight;
	
	num firstNoteStartOffset = 50;
	
	num _staffLineWidth = 2;
	
	num pixelsPerQNote = 100; //the follow distance in pixels awarded to a quarter note 
	
	List<LinearVisualNote> vnList;
	
	Function _rendererReadyCallback; //called after textures have been loaded
	
	LinearNoteViewer(Function readyCallback) {
		_rendererReadyCallback = readyCallback;
		
		init();
	}
	
	void init() {
		MusicTextures.onCompleteFunction = _rendererReadyCallback;
		MusicTextures.createTextures();
	}
	
	void displayNotes(Part part){
		_container = new Sprite();
		
		Sprite notesContainer = _drawNotes(part);
		
		_createBackground(notesContainer.width, notesContainer.height);
		
		notesContainer.x = firstNoteStartOffset;
		
		_container.addChild(notesContainer);
		
		this.addChild(_container);
	}
	
	void _createBackground(num width, num height){
		num widthBuffer = 100;
		num heightBuffer = 100;
		
		totalWidth = width + widthBuffer;
        totalHeight = height + heightBuffer;
        		
		_container.graphics.beginPath();
		_container.graphics.rect(0, 0, totalWidth, totalHeight);
		_container.graphics.fillColor(0xFFFFFFFF);
		
		
		
		for (int i = 0; i < 5; i++){
			_container.graphics.moveTo(0, _topStaffLinePos + i * _staffLineSpacing);
			_container.graphics.lineTo(totalWidth, _topStaffLinePos + i * _staffLineSpacing);
		}
		_container.graphics.strokeColor(0xFF000000, _staffLineWidth);
		
		_container.graphics.closePath();
	}
	
	Sprite _drawNotes(Part part) {
		vnList = [];
		Sprite notesContainer = new Sprite();
		var ngList = part.noteGroups;
		for (var ng in ngList){
			num hPos = ng.qNoteTime * pixelsPerQNote;
			Bitmap symbol = _getSymbol(ng);
			Bitmap accidental = _createAccidental(ng);
			symbol.scaleX = symbol.scaleY = _scale;
			var vn = new LinearVisualNote(ng);
			vn.addChild(symbol);
			if (accidental != null){
				accidental.scaleX = accidental.scaleY = _scale;
				symbol.x = 1.5 * _staffLineSpacing;
				vn.addChild(accidental);
			}
			if (ng.isRest){
				vn.y = ((5 * _staffLineSpacing) - symbol.width) / 2;
			}
			else {
				var note = ng.notes[0];
				if (note.tieState != TieState.NONE && note.tieState != TieState.START){
					continue; //don't draw notes that are tied to
				}
				//position the note vertically
				int stepsFromTopStaffLine = PitchUtils.getStepsFromTopStaffLine(ng.notes[0].pitchName, "treble");
				vn.y = 0.5 * stepsFromTopStaffLine * _staffLineSpacing;
				
				//draw leger lines if necessary
				int numLegerLines = PitchUtils.getNumberOfLegerLines(stepsFromTopStaffLine);
				if (numLegerLines != 0){ _drawLegerLines(numLegerLines, stepsFromTopStaffLine, vn, symbol.x); }
			}
			vn.x = hPos;
			vn.y += _topStaffLinePos - (0.5 * _staffLineSpacing);
			
			notesContainer.addChild(vn);
			vnList.add(vn);
		}
		
		return notesContainer;
    }
	
	
	Bitmap _getSymbol(NoteGroup ng){
		BitmapData symbolBD;
		
		var vertOffset = 0.0;
		switch(ng.durationType){
			case DurationType.WHOLE:
				symbolBD = (ng.isRest)? MusicTextures.wholeRest : MusicTextures.wholeNoteHead;
				if (ng.isRest){ vertOffset = -0.7 * _staffLineSpacing; }
				break;
			case DurationType.HALF:
				symbolBD = (ng.isRest)? MusicTextures.halfRest : MusicTextures.halfNoteHead;
				if (ng.isRest){ vertOffset = -0.3 * _staffLineSpacing; }
				break;
			case DurationType.QUARTER:
				symbolBD = (ng.isRest)? MusicTextures.quarterRest : MusicTextures.quarterNoteHead;
				break;
			case DurationType.EIGHTH:
				symbolBD = (ng.isRest)? MusicTextures.eighthRest : MusicTextures.quarterNoteHead;
				break;
			case DurationType.SIXTEENTH:
				symbolBD = (ng.isRest)? MusicTextures.sixteenthRest : MusicTextures.quarterNoteHead;
				break;
			case DurationType.THIRTY_SECOND:
				symbolBD = (ng.isRest)? MusicTextures.sixtyFourthRest : MusicTextures.quarterNoteHead;
				break;
			case DurationType.SIXTY_FOURTH:
				symbolBD = (ng.isRest)? MusicTextures.sixtyFourthRest : MusicTextures.quarterNoteHead;
				break;
			default:
				//unknown duration type
				symbolBD = (ng.isRest)? MusicTextures.quarterRest : MusicTextures.quarterNoteHead;
		}
		
		var bmp = new Bitmap(symbolBD);
		bmp.y = vertOffset;
		
		return bmp;
	}
	
	Bitmap _createAccidental(NoteGroup ng){
		if (ng.isRest){
			return null;
		}
		var note = ng.notes[0];
		int accidentalType = AccidentalType.getAccidentalType(note.alteration);
    	Bitmap accidentalBMP;
    	num vertOffset = 0;
    	if (accidentalType != AccidentalType.NONE && accidentalType != AccidentalType.NATURAL){
    		switch(accidentalType) {
				case AccidentalType.SHARP:
					accidentalBMP = (new Bitmap(MusicTextures.sharp));
					vertOffset = -0.9 * _staffLineSpacing;
					break;
				case AccidentalType.FLAT:
					accidentalBMP = (new Bitmap(MusicTextures.flat));
					vertOffset = -1.2 * _staffLineSpacing;
					break;
				case AccidentalType.NATURAL:
					accidentalBMP = (new Bitmap(MusicTextures.natural));
					vertOffset = -0.7 * _staffLineSpacing;
					break;
				case AccidentalType.DOUBLE_SHARP:
					accidentalBMP = (new Bitmap(MusicTextures.doubleSharp));
					break;
				case AccidentalType.DOUBLE_FLAT:
					accidentalBMP = (new Bitmap(MusicTextures.doubleFlat));
					break;
				default:
					print("Unrecognized accidental! $accidentalType");
			}
    		accidentalBMP.y = vertOffset;
    		
    		return accidentalBMP;
    	}
    	else {
    		return null;
    	}
	}
	
	void _drawLegerLines(int numLegerLines, int stepsFromTopStaffLine, LinearVisualNote vn, num hPos) {
		num vStartPos = 0.5 * _staffLineSpacing;
		if (stepsFromTopStaffLine % 2 != 0){
			//with notes on spaces, the leger line appears above or below the note, not on it
			vStartPos += (numLegerLines > 0)? -0.5 * _staffLineSpacing : 0.5 * _staffLineSpacing;
		}
		num mult = (numLegerLines > 0)? -1 * _staffLineSpacing : _staffLineSpacing;
		numLegerLines = numLegerLines.abs();
		hPos -= _staffLineSpacing;
		
		vn.graphics.beginPath();
		for (int i = 0; i < numLegerLines; i++){
			vn.graphics.moveTo(hPos, vStartPos + i * mult);
			vn.graphics.lineTo(hPos + 3 * _staffLineSpacing, vStartPos + i * mult);
		}
		vn.graphics.strokeColor(0xFF000000, _staffLineWidth);
		vn.graphics.closePath();
    }
}