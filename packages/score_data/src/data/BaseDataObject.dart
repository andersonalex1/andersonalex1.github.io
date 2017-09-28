part of score_data.data;

class BaseDataObject {
	int _dataID = 0;
	//XmlElement _dataXML;
	
	static int _nextID = 1;
	
	BaseDataObject() {
	}
	
	static void resetIDCounter() {
		_nextID = 0;
	}
	
	/**
	 * Gets the unique dataID for this object in the score.
	 */
	int get dataID {
		if (_dataID == 0){
			_dataID = _nextID;
			_nextID++;
		}
		return _dataID;
	}
	void set dataID(int value) { _dataID = value; }
	
	/**
	 * contains the saved XML data describing this object
	 */
	//XmlElement get dataXML { return _dataXML; }
	//void set dataXML(XmlElement value) { _dataXML = value; }
}