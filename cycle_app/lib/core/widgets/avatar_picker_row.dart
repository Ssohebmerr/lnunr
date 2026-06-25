import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../profile/avatar_catalog.dart';
import '../theme/app_design_tokens.dart';

class AvatarPickerRow extends StatelessWidget {
  const AvatarPickerRow({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.itemSize = 56,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double itemSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: itemSize + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AvatarCatalog.count,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final selected = i == selectedIndex;
          final url = AvatarCatalog.imageUrl(index: i, size: 128);

          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: selected ? AppShadows.softRose(opacity: 0.2) : null,
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: itemSize,
                  height: itemSize,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
