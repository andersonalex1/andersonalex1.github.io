part of score_performance.audio;

class SampleTimeStampDO {
	int sampleTime = 0;
	int msTime = 0;
	num qNoteTime = 0;
	num qNoteEndTime;
	SampleTimeStampDO nextSampleTimeStampDO = null;
	num tempo = 120;
	
	SampleTimeStampDO(this.sampleTime, this.qNoteTime);
	
}