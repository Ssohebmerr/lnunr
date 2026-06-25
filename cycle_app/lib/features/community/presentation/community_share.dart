import 'package:share_plus/share_plus.dart';

import '../data/models/community_post.dart';

Future<void> shareCommunityPost({
  required CommunityPost post,
  required String communityName,
  required String shareLabel,
}) async {
  final buffer = StringBuffer()
    ..writeln(post.authorAlias)
    ..writeln()
    ..writeln(post.text.trim())
    ..writeln()
    ..writeln('— $communityName')
    ..writeln(shareLabel);

  await SharePlus.instance.share(ShareParams(text: buffer.toString().trim()));
}
