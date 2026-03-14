enum Mood {
  happy('😊', 'Happy'),
  calm('😌', 'Calm'),
  sad('😢', 'Sad'),
  stressed('😰', 'Stressed'),
  excited('🎉', 'Excited');

  const Mood(this.emoji, this.label);
  final String emoji;
  final String label;

  static Mood fromString(String moodLabel) {
    return Mood.values.firstWhere(
      (mood) => mood.label.toLowerCase() == moodLabel.toLowerCase(),
      orElse: () => Mood.calm,
    );
  }
}
