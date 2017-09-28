part of sf2.sf;

class SFLoader {
	
	//AudioContext _context;
	
	Function _sfReadyCallback;
	
	int _numLoadedFiles;
	
	static const int _TOTAL_FILES = 2;
	
	Map _sfJson;
    AudioBuffer _sfBuffer;
    
    AudioBufferLoader _bufferLoader;
	
	List<Sample> _samples;
	List<Preset> _presets;
	
	StreamSubscription<String> _audioLoadProgressListener;
	
	StreamController<String> _progressController = new StreamController<String>();
	
	SFLoader(){
		//_context = context;
		if (SFPlayer.audioContext == null){
			SFPlayer.audioContext = new AudioContext();
		}
	}
	
	void loadSoundFont(String audioFileUrl, String jsonFileUrl, Function callback){
		_sfReadyCallback = callback;
		
		_numLoadedFiles = 0;
		_loadJsonFile(jsonFileUrl);
		_loadAudioFile(audioFileUrl);
	}
	
	/**
	 * gets the Preset object with the requested bank and preset numbers
	 * @param preset the preset number from the SF2 file
	 * @param bank the bank number from the SF2 file
	 * @return the Preset object if it is found, otherwise null
	 */
	Preset getPreset(int preset, int bank) {
		int numPresets = _presets.length;
		for (int i = 0; i < numPresets; i++){
			if (_presets[i].presetNumber == preset){
				if (_presets[i].bankNumber == bank){
					return _presets[i];
				}
			}
		}

		return null;
	}
	
	void _loadJsonFile(String jsonFileUrl) {
		HttpRequest.getString(jsonFileUrl).then((jsonString){
			_sfJson = JSON.decode(jsonString);
			if (++_numLoadedFiles == _TOTAL_FILES){
				_processFiles();
			}
		});
	}
	
	void _loadAudioFile(String audioFileUrl) {
		_bufferLoader = new AudioBufferLoader([audioFileUrl], _onSFLoaded,
			SFPlayer.audioContext);
		_audioLoadProgressListener =
			_bufferLoader.audioLoadProgress.listen(_onAudioLoadProgress);
		_bufferLoader.load();
	}
	
	void _onAudioLoadProgress(String text){
		_progressController.add(text);
	}
	
	void _onSFLoaded(List<AudioBuffer> bufferList){
		_sfBuffer = bufferList[0];
		
		_audioLoadProgressListener.cancel();
    	
		if (++_numLoadedFiles == _TOTAL_FILES){
			_processFiles();
		}
    }
	
	void _processFiles(){
		//window.alert('preparing to create audio samples');
		_progressController.add("Creating audio samples...");
		_createSampleObjects();
		//window.alert('audio samples created');
		
		_progressController.add("Creating instrument presets...");
		_createPresets();
		
		_sfBuffer = null;
		_sfJson = null;
		
		_progressController.add("SoundFont Ready");
		
		//window.alert('soundfont ready');
		_sfReadyCallback();
	}
	
	void _createSampleObjects(){
		_samples = [];
		
		var sfAudioData = _sfBuffer.getChannelData(0);
		 
		num sampleRateConv = SFPlayer.audioContext.sampleRate / 44100;

		print('sampleRateConv: ' + sampleRateConv.toString());
		
//		int mp3Offset = 0;
//		while (sfAudioData[mp3Offset] < 0.002 && sfAudioData[mp3Offset] > -0.002){
//			mp3Offset++;
//		}
//		print(mp3Offset);
		
		List<Map> sampleMaps = _sfJson['sfData']['samples']['sample'];
		
		for (Map sampleMap in sampleMaps){
			var sample = new Sample();
			sample.id = int.parse(sampleMap['id']);
			sample.name = sampleMap["name"];
			sample.start = (int.parse(sampleMap["start"]) *
				sampleRateConv).toInt();// + mp3Offset;
			sample.end = (int.parse(sampleMap["end"]) *
				sampleRateConv).toInt();// + mp3Offset;
			sample.loopStart = (int.parse(sampleMap["loopStart"]) *
				sampleRateConv).toInt();// + mp3Offset;
			sample.loopEnd = (int.parse(sampleMap["loopEnd"]) *
				sampleRateConv).toInt();// + mp3Offset;
			sample.sampleRate = int.parse(sampleMap["sampleRate"]);
			sample.originalPitch = int.parse(sampleMap["originalPitch"]);
			sample.pitchCorrection = int.parse(sampleMap["pitchCorrection"]);
			sample.sampleLink = int.parse(sampleMap["sampleLink"]);
			sample.sampleType = int.parse(sampleMap["sampleType"]);
			
			var buffer = SFPlayer.audioContext.createBuffer(1, sample.end -
				sample.start, SFPlayer.audioContext.sampleRate);
			var bufferAudioData = buffer.getChannelData(0);
			int sampleStartIndex = sample.start;
			for (int i = 0; i < bufferAudioData.length; i++){
				bufferAudioData[i] = sfAudioData[i + sampleStartIndex];
			}
			sample.audioBuffer = buffer;

			if (sample.id == 47){ //Piano 1 in TimGM6mb
				print("start: " + sample.start.toString() + " end: " + sample.end.toString() +
					" loopStart: " + sample.loopStart.toString() + " loopEnd: " +
					sample.loopEnd.toString() +	" sRate: " + sample.sampleRate.toString());
			}
            			
			//now that we have the audio data, adjust all sample times back to 0
			//based start
			sample.loopEnd -= sample.start;
			sample.loopStart -= sample.start;
			sample.end -= sample.start;
			sample.start = 0;
		
			_samples.add(sample);
		}
		
	}
	
	void _createPresets(){
		_presets = [];
		
		List<Map> presetMaps = _sfJson['sfData']['presets']['preset'];
		for (var pMap in presetMaps){
			var preset = new Preset();
			_presets.add(preset);
			preset.name = pMap['name'];
			preset.presetNumber = int.parse(pMap["presetNumber"]);
            preset.bankNumber = int.parse(pMap["bankNumber"]);

            if (preset.presetNumber == 0 && preset.bankNumber == 0){
            	print('preset 0 bank 0');
            }
            
            List<Map> pzoneMaps = (pMap['zones']['zone'] is List<Map>)?
                pMap['zones']['zone'] : [pMap['zones']['zone']];
            for (var pzMap in pzoneMaps){
            	var pzone = new Zone();
				preset.zones.add(pzone);
				pzone.startLoopAddrsOffset =
					int.parse(pzMap["startLoopAddrsOffset"]);
				pzone.endLoopAddrsOffset =
					int.parse(pzMap["endLoopAddrsOffset"]);
				pzone.bottomNote =
					int.parse(pzMap["bottomNote"]);
				pzone.topNote = int.parse(pzMap["topNote"]);
				pzone.fineTune = num.parse(pzMap["fineTune"]);
				pzone.courseTune = int.parse(pzMap["courseTune"]);
				pzone.overridingRootKey =
					int.parse(pzMap["overridingRootKey"]);
				pzone.loop = pzMap["loop"] == "true";
				pzone.delayVolEnvTime =
					int.parse(pzMap["delayVolEnvTime"]);
				pzone.attackVolEnvTime =
					int.parse(pzMap["attackVolEnvTime"]);
				pzone.holdVolEnvTime =
					int.parse(pzMap["holdVolEnvTime"]);
				pzone.decayVolEnvTime =
					int.parse(pzMap["decayVolEnvTime"]);
				pzone.sustainVolReduction =
					num.parse(pzMap["sustainVolReduction"]);
				pzone.releaseVolEnvTime =
					int.parse(pzMap["releaseVolEnvTime"]);
				pzone.isGlobal = pzMap["isGlobal"] == "true";
				
				if (pzMap['instrument'] != null &&
						pzMap['instrument']['name'] != null){
					Map iMap = pzMap['instrument'];
					var inst = new Instrument();
                    pzone.instrument = inst;
                    
                    inst.name = iMap['name'];
                    
                    List<Map> izoneMaps = (iMap['zones']['zone'] is List<Map>)?
                        iMap['zones']['zone'] : [iMap['zones']['zone']];
                    for (var izMap in izoneMaps){
        				var izone = new Zone();
        				inst.zones.add(izone);
        				izone.startLoopAddrsOffset =
					        int.parse(izMap["startLoopAddrsOffset"]);
        				izone.endLoopAddrsOffset =
					        int.parse(izMap["endLoopAddrsOffset"]);
        				izone.bottomNote = int.parse(izMap["bottomNote"]);
        				izone.topNote = int.parse(izMap["topNote"]);
        				if(izMap['sample'] != null){
        					izone.sample = _samples.where((s)=>s.id ==
						        int.parse(izMap["sample"])).first;
        				}
        				izone.fineTune = num.parse(izMap["fineTune"]);
        				izone.courseTune =
					        int.parse(izMap["courseTune"]);
        				izone.overridingRootKey =
					        int.parse(izMap["overridingRootKey"]);
        				izone.loop = izMap["loop"] == "true";
        				izone.delayVolEnvTime =
					        int.parse(izMap["delayVolEnvTime"]);
        				izone.attackVolEnvTime =
					        int.parse(izMap["attackVolEnvTime"]);
        				izone.holdVolEnvTime =
					        int.parse(izMap["holdVolEnvTime"]);
        				izone.decayVolEnvTime =
					        int.parse(izMap["decayVolEnvTime"]);
        				izone.sustainVolReduction =
					        num.parse(izMap["sustainVolReduction"]);
        				izone.releaseVolEnvTime =
					        int.parse(izMap["releaseVolEnvTime"]);
        				izone.isGlobal = izMap["isGlobal"] == "true";
                    }
				}
            }
		}
	}
	
	AudioBuffer get sfAudioBuffer { return _sfBuffer; }
	
	Stream<String> get progressStream { return _progressController.stream; }
	
}