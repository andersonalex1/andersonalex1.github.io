part of score_data.music_creation;

class PitchNameManager {
	
	//List<Map<NoteGroup, Lyric>> _originalLyrics;

	Score _score;
	
	PitchNameManager(this._score){
		
	}
	
	/*void reset(){
		_originalLyrics = null;
	}*/

	/**
	 * removes note names and restores lyrics for all staves
	 */
	void showLyrics(){
		for (var part in _score.parts){
			for (var staff in part.staves){
				if (staff.originalLyrics == null){
					continue;
				}

				var originalLyrics = staff.originalLyrics;

				int lyricIndex = 0;
				//var staff = _score.parts[0].staves[0];
				for (var measure in staff.measures) {
					var voice = measure.voices[0];
					for (var ng in voice.noteGroups){
						if (lyricIndex < originalLyrics.length &&
							originalLyrics[lyricIndex].containsKey(ng)){
							ng.lyric = originalLyrics[lyricIndex][ng];
							lyricIndex++;
						}
						else {
							ng.lyric = null;
						}
					}
				}

				staff.originalLyrics = null;
			}
		}


	}
	
	void showNoteNames(Staff staff) {
		bool storeLyrics = false;

		if (staff.originalLyrics == null){
			staff.originalLyrics = [];
			storeLyrics = true;
		}

		var originalLyrics = staff.originalLyrics;
		
		num vPos = _score.scoreProperties.staffLineSpacing * -8;
		//hPos not working - hPos not hooked up in rendering?
		num hPos = _score.scoreProperties.staffLineSpacing * 0.5;
		//var staff = _score.parts[0].staves[0];
		for (var measure in staff.measures) {
			var voice = measure.voices[0];
			for (var ng in voice.noteGroups){
				if (ng.isRest || ng.isGrace){
					continue;
				}
				//var note = ng.notes[0];
				var note = ng.visibleNotes[0];
				if (storeLyrics && ng.lyric != null){
					//store the original lyrics
					originalLyrics.add({ng : ng.lyric});
				}
				if (note.tieState != "none" && note.tieState != "start"){
					//don't add note names to notes that continue or end ties
					ng.lyric = null;
					continue;
				}
				var pitchName = note.pitchName;
				pitchName = pitchName.substring(0, pitchName.length -1);
				//pitchName += _getAccidentalText(ng.notes[0].alteration);
				pitchName += _getAccidentalText(note.alteration);
				ng.lyric = new Lyric(SyllablePosition.MIDDLE, " " + pitchName, 1, hPos, vPos);
			}
		}
	}

	void updateNoteNames(){
		for (var part in _score.parts){
			for (var staff in part.staves){
				if (isStaffShowingNoteNames(staff)){
					showNoteNames(staff);
				}
			}
		}
	}
    
    String _getAccidentalText(int alteration) {
		switch (alteration) {
			case -2:
				return "bb";
			case 2:
				return "x";
			case -1:
				return "b";
			case 1:
				return "#";
			default:
				return "";
		}
	}

	bool isStaffShowingNoteNames(Staff staff){
		return staff.originalLyrics != null;
	}
}