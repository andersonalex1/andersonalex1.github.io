part of score_render.stagexl.bitmap_renderer;

class VisualMeasure {
	num x;
	num y;
	num width;
	num height;
	
	Measure measureRef;
	
	VisualSystem vSystemRef;
	
	VisualMeasure([this.x = 0, this.y = 0, this.width = 0, this.height = 0, this.measureRef = null]){
		
	}
}