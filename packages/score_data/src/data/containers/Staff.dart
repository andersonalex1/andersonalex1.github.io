part of score_data.data;
	
class Staff extends BaseDataObject {

	List<Measure> _measures = [];
	
	Part _partRef;

	/**may be used to store a list of NoteGroups and their associated lyric words,
	 * if any. This is not populated during parsing, but may be used by
	 * PitchNameManager from musicCreation package*/
	List<Map<NoteGroup, Lyric>> _originalLyrics;

	///determines whether staff is rendered
	bool _visible = true;
	
	Staff() {
		
	}
	
	void addMeasure(Measure measure) {
		_measures.add(measure);
		measure.staff = this;
	}

	/**
	 * removes the measure at the requested index
	 * @param index the index of the measure with the measures list
	 */
	void removeMeasureAt(int index) {
		_measures.removeAt(index);
	}
	
	/**
	 * inserts the Measure at the requested index
	 * @param	measure the Measure to insert
	 * @param	insertionIndex the position to insert the Measure (if invalid, the Measure is not added)
	 */
	void insertMeasure(Measure measure, int insertionIndex) {
		if (insertionIndex <= _measures.length && insertionIndex >= 0) {
			_measures.insert(insertionIndex, measure);
			measure.staff = this;
		}
		else {
			print("requested index out of range!");
		}
	}

	List<Measure> get measures { return _measures; }
	void set measures(List<Measure> value) { _measures = value; }
	
	Part get partRef { return _partRef; }	
	void set partRef(Part value) { _partRef = value; }

	List<Map<NoteGroup, Lyric>> get originalLyrics => _originalLyrics;
	void set originalLyrics(List<Map<NoteGroup, Lyric>> value){
		_originalLyrics = value;
	}

	/**
	 * true if this staff is being rendered - affects whether NoteGroups and
	 * measures are included in MeasureStacks. Note, at least one staff must
	 * be visible for any given part. To hide an entire part, don't include it
	 * in the list of Parts sent for render.
	 */
	bool get visible {	return _visible; }
	void set visible(bool value) {
		if (value == false){
			bool atLeastOneStaffVisible = false;
			for (var staff in _partRef._staves){
				if (staff != this && staff._visible){
					atLeastOneStaffVisible = true;
				}
			}
			if (!atLeastOneStaffVisible){
				throw 'Part must have at least one visible Staff';
			}
		}
		_visible = value;
	}
}
