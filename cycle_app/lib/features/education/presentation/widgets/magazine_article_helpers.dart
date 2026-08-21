import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/education_content.dart';

Color articleCategoryColor(ArticleCategory category) {
  return switch (category) {
    ArticleCategory.basics => const Color(0xFF6B7FE8),
    ArticleCategory.health => const Color(0xFFE85D75),
    ArticleCategory.nutrition => const Color(0xFF3D9A78),
    ArticleCategory.mind => const Color(0xFF9B59B6),
    ArticleCategory.fertility => const Color(0xFFD4849A),
    ArticleCategory.fitness => const Color(0xFF4A90A4),
    ArticleCategory.adult => const Color(0xFFE85D75),
  };
}

String articleCategoryLabel(ArticleCategory category, AppLocalizations l10n) {
  return switch (category) {
    ArticleCategory.basics => l10n.educationCatBasics,
    ArticleCategory.health => l10n.educationCatHealth,
    ArticleCategory.nutrition => l10n.educationCatNutrition,
    ArticleCategory.mind => l10n.educationCatMind,
    ArticleCategory.fertility => l10n.educationCatFertility,
    ArticleCategory.fitness => l10n.educationCatFitness,
    ArticleCategory.adult => l10n.educationCatAdult,
  };
}
