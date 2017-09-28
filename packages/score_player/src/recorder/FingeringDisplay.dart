part of score_player;

	
class FingeringDisplay extends Sprite {

	static ResourceManager resourceManager;
	
	static List<num> positions = [4, 46, 81, 116, 167, 202, 237, 272];
	
	static List<FingeringDisplay> displays;
	
	//0 for baroque, 1 for german
	static int _fingerMode = 0;
	
	//closed = 0, half hole = 1, open = 2, half thumb = 3
	static List<List<int>> _fingerings;
	
	static List<List<int>> _baroqueFingerings = [
		[0,  0, 0, 0,  0, 0, 0, 0], //C (low)
		[0,  0, 0, 0,  0, 0, 0, 1], //C#
		[0,  0, 0, 0,  0, 0, 0, 2], //D
		[0,  0, 0, 0,  0, 0, 1, 2], //Eb
		[0,  0, 0, 0,  0, 0, 2, 2], //E
		[0,  0, 0, 0,  0, 2, 0, 0], //F
		[0,  0, 0, 0,  2, 0, 0, 2], //F#
		[0,  0, 0, 0,  2, 2, 2, 2], //G
		[0,  0, 0, 2,  0, 0, 0, 2], //Ab
		[0,  0, 0, 2,  2, 2, 2, 2], //A
		[0,  0, 2, 0,  0, 2, 0, 2], //Bb
		[0,  0, 2, 2,  2, 2, 2, 2], //B
		[0,  2, 0, 2,  2, 2, 2, 2], //C
		[2,  0, 0, 2,  2, 2, 2, 2], //C#
		[2,  2, 0, 2,  2, 2, 2, 2], //D
		[2,  2, 0, 0,  0, 0, 0, 2], //Eb
		[3,  0, 0, 0,  0, 0, 2, 2], //E
		[3,  0, 0, 0,  0, 2, 0, 2], //F
		[3,  0, 0, 0,  2, 0, 2, 2], //F#
		[3,  0, 0, 0,  2, 2, 2, 2], //G
		[3,  0, 0, 2,  0, 2, 2, 2], //Ab
		[3,  0, 0, 2,  2, 2, 2, 2], //A
		[3,  0, 0, 2,  0, 0, 0, 2], //Bb
		[3,  0, 0, 2,  0, 0, 2, 2], //B
		[3,  0, 2, 2,  0, 0, 2, 2], //C
		[3,  0, 3, 0,  0, 3, 0, 0], //C#
		[3,  0, 2, 0,  0, 2, 0, 2], //D
		[3,  2, 0, 0,  2, 0, 0, 2]]; //Eb
	
	static List<List<int>> _germanFingerings = [
		[0,  0, 0, 0,  0, 0, 0, 0], //C (low)
		[0,  0, 0, 0,  0, 0, 0, 1], //C#
		[0,  0, 0, 0,  0, 0, 0, 2], //D
		[0,  0, 0, 0,  0, 0, 1, 2], //Eb
		[0,  0, 0, 0,  0, 0, 2, 2], //E
		[0,  0, 0, 0,  0, 2, 2, 2], //F
		[0,  0, 0, 0,  2, 0, 0, 0], //F#
		[0,  0, 0, 0,  2, 2, 2, 2], //G
		[0,  0, 0, 2,  0, 0, 0, 2], //Ab
		[0,  0, 0, 2,  2, 2, 2, 2], //A
		[0,  0, 2, 0,  0, 2, 2, 2], //Bb
		[0,  0, 2, 2,  2, 2, 2, 2], //B
		[0,  2, 0, 2,  2, 2, 2, 2], //C
		[2,  0, 0, 2,  2, 2, 2, 2], //C#
		[2,  2, 0, 2,  2, 2, 2, 2], //D
		[2,  2, 0, 0,  0, 0, 0, 2], //Eb
		[3,  0, 0, 0,  0, 0, 2, 2], //E
		[3,  0, 0, 0,  0, 2, 2, 2], //F
		[3,  0, 0, 0,  2, 0, 2, 0], //F#
		[3,  0, 0, 0,  2, 2, 2, 2], //G
		[3,  0, 0, 0,  2, 0, 0, 0], //Ab
		[3,  0, 0, 2,  2, 2, 2, 2], //A
		[3,  0, 0, 2,  0, 0, 0, 2], //Bb
		[3,  0, 0, 2,  0, 0, 2, 2], //B
		[3,  0, 2, 2,  0, 0, 2, 2], //C
		[3,  0, 3, 0,  0, 3, 0, 0], //C#
		[3,  0, 2, 0,  0, 2, 0, 2], //D
		[3,  2, 0, 0,  2, 0, 0, 2]]; //Eb
	
	static List<List<int>> _altoUntransposedFingerings = [
		[0,  0, 0, 0,  0, 0, 0, 0], //C (not real - place holder)
		[0,  0, 0, 0,  0, 0, 0, 0], //C# (not real - place holder)
		[0,  0, 0, 0,  0, 0, 0, 0], //D (not real - place holder)
		[0,  0, 0, 0,  0, 0, 0, 0], //Eb (not real - place holder)
		[0,  0, 0, 0,  0, 0, 0, 0], //E (not real - place holder)
		[0,  0, 0, 0,  0, 0, 0, 0], //F (low)
		[0,  0, 0, 0,  0, 0, 0, 1], //F#
		[0,  0, 0, 0,  0, 0, 0, 2], //G
		[0,  0, 0, 0,  0, 0, 1, 2], //Ab
		[0,  0, 0, 0,  0, 0, 2, 2], //A
		[0,  0, 0, 0,  0, 2, 0, 0], //Bb
		[0,  0, 0, 0,  2, 0, 0, 2], //B
		[0,  0, 0, 0,  2, 2, 2, 2], //C
		[0,  0, 0, 2,  0, 0, 0, 2], //C#
		[0,  0, 0, 2,  2, 2, 2, 2], //D
		[0,  0, 2, 0,  0, 2, 0, 2], //Eb
		[0,  0, 2, 2,  2, 2, 2, 2], //E
		[0,  2, 0, 2,  2, 2, 2, 2], //F
		[2,  0, 0, 2,  2, 2, 2, 2], //F#
		[2,  2, 0, 2,  2, 2, 2, 2], //G
		[2,  2, 0, 0,  0, 0, 0, 2], //Ab
		[3,  0, 0, 0,  0, 0, 2, 2], //A
		[3,  0, 0, 0,  0, 2, 0, 2], //Bb
		[3,  0, 0, 0,  2, 0, 2, 2], //B
		[3,  0, 0, 0,  2, 2, 2, 2], //C
		[3,  0, 0, 2,  0, 2, 2, 2], //C#
		[3,  0, 0, 2,  2, 2, 2, 2], //D
		[3,  0, 0, 2,  0, 0, 0, 2], //Eb
		[3,  0, 0, 2,  0, 0, 2, 2], //E
		[3,  0, 2, 2,  0, 0, 2, 2], //F
		[3,  0, 3, 0,  0, 3, 0, 0], //F#
		[3,  0, 2, 0,  0, 2, 0, 2], //G
		[3,  2, 0, 0,  2, 0, 0, 2]]; //Ab
	
	FingeringDisplay() {
		
	}
	
	static void createFingeringDisplays() {
		if (_fingerMode == 0) {
			_fingerings = _baroqueFingerings;
		}
		else if (_fingerMode == 1) {
			_fingerings = _germanFingerings;
		}
		else if (_fingerMode == 2) {
			_fingerings = _altoUntransposedFingerings;
		}
		else {
			print("Unrecognized fingering mode!");
		}
		displays = [];

		var gbd = resourceManager.getTextureAtlas("recorder").getBitmapData;
		for (List<int> fingering in _fingerings) {
			var display = new FingeringDisplay();
			for (int i = 0; i < 8; i++) {
				Bitmap hole;
				switch (fingering[i]) {
					case 0:
						if (i < 6) {
							hole = new Bitmap(gbd("closedHole"));// TextureAssets.closedHole);
							hole.filters = [new DropShadowFilter(3, 45, 0xFFFFFF, 1, 5)];
						}
						else {
							hole = new Bitmap(gbd("closedDoubleHole"));// TextureAssets.doubleHoleClosed);
							hole.filters = [new DropShadowFilter(1, 45, 0xFFFFFF, 1, 5)];
						}
						
						break;
					case 1: 
						hole = new Bitmap(gbd("halfClosedDoubleHole"));// TextureAssets.halfHole);
						hole.filters = [new DropShadowFilter(3, 45, 0, 1, 5)];
						break;
					case 2:
						if (i < 6) {
							hole = new Bitmap(gbd("openHole"));//TextureAssets.openHole);
							hole.filters = [new DropShadowFilter(5, 45, 0, 1, 5)];
						}
						else {
							hole = new Bitmap(gbd("openDoubleHole"));//TextureAssets.doubleHoleOpen);
							hole.filters = [new DropShadowFilter(2, 45, 0, 1, 5)];
						}							
						break;
					case 3:
						hole = new Bitmap(gbd("halfClosedHole"));//TextureAssets.halfThumb);
						hole.filters = [new DropShadowFilter(3, 45, 0, 1, 5)];
						break;
				}
				hole.scaleX = hole.scaleY = 0.5; //added for dart version (since holes were made twice as big)
				hole.x = 7;
				hole.y = positions[i] + ((26 - hole.height) / 2);
				if (i == 0) {
					//hole.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 152, 135, 49, 0);
				}
				display.addChild(hole);
			}
			displays.add(display);
		}
	}
	
	static FingeringDisplay getFingeringDisplay(int cents) {
		int index = cents ~/ 100 - 60;
		if (index < 0 || index >= _fingerings.length) {
			return null;
		}
		else {
			return displays[index];
		}
		
	}
	
	static Bitmap getFingeringDisplayAsBitmap(int cents){
		FingeringDisplay orig = getFingeringDisplay(cents);
		if (orig == null){
			return null;
		}
		//BitmapData bd = new BitmapData(orig.width.toInt() + 5, orig.height.toInt() + 5, true, 0x00000000);
		BitmapData bd = new BitmapData(orig.width.toInt() + 5, orig.height.toInt() + 5, 0x00000000);
		bd.draw(orig);
		return new Bitmap(bd);
	}
	
	static void destroyDisplays(){
		if (displays != null){
			displays = null;
		}
	}
	
	
	/**
	 * sets the mode for the fingerings (0 for baroque, 1 for german, 2 for untransposed alto)
	 */
	static int get fingerMode { return _fingerMode; }		
	static void set fingerMode(int value) {
		if (value < 0 || value > 2) {
			return;
		}
		_fingerMode = value;
		createFingeringDisplays();
	}
	
}
