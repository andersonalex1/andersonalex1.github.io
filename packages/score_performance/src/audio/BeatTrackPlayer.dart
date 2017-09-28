part of score_performance.audio;

typedef void Callback();

class BeatTrackPlayer {
	SFPlayer _sfPlayer;
	SFLoader _sfLoader;
	
	Callback _playbackCompleteCallback;
	
	
	BeatTrackPlayer(this._sfPlayer, this._sfLoader){
		
	}
	
	void play(Callback playbackCompleteCallback, Part part,
			bool playSoundFontNotes, int countoffBeats){
		_playbackCompleteCallback = playbackCompleteCallback;
		
		
	}
	
	void stop(){
		
	}
}