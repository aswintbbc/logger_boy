String slotToTime(String half, int slot) {
  // Each half has 8 slots = 4 hours, each slot = 30 minutes
  int baseHour = (half == "AM") ? 9 : 1; // AM: 9–12, PM: 1–4
  int hour = baseHour + (slot ~/ 2);
  String minute = (slot % 2 == 0) ? "00" : "30";
  return "$hour:$minute";
}
