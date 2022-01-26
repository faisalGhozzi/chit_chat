import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';

/// Describes how the media is stored.
enum MediaStorage {
  /// The media is stored in a local file
  file,

  /// The media is stored in a in memory buffer
  buffer,

  /// The media is stored in an asset.
  asset,

  /// The media is being streamed
  stream,

  /// The media is a remote sample file.
  remoteExampleFile,
}

/// get the duration for the media with the given codec.
Future<Duration?>? getDuration(Codec? codec) async {
  Future<Duration?>? duration;
  switch (MediaPath().media) {
    case MediaStorage.file:
    case MediaStorage.buffer:
      duration = flutterSoundHelper.duration(MediaPath().pathForCodec(codec!)!);
      break;
    case MediaStorage.asset:
      duration = null;
      break;
    case MediaStorage.remoteExampleFile:
      duration = null;
      break;
    case MediaStorage.stream:
      duration = null;
      break;
    default:
      duration = null;
  }
  return duration;
}

/// formats a duration for printing.
///  mm:ss
String formatDuration(Duration duration) {
  var date =
      DateTime.fromMillisecondsSinceEpoch(duration.inMilliseconds, isUtc: true);
  return DateFormat('mm:ss', 'en_GB').format(date);
}

/// the set of samples availble as assets.
List<String> assetSample = [
  'assets/samples/sample.aac',
  'assets/samples/sample.aac',
  'assets/samples/sample.opus',
  'assets/samples/sample.caf',
  'assets/samples/sample.mp3',
  'assets/samples/sample.ogg',
  'assets/samples/sample.wav',
];

/// Checks if the past file exists
bool fileExists(String path) {
  return File(path).existsSync();
}

/// checks if the given directory exists.
bool directoryExists(String path) {
  return Directory(path).existsSync();
}

/// In this simple example, we just load a file in memory.
/// This is stupid but just for demonstration  of startPlayerFromBuffer()
Future<Uint8List?> makeBuffer(String path) async {
  try {
    if (!fileExists(path)) return null;
    var file = File(path);
    file.openRead();
    var contents = await file.readAsBytes();
    print('The file is ${contents.length} bytes long.');
    return contents;
  } on Object catch (e) {
    print(e.toString());
    return null;
  }
}

class MediaPath {
  static final MediaPath _self = MediaPath._internal();

  /// list of sample paths for each codec
  static const List<String> paths = [
    'flutter_sound_example.aac', // DEFAULT
    'flutter_sound_example.aac', // CODEC_AAC
    'flutter_sound_example.opus', // CODEC_OPUS
    'flutter_sound_example.caf', // CODEC_CAF_OPUS
    'flutter_sound_example.mp3', // CODEC_MP3
    'flutter_sound_example.ogg', // CODEC_VORBIS
    'flutter_sound_example.wav', // CODEC_PCM
  ];

  final List<String?> _path = [null, null, null, null, null, null, null];

  /// The media we are storing
  MediaStorage? media = MediaStorage.file;

  /// ctor
  factory MediaPath() {
    return _self;
  }
  MediaPath._internal();

  /// true if the media is an asset
  bool get isAsset => media == MediaStorage.asset;

  /// true if the media is an file
  bool get isFile => media == MediaStorage.file;

  /// true if the media is an buffer
  bool get isBuffer => media == MediaStorage.buffer;

  /// true if the media is the example file.
  bool get isExampleFile => media == MediaStorage.remoteExampleFile;

  /// Sets the location of the file for the given codec.
  void setCodecPath(Codec codec, String? path) {
    _path[codec.index] = path;
  }

  /// returns the path to the file for the given codec.
  String? pathForCodec(Codec codec) {
    return _path[codec.index];
  }

  /// `true` if a path for the give codec exists.
  bool exists(Codec codec) {
    return _path[codec.index] != null;
  }
}
