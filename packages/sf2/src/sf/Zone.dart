part of sf2.sf;
	
class Zone {
	Instrument instrument; //only Presets set this property in their zones

	int startLoopAddrsOffset = 0;
	int endLoopAddrsOffset = 0;
	
	int bottomNote = 0;
	int topNote = 127;
	
	Sample sample; //only Instruments set this property in their zones
	
	num fineTune = 0; //the fine tuning in semitones (0.05 would be 5 cents sharp)
	int courseTune = 0; //the course tuning in semitones (5 would be 5 semitones sharp)
	int overridingRootKey = -1; //overrides the sample's root key - if -1, it does nothing
	
	bool loop = false;
	
	//Information for envelope volume. The delay, attack, hold and decay all
	//refer to the length of time, in samples, that each phase should last.
	//During the attack env, volume ramps up from nothing to full (1.0). During
	//the hold, it stays steady, and then it declines during the decay env BY
	//THE AMOUNT specified in the sustainVolReduction (not TO, but BY) the
	//release env is the amount of time taken to get to 0 after the note is released.
	int delayVolEnvTime = 43;
	int attackVolEnvTime = 43;
	int holdVolEnvTime = 43;
	int decayVolEnvTime = 43;
	num sustainVolReduction = 0; //0 to 1
	int releaseVolEnvTime = 43;


	bool isGlobal = false;
	
	
	/**
	 * creates a duplicate of the zone with all of the same property values
	 */
	Zone clone() {
		var zone = new Zone();
		zone.instrument = instrument;
		
		zone.startLoopAddrsOffset = startLoopAddrsOffset;
		zone.endLoopAddrsOffset = endLoopAddrsOffset;
		
		zone.bottomNote = bottomNote;
		zone.topNote = topNote;
		
		zone.sample = sample;
		
		zone.fineTune = fineTune;
		zone.courseTune = courseTune;
		zone.overridingRootKey = overridingRootKey;
		
		zone.loop = loop;
		
		zone.delayVolEnvTime = delayVolEnvTime;
		zone.attackVolEnvTime = attackVolEnvTime;
		zone.holdVolEnvTime = holdVolEnvTime;
		zone.decayVolEnvTime = decayVolEnvTime;
		zone.sustainVolReduction = sustainVolReduction;
		zone.releaseVolEnvTime = releaseVolEnvTime;
		
		//DON'T CLONE isGlobal
		
		return zone;
	}
	
}
