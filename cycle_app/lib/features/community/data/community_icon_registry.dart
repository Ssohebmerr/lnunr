import 'package:flutter/material.dart';

IconData communityIconFromName(String name) {
  return switch (name) {
    'chat_bubble_outline' => Icons.chat_bubble_outline,
    'favorite_outline' => Icons.favorite_outline,
    'medication_outlined' => Icons.medication_outlined,
    'healing_outlined' => Icons.healing_outlined,
    'spa_outlined' => Icons.spa_outlined,
    'water_drop_outlined' => Icons.water_drop_outlined,
    'language_outlined' => Icons.language_outlined,
    'school_outlined' => Icons.school_outlined,
    'psychology_outlined' => Icons.psychology_outlined,
    'child_care_outlined' => Icons.child_care_outlined,
    'fitness_center_outlined' => Icons.fitness_center_outlined,
    _ => Icons.groups_outlined,
  };
}

String communityIconName(IconData icon) {
  return switch (icon) {
    Icons.chat_bubble_outline => 'chat_bubble_outline',
    Icons.favorite_outline => 'favorite_outline',
    Icons.medication_outlined => 'medication_outlined',
    Icons.healing_outlined => 'healing_outlined',
    Icons.spa_outlined => 'spa_outlined',
    Icons.water_drop_outlined => 'water_drop_outlined',
    Icons.language_outlined => 'language_outlined',
    Icons.school_outlined => 'school_outlined',
    Icons.psychology_outlined => 'psychology_outlined',
    Icons.child_care_outlined => 'child_care_outlined',
    Icons.fitness_center_outlined => 'fitness_center_outlined',
    _ => 'groups_outlined',
  };
}
