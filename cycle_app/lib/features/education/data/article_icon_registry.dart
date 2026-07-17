import 'package:flutter/material.dart';

/// Maps Firestore [iconName] strings to Material icons for education articles.
IconData articleIconFromName(String name) {
  return switch (name) {
    'loop_outlined' => Icons.loop_outlined,
    'brightness_4_outlined' => Icons.brightness_4_outlined,
    'emoji_nature_outlined' => Icons.emoji_nature_outlined,
    'cloud_outlined' => Icons.cloud_outlined,
    'healing_outlined' => Icons.healing_outlined,
    'medical_services_outlined' => Icons.medical_services_outlined,
    'restaurant_outlined' => Icons.restaurant_outlined,
    'fitness_center_outlined' => Icons.fitness_center_outlined,
    'psychology_outlined' => Icons.psychology_outlined,
    'volunteer_activism_outlined' => Icons.volunteer_activism_outlined,
    'favorite_outline' => Icons.favorite_outline,
    'medication_outlined' => Icons.medication_outlined,
    'menu_book_outlined' => Icons.menu_book_outlined,
    'spa_outlined' => Icons.spa_outlined,
    'self_improvement_outlined' => Icons.self_improvement_outlined,
    'calendar_month_outlined' => Icons.calendar_month_outlined,
    'bedtime_outlined' => Icons.bedtime_outlined,
    'bloodtype_outlined' => Icons.bloodtype_outlined,
    'water_drop_outlined' => Icons.water_drop_outlined,
    _ => Icons.article_outlined,
  };
}

String articleIconName(IconData icon) {
  return switch (icon) {
    Icons.loop_outlined => 'loop_outlined',
    Icons.brightness_4_outlined => 'brightness_4_outlined',
    Icons.emoji_nature_outlined => 'emoji_nature_outlined',
    Icons.cloud_outlined => 'cloud_outlined',
    Icons.healing_outlined => 'healing_outlined',
    Icons.medical_services_outlined => 'medical_services_outlined',
    Icons.restaurant_outlined => 'restaurant_outlined',
    Icons.fitness_center_outlined => 'fitness_center_outlined',
    Icons.psychology_outlined => 'psychology_outlined',
    Icons.volunteer_activism_outlined => 'volunteer_activism_outlined',
    Icons.favorite_outline => 'favorite_outline',
    Icons.medication_outlined => 'medication_outlined',
    Icons.calendar_month_outlined => 'calendar_month_outlined',
    Icons.bedtime_outlined => 'bedtime_outlined',
    Icons.bloodtype_outlined => 'bloodtype_outlined',
    Icons.water_drop_outlined => 'water_drop_outlined',
    Icons.spa_outlined => 'spa_outlined',
    _ => 'article_outlined',
  };
}
