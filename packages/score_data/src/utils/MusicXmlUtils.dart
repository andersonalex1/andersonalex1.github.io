part of score_data.utils;

class MusicXmlUtils {

	static Future<String> getMusicXmlStringFromUrl(String url) {
		var completer = new Completer();
		if (url == null) completer.complete(null);
		try {
			if (url.lastIndexOf('.xml') == url.length - 4){
				html.HttpRequest.getString(url).then((String result){
					var cleanString = _verifyAndCleanMusicXmlString(result);
					completer.complete(cleanString);
				})
				.catchError((Object e){
					print(e.toString());
					completer.complete(null);
				});
			}
			else if (url.lastIndexOf('.mxl') == url.length - 4){
				html.HttpRequest.request(url, responseType: 'arraybuffer')
					.then((html.HttpRequest request){
						List<int> data = (request.response as ByteBuffer)
							.asUint8List().toList();
						var xmlString = _decompressMusicXml(data);
						var cleanString = (xmlString != null)
							? _verifyAndCleanMusicXmlString(xmlString) : null;
						completer.complete(cleanString);
				})
				.catchError((e){
					print(e.toString());
					completer.complete(null);
				});
			}
			else {
				completer.complete(null);
			}
		}
		catch (e){

		}
		return completer.future;
	}

	///reads a .xml or .mxl MusicXML file provided as a html.File object (this
	///typically comes from an HTML file selection Input control). Returns a
	///future that upon completion delivers the verified and cleaned MusicXML
	///as a String
	static Future<String> getMusicXmlStringFromFile(html.File file) {
		var completer = new Completer();
		html.FileReader reader = new html.FileReader();
		try {
			reader.onLoad.listen((_){
				if (reader.result is String){
					var cleanString =
						_verifyAndCleanMusicXmlString(reader.result as String);
					completer.complete(cleanString);
				}
				else {
					//List<int> data = reader.result.asUint8List().toList();
					List<int> data = (reader.result as Uint8List).toList();
					var xmlString = _decompressMusicXml(data);
					var cleanString = (xmlString != null)
						? _verifyAndCleanMusicXmlString(xmlString) : null;
					completer.complete(cleanString);
				}
			});
			if (file.name.lastIndexOf('.xml') == file.name.length - 4){
				reader.readAsText(file, "text/xml");
			}
			else if (file.name.lastIndexOf('.mxl') == file.name.length - 4){
				reader.readAsArrayBuffer(file);
			}
			else {
				completer.complete(null);
			}
		}
		catch (e){
			print(e);
			completer.complete(null);
		}
		
		return completer.future;
	}

	///decompresses binary musicXML data, verifies its validity, cleans
	///illegal characters, and returns the MusicXML as a String
	static String getMusicXmlStringFromCompressedIntList(List<int> data){
		try {
			var xmlString = _decompressMusicXml(data);
			return (xmlString != null)
				? _verifyAndCleanMusicXmlString(xmlString) : null;
		}
		catch (e){
			print(e);
			return null;
		}
	}

	///verifies string is valid MusicXML and cleans up unrecognized characters
	static String _verifyAndCleanMusicXmlString(String xmlString){
		if (xmlString.indexOf("score-partwise") == -1){
			//not a valid part-wise score
			return null;
		}

		//strip ETX character and other illegals
		return xmlString.replaceAll(new RegExp("[\x03\x00]"), ""); 
	}

	///decompresses binary List<int> into music XML string
	static String _decompressMusicXml(List<int> data){
		Archive archive = new ZipDecoder().decodeBytes(data);
		for (var file in archive.files){
			if (file.name.toLowerCase().indexOf("meta-inf/") == -1 &&
					file.name.toLowerCase().lastIndexOf(".xml") ==
					file.name.length - 4){
				var content = file.content;
				return (new String.fromCharCodes(content)); //the musicXML string
			}
			
		}
		return null;
		//var content = archive[1].content;
		//return (new String.fromCharCodes(content)); //the musicXML string
	}
}

