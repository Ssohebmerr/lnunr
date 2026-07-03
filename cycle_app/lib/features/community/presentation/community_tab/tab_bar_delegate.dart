import 'package:flutter/material.dart';

import '../widgets/community_ui.dart';

class CommunityTabBarDelegate extends SliverPersistentHeaderDelegate {
  CommunityTabBarDelegate({required this.controller, required this.tabs});

  final TabController controller;
  final List<({IconData icon, String label})> tabs;

  @override
  double get minExtent => 54;
  @override
  double get maxExtent => 54;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return CommunityHubTabBar(controller: controller, tabs: tabs);
  }

  @override
  bool shouldRebuild(covariant CommunityTabBarDelegate oldDelegate) =>
      controller != oldDelegate.controller;
}
