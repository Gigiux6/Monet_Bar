void main() {
  int _daysUntilNext(String dateStr, int validityDays) {
    try {
      final parts = dateStr.split('-');
      int month = 1;
      int day = 1;

      if (parts.length == 3) {
        month = int.tryParse(parts[1]) ?? 1;
        day = int.tryParse(parts[2]) ?? 1;
      } else if (parts.length == 2) {
        day = int.tryParse(parts[0]) ?? 1;
        month = int.tryParse(parts[1]) ?? 1;
      } else {
        return -1;
      }

      DateTime now = DateTime(2026, 6, 9); // mock now
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime eventThisYear = DateTime(now.year, month, day);
      DateTime eventNextYear = DateTime(now.year + 1, month, day);

      final diffToThisYear = eventThisYear.difference(today).inDays;
      
      if (diffToThisYear >= -validityDays && diffToThisYear <= validityDays) {
        return diffToThisYear;
      }

      if (eventThisYear.isBefore(today)) {
        return eventNextYear.difference(today).inDays;
      } else {
        return diffToThisYear;
      }
    } catch (_) {
      return -1;
    }
  }

  print("25-12: ${_daysUntilNext('25-12', 0)}");
  print("12-25: ${_daysUntilNext('12-25', 0)}");
  print("2024-12-25: ${_daysUntilNext('2024-12-25', 0)}");
  print("25-12-2024: ${_daysUntilNext('25-12-2024', 0)}");
  print("1990-12-25: ${_daysUntilNext('1990-12-25', 0)}");
}
