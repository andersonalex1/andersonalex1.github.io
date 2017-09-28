part of score_render.stagexl.bitmap_renderer;

class VisualSystem extends Sprite {

	List<VisualNoteGroup> _visNoteGroups; //contains the VisualNoteGroup objects for this system
	VisualPage _pageRef; //the VisualPage object this system gets placed on.

	System _systemRef; //the System object used to generate this VisualSystem

	List<VisualMeasure> _visualMeasures = [];
	
	List<Bitmap> _extraNoteheads;

	static int _cacheWidthAddition = 0;

	VisualSystem(System system) {
		
		_systemRef = system;
		_visNoteGroups = [];
	}
	
	/**
	 * gets the VisualMeasure object that lies under the past in Point
	 * @param point a Point object the with coordinates of the point to check against each measure in the system
	 * @return a VisualMeasure if one is found, otherwise null
	 */
	VisualMeasure getVisualMeasureUnderPoint(Point point) {
		int numMeasures = _visualMeasures.length;
		for (int i = 0; i < numMeasures; i++) {
			var visMeas = _visualMeasures[i];
			if (visMeas.x <= point.x && visMeas.x + visMeas.width > point.x && 
					visMeas.y <= point.y && visMeas.y + visMeas.height > point.y) {
				return visMeas;
			}
		}
		return null;
	}
	
	void cacheSystemGraphics(){
		var bounds = this.bounds;
        this.applyCache(bounds.left.floor(), bounds.top.floor(),
	        bounds.width.ceil() + _cacheWidthAddition % 100, bounds.height.ceil());
        //some platforms (Chromebook) seem to have a problem when caching multiple
		//objects of the same size. The image data ends up getting shared. We're
		//attempting to work around this by varying our cache width to prevent
		//the browser making this error.
        _cacheWidthAddition++;
	}
	
	///adds an extra notehead, as for assessment, to the system
	void addExtraNotehead(num xPos, num yPos, int color){
		if (_extraNoteheads == null) _extraNoteheads = [];
		var bd = MusicTextures.getColoredNoteheadBD(NoteheadType.QUARTER, color);
		var bmp = new Bitmap(bd);
		bmp.x = xPos;
		bmp.y = yPos;
		_extraNoteheads.add(bmp);
		this.addChild(bmp);
	}
	
	///removes any extra noteheads that were added (as for assessment). If any
	///were present, true is returned, otherwise false.
	bool removeExtraNoteheads(){
		if (_extraNoteheads == null) return false;
		for (var bmp in _extraNoteheads){
			if (bmp.parent == this){
				this.removeChild(bmp);
			}
		}
		_extraNoteheads = null;
		
		return true;
	}


	List<VisualNoteGroup> get visNoteGroups { return _visNoteGroups; }

	VisualPage get pageRef { return _pageRef; }
	void set pageRef(VisualPage value) { _pageRef = value; }

	num get scoreX { return this.x + _pageRef.x; }
	
	num get scoreY { return this.y + _pageRef.y; }

	/**
	 * the System object used to generate this VisualSystem
	 */
	System get systemRef { return _systemRef;	}
	
	/**
	 * a list of Rectangles containing the dimensions and positions of the measures in the system (positions relative to system origin). Rectangles
	 * are ordered one row at a time (all measures of first row, then second row, etc.).
	 */
	List<VisualMeasure> get visualMeasures => _visualMeasures;

}

