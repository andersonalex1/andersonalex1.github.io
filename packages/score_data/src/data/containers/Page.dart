part of score_data.data;

class Page extends BaseDataObject {

	List<System> _systems = [];
	
	Page _previous; //the previous System
	Page _next; //the next System
	
	Page() {
		
	}
	
	void addSystem(System system) {
		if (_systems.length > 0) {
			System prevSystem = _systems[_systems.length - 1];
			prevSystem.next = system;
			system.previous = prevSystem;
		}
		system.pageRef = this;
		_systems.add(system);
	}

	/**
	 * removes the System from the Page. The System MUST have no remaining MeasureStacks for this to go through
	 * @param cSystem the empty System to remove
	 */
	void removeSystem(System system) {
		if (system.measureStacks.length == 0){
			for (int i = _systems.length - 1; i >= 0; i--){
				if (_systems[i] == system){
					_systems.removeAt(i);
					//link the previous and next systems together since their will now be a gap between them
					if (system.previous != null){
						if (system.next != null){
							system.previous.next = system.next;
						}
						else {
							system.previous.next = null;
						}
					}
					if (system.next != null){
						if (system.previous != null){
							system.next.previous = system.previous;
						}
						else {
							system.next.previous = null;
						}
					}
					return;
				}
			}
		}
		else {
			print("Attempted to remove a System that still contains MeasureStacks!");
		}
	}
	
	List<System> get systems{ return _systems; }
	
	
	Page get previous { return _previous;	}	
	void set previous(Page value) {	_previous = value; }
	
	Page get next { return _next; }		
	void set next(Page value) {	_next = value; }


}

