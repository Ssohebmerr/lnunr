import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/community_story.dart';

/// Groups stories by author.
class StoryGroup {
  const StoryGroup({
    required this.authorUid,
    required this.authorAlias,
    required this.authorAvatarIndex,
    required this.stories,
    this.communityName,
    this.currentUid,
  });

  final String authorUid;
  final String authorAlias;
  final int authorAvatarIndex;
  final List<CommunityStory> stories;
  final String? communityName;
  final String? currentUid;

  bool get allViewed {
    if (currentUid == null || stories.isEmpty) return false;
    return stories.every((s) => s.viewedBy.contains(currentUid));
  }

  CommunityStory get latest => stories.first;
}

/// Circular avatar with animated gradient ring — like Instagram story circles.
class StoryRing extends StatelessWidget {
  const StoryRing({
    super.key,
    required this.group,
    required this.isViewed,
    required this.onTap,
    this.isCurrentUser = false,
    this.showLabel = true,
  });

  final StoryGroup group;
  final bool isViewed;
  final VoidCallback onTap;
  final bool isCurrentUser;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isViewed
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.outline.withValues(alpha: 0.25),
                          theme.colorScheme.outline.withValues(alpha: 0.15),
                        ],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AuraColors.rose,
                          AuraColors.lavenderSoft,
                          AuraColors.peachGold,
                          AuraColors.rose,
                        ],
                      ),
                boxShadow: isViewed
                    ? null
                    : [
                        BoxShadow(
                          color: AuraColors.rose
                              .withValues(alpha: isDark ? 0.15 : 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E1420) : Colors.white,
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: isCurrentUser
                      ? Container(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.4),
                          child: Icon(
                            Icons.add_rounded,
                            size: 26,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : AppAvatar(
                          radius: 28,
                          avatarIndex: group.authorAvatarIndex,
                          uidSeed: group.authorUid,
                        ),
                ),
              ),
            ),
            if (showLabel) ...[
              const SizedBox(height: 5),
              Text(
                isCurrentUser ? 'Your story' : group.authorAlias,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: isViewed ? FontWeight.w500 : FontWeight.w600,
                  color: isViewed
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-screen story viewer with progress bars, swipe navigation, and gestures.
class StoryViewer extends StatefulWidget {
  const StoryViewer({
    super.key,
    required this.groups,
    required this.initialGroupIndex,
    required this.currentUid,
    required this.onDelete,
    required this.onMarkViewed,
  });

  final List<StoryGroup> groups;
  final int initialGroupIndex;
  final String currentUid;
  final Future<void> Function(String communityId, String storyId) onDelete;
  final Future<void> Function(String communityId, String storyId) onMarkViewed;

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late int _groupIndex;
  int _storyIndex = 0;
  AnimationController? _progressController;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _groupIndex = widget.initialGroupIndex;
    _startProgress();
  }

  @override
  void dispose() {
    _progressController?.dispose();
    super.dispose();
  }

  StoryGroup get _currentGroup => widget.groups[_groupIndex];
  CommunityStory get _currentStory => _currentGroup.stories[_storyIndex];

  void _startProgress() {
    _progressController?.dispose();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _next();
        }
      });
    _progressController!.forward();

    widget.onMarkViewed(_currentStory.communityId, _currentStory.id);
  }

  void _next() {
    if (_storyIndex < _currentGroup.stories.length - 1) {
      setState(() => _storyIndex++);
      _startProgress();
    } else if (_groupIndex < widget.groups.length - 1) {
      setState(() {
        _groupIndex++;
        _storyIndex = 0;
      });
      _startProgress();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previous() {
    if (_storyIndex > 0) {
      setState(() => _storyIndex--);
      _startProgress();
    } else if (_groupIndex > 0) {
      setState(() {
        _groupIndex--;
        _storyIndex = widget.groups[_groupIndex].stories.length - 1;
      });
      _startProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = _currentStory;
    final isOwn = story.authorUid == widget.currentUid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) {
          setState(() => _paused = true);
          _progressController?.stop();
        },
        onLongPressEnd: (_) {
          setState(() => _paused = false);
          _progressController?.forward();
        },
        onTapDown: (details) {
          final w = MediaQuery.sizeOf(context).width;
          if (details.globalPosition.dx < w / 3) {
            _previous();
          } else if (details.globalPosition.dx > w * 2 / 3) {
            _next();
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story content
            if (story.isText)
              Container(
                color: Color(
                  int.tryParse(
                        story.backgroundColor?.replaceFirst('#', '0xFF') ??
                            '0xFFE8A0BF',
                      ) ??
                      0xFFE8A0BF,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      story.textOverlay ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              Image.network(
                story.mediaUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image,
                      color: Colors.white38, size: 48),
                ),
              ),
            // Gradient overlay (top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Gradient overlay (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Progress bars
            if (_progressController != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 8,
                child: Row(
                  children: List.generate(
                    _currentGroup.stories.length,
                    (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: AnimatedBuilder(
                          animation: _progressController!,
                          builder: (_, __) {
                            double value;
                            if (i < _storyIndex) {
                              value = 1.0;
                            } else if (i == _storyIndex) {
                              value = _progressController!.value;
                            } else {
                              value = 0.0;
                            }
                            return LinearProgressIndicator(
                              value: value,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              minHeight: 2.5,
                              borderRadius: BorderRadius.circular(2),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Author info
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AuraColors.rose, AuraColors.lavenderSoft],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black26,
                      child: Text(
                        story.authorAlias.isNotEmpty
                            ? story.authorAlias[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.authorAlias,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _timeAgo(story.createdAt),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwn)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white70, size: 22),
                      onPressed: () async {
                        await widget.onDelete(
                            story.communityId, story.id);
                        if (mounted) Navigator.of(context).pop();
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 26),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Text overlay
            if (story.textOverlay != null && !story.isText)
              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: Text(
                  story.textOverlay!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(blurRadius: 8, color: Colors.black54),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            // Pause indicator
            if (_paused)
              const Center(
                child: Icon(Icons.pause_rounded,
                    color: Colors.white38, size: 56),
              ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

/// Simple animated builder wrapper.
class AnimatedBuilder extends AnimatedWidget {
  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) => builder(context, null);
}
