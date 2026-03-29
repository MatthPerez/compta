String formatDuration(String raw) {
  try {
    final parts = raw.split(":");
    if (parts.length != 3) return raw;

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;

    final totalMinutes = hours * 60 + minutes;

    // return "${totalMinutes.toString().padLeft(2, '0')} min ${seconds.toString().padLeft(2, '0')}";
    return "${totalMinutes.toString().padLeft(2, '0')} min";
  } catch (e) {
    return raw;
  }
}
