part of score_render.stagexl.textures;


class MusicTextures {
	///prepended to resource paths - must end with / if not ""
	static String pathPrefix = "";
	
	static BitmapData wholeRest;
	static BitmapData halfRest;
	static BitmapData quarterRest;
	static BitmapData eighthRest;
	static BitmapData sixteenthRest;
	static BitmapData thirtySecondRest;
	static BitmapData sixtyFourthRest;
	
	static BitmapData wholeNoteHead;
	static BitmapData halfNoteHead;
	static BitmapData quarterNoteHead;
	
	static BitmapData sharp;
	static BitmapData flat;
	static BitmapData natural;
	static BitmapData doubleSharp;
	static BitmapData doubleFlat;
	
	static BitmapData eighthFlagUp;
	static BitmapData eighthFlagDown;
	static BitmapData sixteenthFlagUp;
	static BitmapData sixteenthFlagDown;
	static BitmapData thirtySecondFlagUp;
	static BitmapData thirtySecondFlagDown;
	static BitmapData sixtyFourthFlagUp;
	static BitmapData sixtyFourthFlagDown;
	
	static BitmapData trebleClef;
	static BitmapData bassClef;
	static BitmapData altoClef;
	static BitmapData tenorClef;
	
	static BitmapData f;
	static BitmapData ff;
	static BitmapData fff;
	static BitmapData p;
	static BitmapData pp;
	static BitmapData ppp;
	static BitmapData mf;
	static BitmapData mp;
	static BitmapData m;
	static BitmapData s;
	static BitmapData z;
	static BitmapData r;
	
	static BitmapData augmentationDot;
	
	static BitmapData accent;
	static BitmapData staccato;
	static BitmapData legato;
	
	static List<ColoredNoteheadDO> _coloredNoteheadDOs = [];
	
	//static html.Element _symbolsXml; //info for music font characters
	
	static bool _texturesCreated = false;
	
	static num _svgScale = 1.0;
	
	static Function onCompleteFunction;
	
	MusicTextures() {
		
	}
	
	static void createTextures() {
		
		if (_texturesCreated) {
			return;
		}
		ResourceManager resourceManager = new ResourceManager();
		resourceManager.addTextFile("infoString",
			"${pathPrefix}images/gonvilleSymbolsInfo.xml");
		//resourceManager.addBitmapData("symbolsBD", "images/MusicSymbols.png");
		resourceManager.addBitmapData("symbolsBD",
			"${pathPrefix}images/gonvilleconsol.svg");
		//resourceManager.addTextFile("musicFontInfo", "images/MusicFontInfo.xml");
		
		resourceManager.load().then((result){
//			html.DomParser parser = new html.DomParser();
//    		var doc = parser.parseFromString(resourceManager.getTextFile("musicFontInfo"), "text/xml");
//    		_symbolsXml = doc.querySelector("symbols");
//			_loadSymbolsFromFont(1.0);
			
			String infoString = resourceManager.getTextFile("infoString");
			BitmapData symbolsBD = resourceManager.getBitmapData("symbolsBD");
			
			var parser = new html.DomParser();
			var infoXML = parser.parseFromString(infoString, 'text/xml').querySelector('symbols');
			
			_svgScale = num.parse(infoXML.attributes['scale']);
			
			wholeRest = getBitmapData("WholeRest", infoXML, symbolsBD);
			halfRest = getBitmapData("HalfRest", infoXML, symbolsBD);
			quarterRest = getBitmapData("QuarterRest", infoXML, symbolsBD);
			eighthRest = getBitmapData("EighthRest", infoXML, symbolsBD);
			sixteenthRest = getBitmapData("SixteenthRest", infoXML, symbolsBD);
			thirtySecondRest = getBitmapData("ThirtySecondRest", infoXML, symbolsBD);
			sixtyFourthRest = getBitmapData("SixtyFourthRest", infoXML, symbolsBD);
			
			wholeNoteHead = getBitmapData("WholeNoteHead", infoXML, symbolsBD);
			halfNoteHead = getBitmapData("HalfNoteHead", infoXML, symbolsBD);
			quarterNoteHead = getBitmapData("QuarterNoteHead", infoXML, symbolsBD);
			
			sharp = getBitmapData("Sharp", infoXML, symbolsBD);
			flat = getBitmapData("Flat", infoXML, symbolsBD);
			natural = getBitmapData("Natural", infoXML, symbolsBD);
			doubleSharp = getBitmapData("DoubleSharp", infoXML, symbolsBD);
			doubleFlat = getBitmapData("DoubleFlat", infoXML, symbolsBD);
			
			eighthFlagUp = getBitmapData("EighthFlagUp", infoXML, symbolsBD);
			eighthFlagDown = getBitmapData("EighthFlagDown", infoXML, symbolsBD);
			sixteenthFlagUp = getBitmapData("SixteenthFlagUp", infoXML, symbolsBD);
			sixteenthFlagDown = getBitmapData("SixteenthFlagDown", infoXML, symbolsBD);
			thirtySecondFlagUp = getBitmapData("ThirtySecondFlagUp", infoXML, symbolsBD);
			thirtySecondFlagDown = getBitmapData("ThirtySecondFlagDown", infoXML, symbolsBD);
			sixtyFourthFlagUp = getBitmapData("SixtyFourthFlagUp", infoXML, symbolsBD);
			sixtyFourthFlagDown = getBitmapData("SixtyFourthFlagDown", infoXML, symbolsBD);
			
			trebleClef = getBitmapData("TrebleClef", infoXML, symbolsBD);
			bassClef = getBitmapData("BassClef", infoXML, symbolsBD);
			altoClef = getBitmapData("AltoClef", infoXML, symbolsBD);
			tenorClef = getBitmapData("TenorClef", infoXML, symbolsBD);
			
			f = getBitmapData("F", infoXML, symbolsBD);
			ff = getBitmapData("FF", infoXML, symbolsBD);
			fff = getBitmapData("FFF", infoXML, symbolsBD);
			p = getBitmapData("P", infoXML, symbolsBD);
			pp = getBitmapData("PP", infoXML, symbolsBD);
			ppp = getBitmapData("PPP", infoXML, symbolsBD);
			mf = getBitmapData("MF", infoXML, symbolsBD);
			mp = getBitmapData("MP", infoXML, symbolsBD);
			
			augmentationDot = getBitmapData("Staccato", infoXML, symbolsBD);
			
			accent = getBitmapData("Accent", infoXML, symbolsBD);
			staccato = getBitmapData("Staccato", infoXML, symbolsBD);
			legato = getBitmapData("Legato", infoXML, symbolsBD);
			
			_texturesCreated = true;
			
			if (onCompleteFunction != null){
				onCompleteFunction();
			}
		});
		
		
		
	}
	
	static BitmapData getBitmapData(String id, html.Element infoXML, BitmapData symbolsBD) {
		num x = 0;
		num y = 0;
		num width = 0;
		num height = 0;
		for (var iXML in infoXML.querySelectorAll("symbol")) {
			if (iXML.getAttribute("id") == id) {
				x = (num.parse(iXML.getAttribute("x")) * _svgScale).floor();
				y = (num.parse(iXML.getAttribute("y")) * _svgScale).floor();
				width = (num.parse(iXML.getAttribute("width")) * _svgScale).ceil();
				height = (num.parse(iXML.getAttribute("height")) * _svgScale).ceil();
			}
		}
		
		BitmapData bd = new BitmapData(width.ceil(), height.ceil(), 0x00000000);
		bd.copyPixels(symbolsBD, new Rectangle<int>(x.floor(), y.floor(), width.ceil(),
						height.ceil()), new Point(0, 0));
		return bd;
	}
	
	///gets a colored version of a notehead
	///@param noteheadType a value from the NoteheadType enum
	///@param color an int with values for red, green, blue (ex. 0xFF0000)
	static BitmapData getColoredNoteheadBD(NoteheadType noteheadType, int color){
		if (color == 0){
			switch(noteheadType){
				case NoteheadType.WHOLE: return wholeNoteHead;
				case NoteheadType.HALF: return halfNoteHead;
				default: return quarterNoteHead;
			}
		}
		
		for (var cndo in _coloredNoteheadDOs){
			if (cndo.type == noteheadType){
				if (color == cndo.color){
					return cndo.bitmapData;
				}
			}
		}
		
		var cndo = new ColoredNoteheadDO(noteheadType, color);
		
		BitmapData bd;
		switch(noteheadType){
			case NoteheadType.WHOLE:
				bd = wholeNoteHead.clone();
				break;
			case NoteheadType.HALF:
				bd = halfNoteHead.clone();
				break;
			default:
				bd = quarterNoteHead.clone();
		}
		
		var transform = new ColorTransform();
		transform.color = color;
		bd.colorTransform(bd.rectangle, transform);
		
		cndo.bitmapData = bd;
		_coloredNoteheadDOs.add(cndo);
		
		return bd;
	}
	
}

enum NoteheadType {
	QUARTER, HALF, WHOLE
}

class ColoredNoteheadDO {
	NoteheadType type;
	int color;
	BitmapData bitmapData;
	
	ColoredNoteheadDO(this.type, this.color);
}

