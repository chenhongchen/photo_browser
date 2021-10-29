import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _VideoViewState();
  }
}

class _VideoViewState extends State<VideoView> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    String v1 =
        'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';
    String v2 =
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
    _controller = VideoPlayerController.network(v1)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : Container(
                color: Colors.grey,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width * 9 / 16),
        Positioned(
          bottom: 10,
          right: 10,
          child: TextButton(
            onPressed: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
            child: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 30,
            ),
          ),
        )
      ],
    );
  }
}
