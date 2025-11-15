import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YouTubePlayerWidget extends StatefulWidget {
  const YouTubePlayerWidget({
    super.key,
    required this.videoId,
    this.height = 200,
    this.width,
    this.autoPlay = false,
    this.mute = false,
    this.loop = false,
    this.showControls = true,
  });

  /// YouTube video ID (e.g., 'dQw4w9WgXcQ' from 'https://www.youtube.com/watch?v=dQw4w9WgXcQ')
  final String videoId;
  final double height;
  final double? width;
  final bool autoPlay;
  final bool mute;
  final bool loop;
  final bool showControls;

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        mute: true,
        showControls: true,
        showFullscreenButton: true,
        loop: false,
        enableCaption: false,
        enableJavaScript: true,
      ),
    );
    _controller.loadVideoById(videoId: widget.videoId);
  }

  @override
  void didUpdateWidget(YouTubePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _controller.loadVideoById(videoId: widget.videoId);
    }
  }

  @override
  void dispose() {
    try {
      _controller.close();
    } catch (e) {
      // Ignore errors during disposal (can happen during hot restart)
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width ?? double.infinity,
      child: ClipRect(
        child: YoutubePlayer(
          controller: _controller,
          aspectRatio: widget.width != null 
              ? widget.width! / widget.height 
              : 16 / 9,
        ),
      ),
    );
  }
}

