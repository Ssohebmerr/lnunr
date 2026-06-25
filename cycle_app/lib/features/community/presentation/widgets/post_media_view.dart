import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';

import 'package:video_player/video_player.dart';



class PostMediaView extends StatelessWidget {

  const PostMediaView({

    super.key,

    required this.mediaUrl,

    required this.mediaType,

    this.compact = false,

  });



  final String mediaUrl;

  final String mediaType;

  final bool compact;



  @override

  Widget build(BuildContext context) {

    if (mediaType == 'video') {

      if (compact) {

        return _VideoCompactPlaceholder();

      }

      return _VideoPreview(url: mediaUrl);

    }

    return ClipRRect(

      borderRadius: BorderRadius.circular(14),

      child: CachedNetworkImage(

        imageUrl: mediaUrl,

        width: double.infinity,

        fit: BoxFit.cover,

        placeholder: (_, _) => const AspectRatio(

          aspectRatio: 16 / 9,

          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),

        ),

        errorWidget: (_, _, _) => const SizedBox(

          height: 120,

          child: Center(child: Icon(Icons.broken_image_outlined)),

        ),

      ),

    );

  }

}



class _VideoCompactPlaceholder extends StatelessWidget {

  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return ClipRRect(

      borderRadius: BorderRadius.circular(14),

      child: AspectRatio(

        aspectRatio: 16 / 9,

        child: ColoredBox(

          color: Colors.black.withValues(alpha: 0.85),

          child: Center(

            child: Icon(

              Icons.play_circle_fill_rounded,

              size: 48,

              color: theme.colorScheme.primary.withValues(alpha: 0.9),

            ),

          ),

        ),

      ),

    );

  }

}



class _VideoPreview extends StatefulWidget {

  const _VideoPreview({required this.url});

  final String url;



  @override

  State<_VideoPreview> createState() => _VideoPreviewState();

}



class _VideoPreviewState extends State<_VideoPreview> {

  VideoPlayerController? _controller;

  bool _ready = false;

  bool _error = false;



  @override

  void initState() {

    super.initState();

    _init();

  }



  Future<void> _init() async {

    try {

      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));

      await c.initialize();

      if (mounted) {

        setState(() {

          _controller = c;

          _ready = true;

        });

      }

    } catch (e, st) {

      debugPrint('PostMediaView video init failed: $e\n$st');

      if (mounted) setState(() => _error = true);

    }

  }



  @override

  void dispose() {

    _controller?.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    if (_error) {

      return const SizedBox(

        height: 120,

        child: Center(child: Icon(Icons.broken_image_outlined)),

      );

    }

    if (!_ready || _controller == null) {

      return AspectRatio(

        aspectRatio: 16 / 9,

        child: DecoratedBox(

          decoration: BoxDecoration(

            color: Colors.black.withValues(alpha: 0.08),

            borderRadius: BorderRadius.circular(14),

          ),

          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),

        ),

      );

    }



    final c = _controller!;

    return ClipRRect(

      borderRadius: BorderRadius.circular(14),

      child: Stack(

        alignment: Alignment.center,

        children: [

          AspectRatio(

            aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,

            child: VideoPlayer(c),

          ),

          if (!c.value.isPlaying)

            Material(

              color: Colors.black45,

              shape: const CircleBorder(),

              child: IconButton(

                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 36),

                onPressed: () => setState(() => c.play()),

              ),

            ),

        ],

      ),

    );

  }

}

