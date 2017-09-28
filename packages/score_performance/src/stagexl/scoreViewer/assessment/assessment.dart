part of score_performance.stagexl;

abstract class Assessor {
	AssessmentVisualizer _visualizer;
	
	ScoreViewer _scoreViewer;
	
	List<AssessmentNote> _noteList;
	
	int _totalCorrect = 0;
	int _totalIncorrect = 0; // ignore: unused_field
	int _totalExtra = 0;
	
	Assessor(this._scoreViewer){
		_init();
	}
	
	void _init(){
		_visualizer = _createVisualizer();
		_createAssessmentNotes();
	}
	
	void start();
	
	void stop();
	
	void reset(){
		clearAssessmentVisuals();
		_totalCorrect = _totalIncorrect = _totalExtra = 0;
	}
	
	///removes extra red notes and sets red/green notes back to black
	void clearAssessmentVisuals(){
		_visualizer.clearAssessmentVisuals(_scoreViewer);
	}
	
	///returns score for assessment performance, from 0 to 100
	num getScore(){
		int numNotes = _noteList.length;
		int extraPenalty = _totalExtra - (numNotes - _totalCorrect);
		if (extraPenalty < 0) extraPenalty = 0;
		num score = (_totalCorrect - extraPenalty) / numNotes;
		if (score < 0) score = 0;
		
		return score * 100;
	}

	AssessmentNote getAssessNoteFromVNG(VisualNoteGroup vng){
		for (var assessNote in _noteList){
			if (assessNote.vng == vng){
				return assessNote;
			}
		}
		return null;
	}
	
	void _createAssessmentNotes(){
		_noteList = [];
		for (var vng in _scoreViewer.vngList){
			var ng = vng.noteGroup;
			if (!ng.isRest && (ng.notes[0].tieState == TieState.NONE ||
					ng.notes[0].tieState == TieState.START)){
				var note = new AssessmentNote();
				note.vng = vng;
				_noteList.add(note);
			}
		}
	}
	
	void _markNoteCorrect(AssessmentNote note){
		note.matched = true;
		_totalCorrect++;
		_visualizer.markNoteCorrect(note);
	}
	
	void _markNoteIncorrect(AssessmentNote note){ // ignore: unused_element
		note.matched = false;
		_totalIncorrect++;
		_visualizer.markNoteIncorrect(note);
	}
	
	///adds extra performed note to display and tallies it
	void _addExtraNote(num time){
		_totalExtra++;
		_visualizer.addExtraNote(_scoreViewer, time);
	}

	///override in subclasses for different visualizers
	AssessmentVisualizer _createVisualizer(){
		return new AssessmentVisualizer();
	}
	
}

class AssessmentVisualizer {
	
	static final int GREEN = 0x00FF00;
	static final int RED = 0xFF0000;
	
	void markNoteCorrect(AssessmentNote note){
		note.vng.setColor(GREEN);
		note.vng.vSystemRef.refreshCache();
	}
	
	void markNoteIncorrect(AssessmentNote note){
		note.vng.setColor(RED);
		note.vng.vSystemRef.refreshCache();
	}
	
	///places a notehead on a system indicating an extra performed note
	void addExtraNote(ScoreViewer scoreViewer, num time){
		//the performed rhythm note didn't line up with a notation note - find the
		//approximate position for it and add it to the display as a red note
		num xVal = 0;
		num yVal = 0;
		
		var vngList = scoreViewer.vngList;
		
		int numNotes = vngList.length;
		
		VisualSystem targetSystem;
		
		if (vngList[0].noteGroup.qNoteTime > time) {
			//special case the situation where the user performed notes before the
			// first note in the song
			xVal = vngList[0].originalPosition.x - 30;
			targetSystem = vngList[0].vSystemRef;
		}
		else if (vngList.last.noteGroup.qNoteTime < time) {
			//special case the situation where the user performed notes after the
			// last note in the song
			xVal = vngList.last.originalPosition.x + 30;
			targetSystem = vngList.last.vSystemRef;
		}
		else {
			//the extra note falls between two notation notes - figure out
			// which two
			int i = numNotes - 1;
			while (i >= 0) {
				var cng = vngList[i].noteGroup;
				if (cng.qNoteTime <= time) {
					var noteBefore = vngList[i];
					
					//this should never have to use the noteBefore option
					var noteAfter = (i < numNotes - 1)? vngList[i + 1]
														: noteBefore;
					
					if (noteAfter.originalPosition.x >=
							noteBefore.originalPosition.x) {
						//calculate what percentage of the way between the before
						// and after notes the new note should appear
						num posRatio = (time - noteBefore.noteGroup.qNoteTime) /
							(noteAfter.noteGroup.qNoteTime -
								noteBefore.noteGroup.qNoteTime);
						xVal = noteBefore.originalPosition.x + (posRatio *
							(noteAfter.originalPosition.x -
								noteBefore.originalPosition.x));
						
					}
					else {
						//the notes before and after were on 2 different
						// systems - just put it at the end of the top system
						xVal = noteBefore.originalPosition.x + 30;
					}
					
					targetSystem = noteBefore.vSystemRef;
					
					break;
				}
				i--;
			}
			
			//draw the note on the display
			targetSystem.addExtraNotehead(xVal, yVal, RED);
			targetSystem.refreshCache();
		}
	}
	
	///removes extra red notes and sets red/green notes back to black
	void clearAssessmentVisuals(ScoreViewer scoreViewer){
		for (var vng in scoreViewer.vngList){
			vng.clearColor();
		}
		var systems = scoreViewer.vScore.getVisualSystems();
		for (var sys in systems){
			sys.removeExtraNoteheads();
			//refresh the cache here takes care of the extra notes AND the
			//note coloration from the previous loop
			sys.refreshCache();
		}
	}
}

class AssessmentNote {
	VisualNoteGroup vng;
	bool matched = false;
}