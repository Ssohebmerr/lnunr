import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The custom feminine icon set.
///
/// Each value maps to an SVG asset under `assets/icons/feminine/`. The SVGs are
/// authored as single-color filled silhouettes (with cut-outs via the
/// even-odd fill rule) and tinted at runtime with [BlendMode.srcIn], so they
/// adapt to the theme (selected / unselected, light / dark) just like a normal
/// [Icon].
enum FeminineIcon {
  home('home.svg'),
  community('community.svg'),
  selfCare('self_care.svg'),
  reports('reports.svg'),
  account('account.svg'),
  ai('ai.svg'),
  calendar('calendar.svg'),
  insights('insights.svg'),
  education('education.svg'),
  partner('partner.svg'),
  premium('premium.svg'),
  notifications('notifications.svg'),
  settings('settings.svg'),
  watch('watch.svg'),
  support('support.svg'),
  about('about.svg'),
  help('help.svg'),
  add('add.svg');

  const FeminineIcon(this.file);

  final String file;

  String get assetPath => 'assets/icons/feminine/$file';
}

/// Renders a [FeminineIcon] tinted to [color] at the given [size].
class FeminineIconView extends StatelessWidget {
  const FeminineIconView(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
  });

  final FeminineIcon icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? IconTheme.of(context).color ?? Colors.black;
    return SvgPicture.asset(
      icon.assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
