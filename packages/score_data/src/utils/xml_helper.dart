//library score_data.utils.xml_helper;
//
//import 'package:xml/xml.dart';
//
//Iterable<XmlNode> _getElement(dynamic xml, String path, [int lastElementIndexOffset = 0, bool returnXMLList = false]){
//	if (path == null){
//		return null;
//	}
//	
//	if (xml is Iterable<XmlElement> || xml is Iterable<XmlNode>){
//		xml = xml.first as XmlElement;
//	}
//	
//	//List<String> terms = path.split(" ");
//	//break the string up into terms. Terms can include conditions that may have spaces, so don't split on spaces within conditions.
//	path = path.trim();
//	List<String> terms = [];
//	bool insideCondition = false;
//	int termStartIndex = 0;
//	for (int i = 0; i < path.length; i++){
//		String char = path[i];
//		if (char == " "){
//			if (!insideCondition){
//				terms.add(path.substring(termStartIndex, i));
//			}
//			while (path[i+1] == " "){
//				i++;
//			}
//			if (!insideCondition){
//				termStartIndex = i + 1;
//			}
//			
//		}
//		else if (char == "("){
//			insideCondition = true;
//		}
//		else if (char == ")"){
//			insideCondition = false;
//		}
//		
//	}
//	
//	terms.add(path.substring(termStartIndex, path.length));
//	
//	if (terms.length == 0){
//		return null;
//	}
//	
//	
//	int lastElementIndex = terms.length - 1 + lastElementIndexOffset;
//	
//	List<XmlNode> parentList;
//	int parentIndex = 0;
//	while (parentIndex <= lastElementIndex && xml != null){
//		String term = terms[parentIndex];
//		
//		//look for conditions
//		int condStartIndex = term.indexOf('(');
//		String condition = "";
//		if (condStartIndex > 0 && condStartIndex < term.length - 2){
//			condition = term.substring(condStartIndex + 1, term.length - 1);
//			term = term.substring(0, condStartIndex);
//		}
//
//		
//		if (term == "*"){
//			parentList = (parentList.first as XmlElement).children.where((e)=> e is XmlElement).toList();
//		}
//		else {
//			if (parentList != null){
//				parentList = (parentList.first as XmlElement).findElements(term).toList();
//			}
//			else {
//				parentList = (xml as XmlElement).findElements(term).toList();
//			}
//			
//		}
//		
//		
//		if (condition != "") {
//			//handle condition
//			List<String> condTerms = condition.split("==");
//			if (condTerms.length != 2){
//				return null;
//			}
//			String left = condTerms[0].trim();
//			String right = condTerms[1].trim();
//			bool isAttCondition = false;
//			if (left.indexOf("@") == 0 && left.length > 1){
//				isAttCondition = true;
//				left = left.substring(1, left.length);
//			}
//			if (left.length < 1 || right.length < 1){
//				return null;
//			}
//			
//			for (int i = parentList.length - 1; i >= 0; i--){
//				if (parentList.elementAt(i) is XmlElement){
//					if (isAttCondition){
//						if ((parentList.elementAt(i) as XmlElement).getAttribute(left) != right){
//							parentList.removeAt(i);
//						}
//					}
//					else {
//						if ((parentList.elementAt(i) as XmlElement).findElements(left).where((e) => e.text == right).length == 0){
//							parentList.removeAt(i);
//						}
//					}
//				}
//				
//			}				
//			
//		}
//		
//		if (parentList.length == 0){
//			//return null;
//			return parentList;
//		}
//		
//		parentIndex++;
//	}
//	
//	
//	return parentList;
////	if (!returnXMLList){
////		xml = (parentList.length > 0)? parentList[0] : null;
////		return xml;
////	}
////	else {
////		return parentList;
////	}
//	
//}
//
//Iterable<XmlNode> eCol(dynamic xml, String path){
//	return _getElement(xml, path, 0, true);
//}
//
//String e(dynamic xml, String path, [bool convertNullToEmptyString = false]) {
//	xml = _getElement(xml, path);
//	
//	if (xml.length > 0){
//		return xml[0].text;
//	}
//	else {
//		return (convertNullToEmptyString)? "" : null;
//	}
//}
//
//int eInt (dynamic xml, String path, [bool convertNullToZero = false]) {
//	String val = e(xml, path);
//	return (val != null)? int.parse(val) : ((convertNullToZero)? 0 : null);
//}
//
//num eNum (dynamic xml, String path, [bool convertNullToZero = false]) {
//	String val = e(xml, path);
//	return (val != null)? num.parse(val) : ((convertNullToZero)? 0 : null);
//}
//
//
//String a(dynamic xml, String path, [bool convertNullToEmptyString = false]) {
//	xml = _getElement(xml, path, -1); //for attributes, the last element is the second to last string in the path
//	
//	String val = null;
//	if (xml.length > 0){
//		path = path.trim();
//		List<String> terms = path.split(" ");
//		val = xml.first.getAttribute(terms[terms.length - 1]);
//	}
//	
//	if (val == null && convertNullToEmptyString){
//		val = "";
//	}
//	return val;
//}
//
//int aInt (dynamic xml, String path, [bool convertNullToZero = false]) {
//	String val = a(xml, path);
//	return (val != null)? int.parse(val) : ((convertNullToZero)? 0 : null);
//}
//
//num aNum (dynamic xml, String path, [bool convertNullToZero = false]) {
//	String val = a(xml, path);
//	return (val != null)? num.parse(val) : ((convertNullToZero)? 0 : null);
//}
