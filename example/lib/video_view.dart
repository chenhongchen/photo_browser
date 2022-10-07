import 'package:flt_hc_hud/hud/hc_activity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoView extends StatefulWidget {
  const VideoView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoViewState();
  }
}

class _VideoViewState extends State<VideoView> {
  late VideoPlayerController _controller;
  bool _hiddenIndicator = false;

  @override
  void initState() {
    super.initState();
    String v1 =
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
    _controller = VideoPlayerController.network(v1)
      ..setLooping(true)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
        _controller.play();
      })
      ..addListener(() {
        if (_controller.value.position > const Duration(milliseconds: 100)) {
          setState(() {
            _hiddenIndicator = true;
          });
        }
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
        Container(
            color: Colors.black,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width * 9 / 16),
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        Positioned.fill(
          child: _hiddenIndicator
              ? Container()
              : const HCActivityIndicator(radius: 12),
        ),
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
              color: Colors.white,
              size: 36,
            ),
          ),
        )
      ],
    );
  }
}
