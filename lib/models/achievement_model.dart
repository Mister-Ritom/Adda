import 'package:flutter/material.dart';

class Achievement {
  final String title;
  String description;
  final IconData icon;
  final List<Color> colors;
  final Color textColor;

  Achievement({required this.title, required this.description, required this.icon, required this.colors,
    Color? textColor}):textColor = textColor?? Colors.white;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'icon': icon.codePoint,
      'colors': colors.map((color) => color.value).toList(),
      'textColor': textColor.value,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      title: json['title'],
      description: json['description'],
      icon: IconData(
        json['icon'],
        fontFamily: 'FontAwesomeSolid',
        fontPackage: 'font_awesome_flutter',
      ),
      colors: (json['colors'] as List<dynamic>).map((color) => Color(color)).toList(),
      textColor: Color(json['textColor']),
    );
  }

}