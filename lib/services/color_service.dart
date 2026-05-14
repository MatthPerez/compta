import 'package:flutter/material.dart';

class ColorService {
  static Color baseColor = Colors.deepPurple; // Couleur de base par défaut

  // Retourne une couleur 40% plus claire
  static Color get lightColor {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness(hsl.lightness * 1.4).toColor();
  }

  // Met à jour la couleur de base
  static void setBaseColor(Color color) {
    baseColor = color;
  }
}
