part of score_data.data;

class Voice extends BaseDataObject {

	List<NoteGroup> _noteGroups = [];
	List<NoteGroupContainer> _noteGroupContainers;
	
	int _number = 0; //the voice number (voice 1, voice 2, etc.)
	
	Measure _measure; //the Measure this voice belongs to
	
	Voice(int number) {
		_number = number;
	}
	
	void addNoteGroup(NoteGroup noteGroup) {
		noteGroup.voice = this;
		_noteGroups.add(noteGroup);

		if (noteGroup.tuplets != null){

		}
	}

	

	/**
	 * removes the NoteGroupContainer and all child NoteGroups and NoteGroupContainers. If the parent NGC of this NGC is empty,
	 * it too is removed. This check is done recursively in both directions (for children and parents)
	 * @param ngc the NoteGroupContainer you want to remove
	 * @param removeParentIfEmpty if true, if removing the ngc leaves its parent with an empty ngcList, the parentNGC will be removed
	 * @return returns a list of NoteGroup objects that were removed
	 */
	List<NoteGroup> removeNoteGroupContainer(NoteGroupContainer ngc, [bool removeParentIfEmpty = true]) {
		//when we get a NoteGroupContainer to remove, we don't know what level it's at. We must check for levels below (all of which must be removed
		//as this NGC is removed), and we must check to see if the parent list that this ngc is removed from is now empty and should be removed.
		//we apply a recursive check in both directions.
		List<NoteGroup> removedNoteGroups = [];
		if (ngc.noteGroup != null){
			removedNoteGroups.add(ngc.noteGroup);
			_noteGroups.removeAt(_noteGroups.indexOf(ngc.noteGroup)); //base case
		}
		else {
			List<NoteGroupContainer> ngcList = ngc.ngcList;
			for (int i = ngcList.length - 1; i >= 0; i--){
				removedNoteGroups.addAll(removeNoteGroupContainer(ngcList[i], false)); //recursion down
			}
		}

		if (ngc.parentNGC != null){
			List<NoteGroupContainer> parentNGCList = ngc.parentNGC.ngcList;
			parentNGCList.removeAt(parentNGCList.indexOf(ngc));
			if (parentNGCList.length == 0 && removeParentIfEmpty){
				removeNoteGroupContainer(ngc.parentNGC); //recursion up
			}
		}
		else {
			_noteGroupContainers.removeAt(_noteGroupContainers.indexOf(ngc)); //base case
		}

		return removedNoteGroups;
	}
	
	/*public function clone():Voice {
		var voice:Voice = new Voice(_number);
		
		return voice;
	}*/
	
	List<NoteGroup> get noteGroups { return _noteGroups; }

	List<NoteGroupContainer> get noteGroupContainers { return _noteGroupContainers; }
	void set noteGroupContainers(List<NoteGroupContainer> value) { _noteGroupContainers = value; }
	
	int get number { return _number; }
	
	Measure get measure { return _measure; }		
	void set measure(Measure value) { _measure = value; }



}
