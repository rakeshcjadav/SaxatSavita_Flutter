/// Lunar date from a kiran's meta date line, including the Samvat year.
///
/// Example: `સંવત્‌ ૨૦૩૧ વૈશાખ સુદિ-૧૦, તા. ૨૦-૫-૭૫` → `સંવત્ ૨૦૩૧ વૈશાખ સુદિ-૧૦`.
String? kiranTithiFromMetaDate(String metaDate) {
  final cleaned = metaDate.replaceAll(RegExp(r'[\u200c\u200d]'), '').trim();
  if (cleaned.isEmpty) return null;

  final match = RegExp(
    r'(?:(સંવત્?)\s+(\S+)\s+)?(\S+)\s+(સુદી|વદી|સુદિ|વદિ|સુદ|વદ)\s*[-‐–]\s*([૦-૯0-9]+)',
  ).firstMatch(cleaned);
  if (match == null) return null;

  final month = match.group(3)!;
  if (RegExp(r'^[૦-૯0-9]+$').hasMatch(month)) return null;

  final tithi = '$month ${match.group(4)}-${match.group(5)}';
  final samvat = match.group(1);
  final year = match.group(2);
  if (samvat == null || year == null || !RegExp(r'[૦-૯0-9]').hasMatch(year)) {
    return tithi;
  }
  return '$samvat $year $tithi';
}
