part of score_player;

abstract class AbstractControls extends Sprite {
	AbstractPlayer pm;

	static const int DISABLED_MODE = 0;
	static const int STOPPED_MODE = 1;
	static const int PLAYING_MODE = 2;

	AbstractControls(AbstractPlayer playerManager){
		pm = playerManager;
		init();
	}

	void init(){

		draw();

		pm.addEventListener(PlayerEvent.PLAYER_INIT, onPlayerInit);
		pm.addEventListener(PlayerEvent.SONG_RENDERED, onSongRendered);
		pm.addEventListener(PlayerEvent.PLAYBACK_STARTED, onPlaybackStarted);
		pm.addEventListener(PlayerEvent.PLAYBACK_FINISHED, onPlaybackFinished);
		pm.addEventListener(PlayerEvent.SONG_CLOSING, onSongClosing);

		addListeners();
	}



	/**
	 * override this in subclasses to set controls appearance and size when
	 * screen is resized.
	 */
	void setWidth(num width){
		//scaleX = scaleY = math.min(1.75, width / _unscaledWidth);
	}

	/**
	 * override this in subclasses to return the height that should be
	 * allotted for the controls. The notation will be placed directly at this
	 * value. Default is the stageXL display height.
	 */
	num getHeight(){
		return height;
	}

	void draw(){
		throw '_draw() must be overridden!';
	}

	void onPlayerInit(PlayerEvent e){
		setMode(DISABLED_MODE);
	}

	void onSongRendered(PlayerEvent e){
		setMode(STOPPED_MODE);
	}

	void onPlaybackStarted(PlayerEvent e){
		setMode(PLAYING_MODE);
	}

	void onPlaybackFinished(PlayerEvent e){
		setMode(STOPPED_MODE);
	}

	void onSongClosing(PlayerEvent e){
		setMode(DISABLED_MODE);
	}

	///this method should be overridden in subclasses
	void setMode(int mode){
		/*if (mode == DISABLED_MODE){

		}
		else if (mode == STOPPED_MODE){

		}
		else if (mode == PLAYING_MODE){

		}*/
	}

	///this should be overridden in subclasses to add listeners for buttons,
	///etc. This does not affect the listeners for PlayerEvents that trigger
	///the mode shifts (ie. playing, stopped, disabled)
	void addListeners(){

	}

	num get tempoRatio {
		return 1.0;
	}

}