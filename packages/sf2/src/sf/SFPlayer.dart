part of sf2.sf;

class SFPlayer {
	static AudioContext _context;
	
	List<PerformanceNoteDO> _pNoteDOs;
	List<PerformanceNoteDO> _unplayedNotes;
	
	//num _startTime = 0.0; //the AudioContext.currentTime value at start of play

	//the AudioContext.currentTime value when we reach our first audioProcessing call
	num _firstProcessTime = -1.0;
	Timer _processTimer;
	static const int processMSInterval = 500;
	//static const int processMSInterval = 50;

	//set when all notes are finished and we're close to the end of the song
	Timer _playbackCompleteTimer;
	
	//AudioBufferSourceNode _bsNode;
	
	bool _isPlaying = false;
	
	Function _playbackCompleteCallback;
	
	num SAMPLE_RATE = 44100;
	
	List<NoteNodes> _noteNodes = [];
	
	SFPlayer(){
		
	}
	
	///plays a single note
	void playNote(PerformanceNoteDO note){
		_playNote(note.sampleStartTime / SAMPLE_RATE, note);
	}
	
	/**
	 * starts the audio playback - use prepareAudio first to generate the audio
	 */
	void play([Function playbackCompleteCallback = null]){
		if (_isPlaying){
			return;
		}
		
		//////////////////
		
		//create the AudioBuffer
//		int endTime = _pNoteDOs.last.sampleEndTime;
//		for (int i = 0; i < _pNoteDOs.length; i++){
//			if (_pNoteDOs[i].sampleEndTime > endTime){
//				endTime = _pNoteDOs[i].sampleEndTime;
//			}
//		}
//		int channels = 1;
//  		int frameCount = (endTime * (_context.sampleRate / 44100)).toInt() + 2;
//  		var audioBuffer = _context.createBuffer(channels, frameCount, SAMPLE_RATE);
//  		var leftChannel = audioBuffer.getChannelData(0);
//		for (int i = 0; i < 22050; i++){
//			leftChannel[i] = 0.001;
//		}
//  		_bsNode = _context.createBufferSource();
//        _bsNode.buffer = audioBuffer;
//        _bsNode.connectNode(_context.destination);
//        _bsNode.start(0);
		//////////////////
		
        _unplayedNotes = _pNoteDOs.sublist(0);
            	
		_playbackCompleteCallback = playbackCompleteCallback;
		
		//SAMPLE_RATE = _context.sampleRate;
		//_startTime = _context.currentTime;
		_firstProcessTime = -1.0;
		
		_isPlaying = true;
		
		_processTimer = new Timer.periodic(
			const Duration(milliseconds: processMSInterval), _onAudioProcess);
		_onAudioProcess(null);
		
		_playSilentNote();
	}
	
	/**
	 * stops playback
	 */
	void stop(){
		if (_isPlaying){
			if (_processTimer != null){
				if (_processTimer.isActive){
					_processTimer.cancel();
				}
				_processTimer = null;
			}
			if (_playbackCompleteTimer != null){
				if (_playbackCompleteTimer.isActive){
					_playbackCompleteTimer.cancel();
				}
				_playbackCompleteTimer = null;
			}
			_isPlaying = false;
			
			//disconnect any remaining node references (for Chrome cleanup)
			for (var noteNode in _noteNodes){
				noteNode.disconnectNodes();
			}
			_noteNodes = [];
		}
	}
	
	void clearNotes(){
		_pNoteDOs = [];
	}
	
	void prepareAudio(List<PerformanceNoteDO> notes){
		_pNoteDOs = notes;
    	
	}
	
	void _playSilentNote(){
		var bs = _context.createBufferSource();
		bs.buffer = _context.createBuffer(1, 1024, _context.sampleRate);
		bs.start(_context.currentTime);
	}
	
	void _onAudioProcess(Timer timer) {
		num currentTime = _context.currentTime;
		//print(currentTime);
		
		if (_firstProcessTime == -1){
			_firstProcessTime = currentTime;
		}
		
		num currentSamplePos = (currentTime - _firstProcessTime) * 44100;
		
		//CLEANUP FOR CHROME - disconnect finished playing nodes
		while(_noteNodes.length > 0 && _noteNodes[0].endContextTime < currentTime){
			_noteNodes[0].disconnectNodes();
			_noteNodes.removeAt(0);
		}
		
		//get the list of unplayed notes whose start times we are approaching
		List<PerformanceNoteDO> activePNotes = [];
		while (_unplayedNotes.length > 0 && _unplayedNotes[0].sampleStartTime <=
				currentSamplePos + 2 * 44.1 * processMSInterval) {
			activePNotes.add(_unplayedNotes.removeAt(0));
		}
		
		//if there are no active notes, we can skip this iteration
		if (activePNotes.length == 0) {
			
			//check to see if we've finished all notes
			if (_unplayedNotes.length == 0){
				//stop the calls to _onAudioProcess
				_processTimer.cancel();
				
				//set a timer that will call the callback and officially stop
				//playback
				int msUntilPlaybackComplete = (_pNoteDOs.last.sampleEndTime -
					currentSamplePos) ~/ 44.1;
				var duration = new Duration(milliseconds:msUntilPlaybackComplete);
				_playbackCompleteTimer = new Timer(duration, (){
					stop();
					if (_playbackCompleteCallback != null){
						_playbackCompleteCallback();
					}
				});
			}
			
			return;
		}
		
		
		for (var note in activePNotes){
			//get the start time of this note in terms of the context.currentTime
			num noteContextTime = note.sampleStartTime / SAMPLE_RATE -
				(currentTime - _firstProcessTime) + currentTime;
			num duration = (note.sampleEndTime - note.sampleStartTime) / 44100;
			
			var bs = _context.createBufferSource();
			bs.buffer = note.audioBuffer;
			//////////TESTING ONLY - REMOVE (and restore all block quotes!)
			//bs.connectNode(_context.destination);
			//////////
			var gainNode = _context.createGain();
			gainNode.gain.setValueAtTime(1, noteContextTime);
			gainNode.gain.setValueAtTime(1, noteContextTime +
				note.decayStartTime / 44100);
			gainNode.gain.linearRampToValueAtTime(1 - note.sustainVolReduction,
				noteContextTime + note.decayEndTime / 44100);
			gainNode.gain.linearRampToValueAtTime(0, noteContextTime + duration);

			var finalGainNode = _context.createGain();
			finalGainNode.gain.value = note.amplitude;
			finalGainNode.connectNode(_context.destination);
			gainNode.connectNode(finalGainNode);
			bs.connectNode(gainNode);

			num sampleRateFac = note.sampleRate / 44100;
			bs.playbackRate.value = sampleRateFac;
			if (note.loop){
				bs.loopStart =
					//(note.loopStartPos * SAMPLE_RATE / note.sampleRate) / 44100;
					//(note.loopStartPos * note.sampleRate / SAMPLE_RATE) / 44100;
					(note.loopStartPos) / _context.sampleRate;
				bs.loopEnd =
					//(note.loopEndPos * SAMPLE_RATE / note.sampleRate) / 44100;
					//(note.loopEndPos * note.sampleRate / SAMPLE_RATE) / 44100;
					(note.loopEndPos) / _context.sampleRate;
				bs.loop = true;

				//print("lsPos: ${note.loopStartPos} noteSR: ${note.sampleRate} "
				//	"lePos: ${note.loopEndPos} bsLS: ${bs.loopStart} bsLE: ${bs.loopEnd}");
			}
			
			//print (noteContextTime - _firstProcessTime);
			bs.start(noteContextTime, 0, duration);
			bs.stop(noteContextTime + duration);
			
			//store a reference to each node along with the note's end time so
			//they can be disconnected
			_noteNodes.add(new NoteNodes(noteContextTime + duration, bs,
				gainNode, finalGainNode));
		}
		
	}
	
	void _playNote(num noteContextTime, PerformanceNoteDO note){
		//get the start time of this note in terms of the context.currentTime
		num duration = (note.sampleEndTime - note.sampleStartTime) / 44100;
		
		var bs = _context.createBufferSource();
		bs.buffer = note.audioBuffer;
		var gainNode = _context.createGain();
		gainNode.gain.setValueAtTime(1, noteContextTime);
		gainNode.gain.setValueAtTime(1, noteContextTime + note.decayStartTime / 44100);
		gainNode.gain.linearRampToValueAtTime(1 - note.sustainVolReduction, noteContextTime + note.decayEndTime / 44100);
		gainNode.gain.linearRampToValueAtTime(0, noteContextTime + duration);
		
		//var panNode = _context.createPanner();
		//panNode.setPosition(note.pan * 2 - 1, 0, 0);
		//gainNode.connectNode(panNode);
		
		var finalGainNode = _context.createGain();
		finalGainNode.gain.value = note.amplitude;
		finalGainNode.connectNode(_context.destination);
		//panNode.connectNode(finalGainNode);
		gainNode.connectNode(finalGainNode);
		
		bs.connectNode(gainNode);
		//bs.connectNode(_context.destination);
		//num sampleRateFac = note.sampleRate / note.audioBuffer.sampleRate;
		num sampleRateFac = note.sampleRate / 44100;
		bs.playbackRate.value = sampleRateFac;
		if (note.loop){
			bs.loopStart = (note.loopStartPos * SAMPLE_RATE / note.sampleRate) / 44100;
			bs.loopEnd = (note.loopEndPos * SAMPLE_RATE / note.sampleRate) / 44100;
			bs.loop = true;
		}
		
		//print (noteContextTime - _firstProcessTime);
		bs.start(noteContextTime, 0, duration);
		bs.stop(noteContextTime + duration);
		
		//store a reference to each node along with the note's end time so they can be disconnected
		_noteNodes.add(new NoteNodes(noteContextTime + duration, bs, gainNode, finalGainNode));
	}
	
//	void _onPlaybackComplete(Event e){
//		stop();
//		if (_playbackCompleteCallback != null){
//			_playbackCompleteCallback();
//		}
//	}
	
	
	bool get isPlaying { return _isPlaying; }
	
	static AudioContext get audioContext => _context;
	static void set audioContext (AudioContext value) { _context = value; }
	
}

///holds a reference to the AudioNodes and end playback time for a single note
///(for disposal purposes)
class NoteNodes {
	num endContextTime;
	AudioBufferSourceNode bufferSourceNode;
	GainNode gainNode;
	GainNode finalGainNode;
	
	NoteNodes(this.endContextTime, this.bufferSourceNode, this.gainNode,
		this.finalGainNode);
	
	void disconnectNodes(){
		bufferSourceNode.disconnect(0);
		gainNode.disconnect(0);
		finalGainNode.disconnect(0);
	}
}


