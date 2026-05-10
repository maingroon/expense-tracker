class InsufficientHistoryException implements Exception {
  final int availableDays;
  final int requiredDays;

  const InsufficientHistoryException({
    required this.availableDays,
    required this.requiredDays,
  });

  @override
  String toString() =>
      'Need at least $requiredDays days of history; have $availableDays.';
}
