part of audio_input.assessment;

class KeyHitRecognizer extends HitRecognizer {
	AudioContext _context;
	
	bool _sendBeatEvents = false;
	int _beatKey = 32; //32 = Spacebar
	
	StreamSubscription<html.KeyboardEvent> _keyboardSub;
	
	static KeyHitRecognizer _ref;
	
	KeyHitRecognizer(this._context):super(){
		
	}
	
	static KeyHitRecognizer getInstance(AudioContext context){
		if (_ref == null) _ref = new KeyHitRecognizer(context);
		return _ref;
	}
	
	void startHitRec(){
		if (_keyboardSub == null){
			_keyboardSub = html.document.onKeyDown.listen(_onKeyDown);
		}
	}
	
	void stopHitRec(){
		_keyboardSub.cancel();
		_keyboardSub = null;
	}
	
	void _onKeyDown(html.KeyboardEvent e){
		HitEvent hEvent = new HitEvent();
		hEvent.hitType = (e.keyCode == _beatKey && _sendBeatEvents)
										? HitType.BEAT_HIT 
										: HitType.RHYTHM_HIT;
		hEvent.keycode = e.keyCode;
		hEvent.time = _context.currentTime;
		
		_hitEventController.add(hEvent);
	}
	
	bool get sendBeatEvents => _sendBeatEvents;
	void set sendBeatEvents(bool value){ _sendBeatEvents = value; }
	
	int get beatKey => _beatKey;
	void set beatKey(int value){ _beatKey = value; }
}