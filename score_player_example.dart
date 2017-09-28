// Copyright (c) 2017, Tyler. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library score_player_example;

import 'dart:math' as math;
import 'dart:js';
import 'package:score_player/score_player.dart';
import 'package:stagexl/stagexl.dart';
import 'package:score_performance/score_performance.dart';

part 'src/BasicPlayer.dart';

main() {
	String root = _getRootPath();

	//config options for player loader
	var options = new PlayerLoaderOptions();
	options.defaultSongUrl = "songXmls/testfile.xml";
	options.resourceRoot = root;

	//config for the player
	var config = new PlayerInitConfig();
	config.songUrlPrefix = root;
	print("root: " + config.songUrlPrefix);
	new StandalonePlayerLoader(
		()=> new BasicPlayer(config: config),
		options: options);
}

String _getRootPath() {
	var paths = context['paths'];
	if (paths != null && paths.hasProperty("resourceRoot")){
		return paths["resourceRoot"];
	}
	return "";
}
