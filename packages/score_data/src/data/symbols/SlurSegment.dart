part of score_data.data;


class SlurSegment extends BaseDataObject {

	Slur _slur;
	System _systemRef;
	List<PointXY> _points = new List<PointXY>(4);
	Map<int, num> _ngCoordinates;

	SlurSegment() {
	}

	/**
	 * the Slur that this SlurSegment corresponds to
	 */
	Slur get slur { return _slur; }
	void set slur(Slur value) { _slur = value; }

	/**
	 * the System this segment belongs to
	 */
	System get systemRef { return _systemRef; }
	void set systemRef(System value) { _systemRef = value; }

	/**
	 * the positions of the (up to) five points of this slur segment - index 0 is beginning, index 4 is end, 2 is the middle
	 */
	List<PointXY> get points { return _points; }


	/**
	 * contains a list of X/Y pairs of coordinates for the top and bottom points of each NoteGroup that falls in the segment's region
	 */
	Map<int, num> get ngCoordinates { return _ngCoordinates; }
	void set ngCoordinates(Map<int, num> value) { _ngCoordinates = value; }
}

