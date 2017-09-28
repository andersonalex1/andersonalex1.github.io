part of score_player;

class DivList {
	Stage _stage;
	num _width;
	num _height;
	String _title;
	List<String> _textItems;
	num _vPosRatio;
	
	html.DivElement _containerDiv;
	
	Sprite _overlay;
	
	bool _closeOnOutsideClick = true;
	
	Completer _completer;
	
	static const String ID_PREFIX = "listItem";
	
	DivList(this._stage, this._width, this._height, this._title, this._textItems,
			{num vPosRatio: 0.0}){
		_vPosRatio = vPosRatio;
	}
	
	Future<int> show(){
		_draw();
		_completer = new Completer();
		return _completer.future;
	}
	
	void _draw(){
		html.BodyElement body = html.document.getElementsByTagName("body")[0];
		
		_containerDiv = new html.DivElement();
		_containerDiv.style.width = _width.toString() + "px";
		_containerDiv.style.height = _height.toString() + "px";
		_containerDiv.style.overflow = "auto";
		_containerDiv.style.scrollBehavior = "smooth";
		_containerDiv.style.background = "linear-gradient(#EEE, #CCC)";
		_containerDiv.style.opacity = "0.98";
		_containerDiv.style.border = "1px solid #DDDDDD";
		_containerDiv.style.borderRadius = "15px";
		_containerDiv.style.boxShadow = "8px 8px 5px #888888";
		_containerDiv.style.position = "fixed";
		_containerDiv.style.top = "20%";
		//container.style.left = ((window.innerWidth - _width) / 2).toString() + "px";
		_containerDiv.style.left = "calc(50% - " + (_width / 2).toString() + "px)";
		body.append(_containerDiv);
		
		if (_title != "" && _title != null){
			var titleP = new html.ParagraphElement();
			titleP.innerHtml = _title;
			titleP.style.margin = "10px 0 15px 15px";
			titleP.style.fontSize = "2.4em";
			titleP.style.color = '#525174';
		}
		
		var list = new html.UListElement();
		list.style.margin = "10px 0 0 15px";
		list.style.listStyle = "none";
		for (int i = 0; i < _textItems.length; i++){
			var item = _textItems[i];
			var li = new html.LIElement();
			li.id = ID_PREFIX + i.toString();
			li.innerHtml = item;
			li.style.fontFamily = "Source Sans Pro";
			li.style.color = '#525174';
			li.style.marginBottom = "19px";
			li.style.fontSize = "1.8em";
			li.style.cursor = "pointer";
			list.append(li);
			
			li.onClick.listen(_onListItemClick);
		}
		_containerDiv.append(list);
		
		_containerDiv.scrollTop = (list.clientHeight * _vPosRatio).toInt();
		
		_containerDiv.onTouchMove.listen((e) => e.stopImmediatePropagation());
		
		
		_overlay = new Sprite();
		_overlay.graphics.beginPath();
		_overlay.graphics.rect(0, 0, _stage.stageWidth, _stage.stageHeight);
		_overlay.graphics.fillColor(0x00FFFFFF);
		_overlay.graphics.closePath();
		
		_stage.addChild(_overlay);
		_overlay.addEventListener(MouseEvent.CLICK, _onOverlayClicked);
		_overlay.addEventListener(TouchEvent.TOUCH_TAP, _onOverlayClicked);
	}
	
	void _onListItemClick(html.MouseEvent e){
		String id = (e.target as html.LIElement).id;
		int index = int.parse(id.substring(ID_PREFIX.length));
		_closeDivList();
		_completer.complete(index);
	}
	
	void _onOverlayClicked(InputEvent e){
		e.stopImmediatePropagation();
		if (_closeOnOutsideClick){
			_closeDivList();
			_completer.complete(-1);
		}
	}
	
	void _closeDivList(){
		_overlay.removeEventListener(MouseEvent.CLICK, _onOverlayClicked);
		_overlay.removeEventListener(TouchEvent.TOUCH_TAP, _onOverlayClicked);
		_stage.removeChild(_overlay);
		_containerDiv.remove();
	}
}