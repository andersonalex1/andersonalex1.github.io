part of score_render.stagexl.bitmap_renderer;

class BitmapMusicRenderer {

	Score _score; //the Score object with data to render
	VisualScore _visualScore; //the resulting rendered score
	SystemRenderer _systemRenderer; //creates VisualSystems

	List<Part> _parts; //the parts being displayed in the VisualScore

	List<DisplayObject> _addedObjects; //contains objects that were added during the latest render
	List<DisplayObject> _removedObjects; //contains objects that were removed during the latest render
	
	Function _rendererReadyCallback; //called after textures have been loaded

	static const num DISTANCE_BETWEEN_PAGES = 50;
	static num firstPageVerticalOffset = 50;
	
	BitmapMusicRenderer(Function readyCallback) {
		_rendererReadyCallback = readyCallback;
		init();
	}
	
	void init() {
		MusicTextures.onCompleteFunction = _rendererReadyCallback;
		MusicTextures.createTextures();
	}

	/**
	 * Creates a VisualScore object from the passed in Score object
	 * @param	score the Score object that provides the source
	 * @param	partNames the list of parts you want rendered
	 * @return	a VisualScore object that can be displayed
	 */
	VisualScore renderScore(Score score, [List<String> partNames = null]) {
		if (partNames != null){
			partNames = partNames.sublist(0); //we're going to modify this, so create a copy first
		}
		_score = score;
		_visualScore = new VisualScore(score);

		_addedObjects = [];
		_removedObjects = [];

		//get the list of parts we want
		if (partNames == null){
			_parts = score.parts;
		}
		else {
			_parts = [];
			for (var part in score.parts){
				int index = partNames.indexOf(part.name);
				if (index != -1){
					_parts.add(part);
					partNames.removeAt(index);
				}
			}
		}

		//render each system and add it to a VisualPage

		List<System> systems = score.getSystems(); //the systems to render
		_systemRenderer = new SystemRenderer(score.scoreProperties);

		List<VisualPage> vPages = []; //the VisualPage objects we add to the VisualScore
		VisualPage cVPage = null; //the current VisualPage
		for (var system in systems){
			//render the system
			VisualSystem vSystem = _systemRenderer.renderSystem(system, _parts, _addedObjects, _removedObjects);

			//check if this system goes on a new page and then add the system to a page
			if (system.newPage){
				cVPage = new VisualPage(score.scoreProperties);
				vPages.add(cVPage);
			}
			
			if (cVPage != null) {
				cVPage.addSystem(vSystem);
			}
			
			system.needsRendering = false; //set the flag so that this system won't be fully re-rendered unless needed.
		}

		//add the pages to the score
		for (int i = 0; i < vPages.length; i++) {
			//pages[i].y = i * _scoreProps.pageHeight;
			vPages[i].y = (i > 0)? vPages[i - 1].y + vPages[i - 1].height + DISTANCE_BETWEEN_PAGES : firstPageVerticalOffset;
			_visualScore.addChild(vPages[i]);
		}
		_visualScore.visualPages = vPages;


		_visualScore.mouseChildren = false;
		
		if (vPages.length > 0){
			VisualPage lastPage = vPages[vPages.length - 1];
            _visualScore.graphics.circle(0, lastPage.y + lastPage.height + 100, 1);
		}
		

		return _visualScore;
	}

	void reRender() {
		_addedObjects = [];
		_removedObjects = [];

		List<System> systems = _score.getSystems();
		List<VisualSystem> vSystems = _visualScore.getVisualSystems();
		List<VisualPage> vPages = _visualScore.visualPages;

		//give our SystemRenderer a list of the previously created VisualNoteGroup objects so it can re-use as many as possible
		_systemRenderer.legacyVNoteGroups = _visualScore.getVisualNoteGroups();

		//remove all of the VisualSystems from the VisualPages - we'll add them back or create new ones next
		for (var vPage in vPages){
			vPage.removeAllSystems();
			_visualScore.removeChild(vPage);
		}

		//iterate through all of the System objects. For any that don't need re-rendering, grab the VisualSystem that was last created for it.
		//for ones that do, create a new VisualSystem. We'll place all VisualSystems, new and old, into the existing VisualPages
		//as long as they are available. If we need new VisualPages (because additional system.newPage == true settings were found),
		//we'll create them and add them to our vPages list. If we have additional, unused VisualPages at the end, we'll remove them.
		int numSystems = systems.length;
		int pageIndex = -1; //initialize to -1, since we'll increment to 0 when the first system comes
		systems[0].newPage = true; //this should already be true, but make sure
		for (int i = 0; i < numSystems; i++){
			System cSystem = systems[i];
			if (cSystem.newPage){
				//update the current VisualPage - create a new one if we need it
				pageIndex++;
				if (pageIndex >= vPages.length){
					vPages[pageIndex] = new VisualPage(_score.scoreProperties);
				}
			}
			if (!cSystem.needsRendering){
				//try to find the previously created VisualSystem for this System
				bool vSystemFound = false;
				for (var vSystem in vSystems){
					if (vSystem.systemRef == cSystem){
						vPages[pageIndex].addSystem(vSystem);
						vSystemFound = true;
						break;
					}
				}
				if (!vSystemFound){ //if we didn't find the corresponding VisualSystem, create a new one and add it to the VisualPage
					vPages[pageIndex].addSystem(_systemRenderer.renderSystem(cSystem, _parts, _addedObjects, _removedObjects));
				}
			}
			else {
				//this system needs to be rendered again. Do it and add it to our current VisualPage
				vPages[pageIndex].addSystem(_systemRenderer.renderSystem(cSystem, _parts, _addedObjects, _removedObjects));
				cSystem.needsRendering = false;
			}
		}

		//now check to see if we have any VisualPages at the end which don't have VisualSystems - we can remove these pages.
		int i = vPages.length - 1;
		while (i >= 0){
			if (vPages[i].visualSystems.length == 0){
				vPages.removeLast();
			}
			else {
				break;
			}
			i--;
		}

		//add the pages to the score
		for (int i = 0; i < vPages.length; i++) {
			vPages[i].y = (i > 0)? vPages[i - 1].y + vPages[i - 1].height + DISTANCE_BETWEEN_PAGES : 0;
			_visualScore.addChild(vPages[i]);
		}
		_visualScore.visualPages = vPages;
	}


	/**
	 * returns all VisualNoteGroup objects in the score (a means of accessing all notes in the song)
	 * @return Vector of VisualNoteGroup objects
	 */
	List<VisualNoteGroup> getVisualNoteGroups() {
		return _visualScore.getVisualNoteGroups();
	}

	/**
	 * contains DisplayObjects that were added during the latest render
	 */
	List<DisplayObject> get addedObjects { return _addedObjects; }
	void set addedObjects(List<DisplayObject> value) { _addedObjects = value; }

	/**
	 * contains DisplayObjects that were removed during the latest render
	 */
	List<DisplayObject> get removedObjects { return _removedObjects; }
	void set removedObjects(List<DisplayObject> value) { _removedObjects = value;	}


}

