library score_performance.stagexl;

import 'dart:web_audio';
import 'dart:async';
import 'dart:math' as math;
import 'package:stagexl/stagexl.dart';
import 'package:score_data/score_data.dart';
import 'package:score_render/score_render.dart';
import 'package:sf2/sf2.dart';
import 'package:audio_input/audio_input.dart';
import 'audio.dart';

part 'stagexl/linearViewer/LinearViewer.dart';
part 'stagexl/linearViewer/SFLinearDriver.dart';

part 'stagexl/scoreViewer/ScoreViewer.dart';
part 'stagexl/scoreViewer/ScoreViewerPlaybackManager.dart';
part 'stagexl/scoreViewer/ScoreViewerViewManager.dart';
part 'stagexl/scoreViewer/SFScoreDriver.dart';
part 'stagexl/scoreViewer/assessment/assessment.dart';
part 'stagexl/scoreViewer/assessment/NoteSplitter.dart';
part 'stagexl/scoreViewer/assessment/PitchAssessor.dart';
part 'stagexl/scoreViewer/assessment/RhythmAssessor.dart';
part 'stagexl/scoreViewer/assessment/AssessmentType.dart';

part 'stagexl/scrollViewer/ScrollViewer.dart';
part 'stagexl/scrollViewer/SFScrollDriver.dart';