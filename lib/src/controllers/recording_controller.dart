import 'package:agora_calling_app/src/Models/recording_details_model.dart';
import 'package:agora_calling_app/src/repositories/user_repository.dart';
import 'package:agora_calling_app/src/services/auth_service.dart';
import 'package:agora_calling_app/src/widget/custom_alert.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

class RecordingController extends ControllerMVC{
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  List<RecordingDetails> recordingsList = [];
  bool isLoadingData = true;
  bool isPlaying = false;
  AudioPlayer player = AudioPlayer();
  String currentPlayingURL = '';
  int page = 1;

  playPauseRecording(url) async {
    if(isPlaying) {
      await player.pause();
      setState(() {
        isPlaying = false;
      });
      if(url != currentPlayingURL) {
        await player.play(UrlSource(url));
        setState(() {
          isPlaying = true;
          currentPlayingURL = url;
        });
      }
    } else {
      await player.play(UrlSource(url));

      player.state;
      setState(() {
        isPlaying = true;
        currentPlayingURL = url;
      });
    }

    player.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        currentPlayingURL = '';
      });
    });
  }

  Future<List<RecordingDetails>> getRecordingsList() async {
    List<RecordingDetails> data = await getRecordings(page);

    if(data.length > 0) {
      setState(() {
        page++;
        recordingsList.addAll(data);
      });
    }

    setState(() {
      isLoadingData = false;
    });

    return recordingsList;
    // final directory = await getApplicationDocumentsDirectory();
    // await Directory("${directory.path}/recordings").create(recursive: true);
    // recordingsList = Directory("${directory.path}/recordings/").listSync();
    // isLoadingData = false;
    // setState(() {});
    // return recordingsList;
  }
}