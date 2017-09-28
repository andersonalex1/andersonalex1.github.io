part of sf2.sf;

class PerformanceNoteDO {
	//all timing and positioning values are in samples
	
	int sampleStartTime = 0;
	int sampleEndTime = 0;
	AudioBuffer audioBuffer;
	
	///the start position of this note's sample data in the loaded SoundFont
	///audio file
	int sfAudioStartPos = 0;
	///the end position of this note's sample data in the loaded SoundFont audio
	///file
	int sfAudioEndPos = 0;
	int position = 0;
	int sampleRate = 44100;
	int sampleDebt = 0;
	int loopStartPos = 0;
	int loopEndPos = 0;
	num leftVolume = 0;
	num rightVolume = 0;
	int fadeInSamples = 0;
	int fadeOutSamples = 0;
	bool loop = false;
	
	//values used for envelope volume calculation
	
	///the total amount of time the note has been played, in samples (as if the
	///sample rate was actually 44100) - does not reset with loop
	int totalTimePlayed = 0;
	int attackStartTime = 0;
	int holdStartTime = 0;
	int decayStartTime = 0;
	int decayEndTime = 0;
	num sustainVolReduction = 0; //0 to 1
	
	///the volume we were at before the release phase started - must be tracked
	///in case a note ends before its envelopes finish
	num preReleaseVol = 0;
	
	int releaseStartTime = 0;
	
	
	num amplitude = 1.0;
	num pan = 0.5;
	
	
	/// adds a note to the performance. Access the complete list of notes in the
	/// sequence property.
	/// @param	midiNote 0-127 - 60 is middle C
	/// @param	startTime start time, in samples
	/// @param	duration duration, in samples
	/// @param	amplitude a value from 0 to 1 representing base volume level
	/// @param	pan a value from 0 to 1 representing pan (0 is all the way to the
	/// left, 1 is all the way to the right)
	static PerformanceNoteDO createPerformanceNote(int midiNote, int startTime,
			int duration, num amplitude, num pan, Preset preset){
		//figure out which zone the note falls within
		bool zoneFound = false;
		Zone presetZone;
		for (presetZone in preset.zones) {
			if (presetZone.bottomNote <= midiNote && presetZone.topNote >=
					midiNote && presetZone.instrument != null) {
				zoneFound = true;
				break; //we have our zone
			}
		}
		
		//if the preset doesn't have a zone with appropriate range markers for
		// this note, we won't add a sound
		if (!zoneFound) {
			return null;
		}
		
		Instrument instrument = presetZone.instrument;
		
		zoneFound = false;
		Zone instZone;
		for (instZone in instrument.zones) {
			if (instZone.bottomNote <= midiNote && instZone.topNote >=
					midiNote && instZone.sample != null) {
				zoneFound = true;
				break; //we have our zone
			}
		}
		
		//if the instrument doesn't have a zone with appropriate range markers
		// for this note, we won't add a sound
		if (!zoneFound) {
			return null;
		}
		
		var sample = instZone.sample; //get the sample used for this zone
		
		//create the note we'll add to the performance list
		var pNoteDO = new PerformanceNoteDO();
		pNoteDO.sampleStartTime = startTime;
		pNoteDO.sampleEndTime = startTime + duration;
		pNoteDO.audioBuffer = sample.audioBuffer;
		pNoteDO.sfAudioStartPos = sample.start;
		pNoteDO.sfAudioEndPos = sample.end;
		//pNoteDO.position = 0;
		pNoteDO.position = pNoteDO.sfAudioStartPos;
		
		int sampleRootPitch = sample.originalPitch;
		if (presetZone.overridingRootKey > 0){
			sampleRootPitch = presetZone.overridingRootKey;
		}
		else if (instZone.overridingRootKey > 0){
			sampleRootPitch = instZone.overridingRootKey;
		}
		//calculate the sample rate for the note based on how many steps it is
		//away from the root pitch of the sample audio data
		pNoteDO.sampleRate = (sample.sampleRate * math.pow(2, (midiNote +
			instZone.fineTune + presetZone.fineTune + instZone.courseTune +
			presetZone.courseTune - sampleRootPitch) / 12)).toInt();
		
		//loop info
		if (instZone.loop) {
			pNoteDO.loopStartPos = instZone.startLoopAddrsOffset +
				presetZone.startLoopAddrsOffset + sample.loopStart;
			pNoteDO.loopEndPos = instZone.endLoopAddrsOffset +
				presetZone.endLoopAddrsOffset + sample.loopEnd;
		}
		pNoteDO.loop = instZone.loop;
		
		//volume envelope info
		pNoteDO.attackStartTime = instZone.delayVolEnvTime +
			presetZone.delayVolEnvTime;
		pNoteDO.holdStartTime = pNoteDO.attackStartTime +
			instZone.attackVolEnvTime + presetZone.attackVolEnvTime;
		pNoteDO.decayStartTime = pNoteDO.holdStartTime +
			instZone.holdVolEnvTime + presetZone.holdVolEnvTime;
		pNoteDO.decayEndTime = pNoteDO.decayStartTime +
			instZone.decayVolEnvTime + presetZone.decayVolEnvTime;
		//pNoteDO.releaseStartTime = duration - zone.releaseVolEnvTime;
		
		pNoteDO.sustainVolReduction = instZone.sustainVolReduction +
			presetZone.sustainVolReduction;
		
		//experiment - start the release at the end of the note, advancing the end time of the note accordingly
		pNoteDO.releaseStartTime = duration;
		pNoteDO.sampleEndTime += instZone.releaseVolEnvTime +
			presetZone.releaseVolEnvTime;
		
		//volume and pan (center position is full volume, so we multiply by 2)
		pNoteDO.leftVolume = 2 * amplitude * (1 - pan);
		pNoteDO.rightVolume = 2 * amplitude * pan;
		if (pNoteDO.leftVolume > 1) { pNoteDO.leftVolume = 1; }
		if (pNoteDO.rightVolume > 1) { pNoteDO.rightVolume = 1; }
		
		pNoteDO.amplitude = amplitude;
		pNoteDO.pan = pan;
		
		return pNoteDO;
	}
}