/// Main Navigation Screen - Simplified layout, navigation via Dashboard cards
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens.dart';

/// Vereinfachte Navigation: Dashboard ist die Hauptseite
/// Alle anderen Screens werden per Navigator.push erreicht
class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Das Dashboard ist jetzt die einzige Hauptseite
    // Alle anderen Screens werden per Navigator.push aufgerufen
    return const DashboardScreen();
  }
}
