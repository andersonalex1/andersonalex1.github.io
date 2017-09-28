part of audio_input.assessment;

abstract class HitRecognizer {
	StreamController<HitEvent> _hitEventController = new StreamController.broadcast();
	
	void startHitRec();
	
	void stopHitRec();
	
	Stream<HitEvent> get onHit => _hitEventController.stream;
}

enum HitType {
	RHYTHM_HIT,
	BEAT_HIT
}

class HitEvent {
	HitType hitType;
	
	/// the time that the hit was registered - in seconds, according to AudioContext.currentTime
	num time;
	
	///if a keyboard key was pressed to initiate this clap, this denotes which key was pressed
	int keycode;
}















