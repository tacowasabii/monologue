import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../common/format.dart';

/// 연습 영상을 전체 화면으로 재생한다.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.path, required this.title});

  final String path;
  final String title;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final _controller = VideoPlayerController.file(File(widget.path));
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _controller.play();
    }).catchError((Object _) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle(VideoPlayerValue value) {
    if (value.isPlaying) {
      _controller.pause();
    } else {
      if (value.position >= value.duration) _controller.seekTo(Duration.zero);
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: white, title: Text(widget.title)),
      body: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: _controller,
        builder: (context, value, _) {
          if (_failed || value.hasError) {
            return const Center(child: Text('이 영상은 재생할 수 없어요', style: TextStyle(color: white)));
          }
          if (!value.isInitialized) return const Center(child: CircularProgressIndicator());
          return Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggle(value),
                  child: Center(
                    child: AspectRatio(aspectRatio: value.aspectRatio, child: VideoPlayer(_controller)),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: value.isPlaying ? '일시정지' : '재생',
                        color: white,
                        icon: Icon(value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        onPressed: () => _toggle(value),
                      ),
                      Expanded(
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${formatDuration(value.position)} / ${formatDuration(value.duration)}',
                        style: const TextStyle(color: white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
