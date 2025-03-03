class Monument {
  final String name;
  final double score;
  final String imagePath;

  Monument({
    required this.name,
    required this.score,
    required this.imagePath,
  });

  factory Monument.fromJson(String name, dynamic score) {
    final double scoreValue =
        score is double ? score : double.parse(score.toString());
    final String formattedName = name.replaceAll(' ', '_');
    return Monument(
      name: name,
      score: scoreValue,
      imagePath: 'assets/$formattedName.jpg',
    );
  }

  String get matchPercentage => '${(score * 100).toStringAsFixed(0)}%';

  // Categorize recommendations based on score
  String get category {
    if (score >= 0.7) return 'Excellent Match';
    if (score >= 0.6) return 'Great Match';
    if (score >= 0.5) return 'Good Match';
    if (score >= 0.4) return 'Fair Match';
    return 'Potential Match';
  }

  // Get category color
  int get categoryColor {
    if (score >= 0.7) return 0xFF4CAF50; // Green
    if (score >= 0.6) return 0xFF8BC34A; // Light Green
    if (score >= 0.5) return 0xFFFFC107; // Amber
    if (score >= 0.4) return 0xFFFF9800; // Orange
    return 0xFF9E9E9E; // Grey
  }
}
