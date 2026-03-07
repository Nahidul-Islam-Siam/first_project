import 'dart:convert';
import 'dart:io';

const _duaPath = 'assets/data/duas.json';
const _hadithPath = 'assets/data/hadith_bukhari_50.json';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Invalid list item map.');
}

String _cleanSpace(String text) {
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _cleanDuaTitleBn(String input) {
  var out = _cleanSpace(input);
  if (out.isEmpty) return out;

  const exact = {
    'সকাল এবং সন্ধ্যার জন্য স্মরণ শব্দ': 'সকাল-সন্ধ্যার যিকির',
    'বিশ্রামাগারে প্রবেশের জন্য আহ্বান': 'টয়লেটে প্রবেশের দোয়া',
    'বিশ্রামাগার ছাড়ার জন্য আহ্বান': 'টয়লেট থেকে বের হওয়ার দোয়া',
    'আথান (নামাজের আযান) শুনে কী বলবেন': 'আযান শুনে পড়ার দোয়া',
    'নামাযের শুরুর জন্য আহ্বান': 'নামাজ শুরুর দোয়া',
    'রুকির সময় দোয়া (নামাজে রুকু)': 'রুকুতে পড়ার দোয়া',
    'রুকি থেকে উঠার জন্য আহ্বান': 'রুকু থেকে ওঠার দোয়া',
    'টার্মিনাল অসুস্থ এর আহ্বান': 'মৃত্যুপথযাত্রী রোগীর দোয়া',
    'ট্র্যাজেডি স্ট্রাইক যখন জন্য আহ্বান': 'বিপদে পড়লে দোয়া',
  };

  if (exact.containsKey(out)) {
    out = exact[out]!;
  }

  out = out
      .replaceAll('আমন্ত্রণ', 'দোয়া')
      .replaceAll('আহ্বান', 'দোয়া')
      .replaceAll('দাওয়াত', 'দোয়া')
      .replaceAll('দাওয়াত', 'দোয়া')
      .replaceAll('নামায', 'নামাজ')
      .replaceAll('আথান', 'আযান')
      .replaceAll('রুকির', 'রুকুর')
      .replaceAll('রুকি', 'রুকু')
      .replaceAll('কাফফারা', 'কাফফারা')
      .replaceAll(' এর ', ' এর ')
      .replaceAll('  ', ' ');

  out = _cleanSpace(out);
  return out;
}

String _cleanHadithTitleBn(String input, int id) {
  var out = _cleanSpace(input);
  if (out.isEmpty) return 'সহিহ বুখারি হাদিস ${_toBanglaDigits(id)}';

  out = out
      .replaceAll('রাসুলুল্লাহ', 'রাসূলুল্লাহ')
      .replaceAll('রাসুল ', 'রাসূল ')
      .replaceAll(
        'সাল্লাল্লাহু ‘আলাইহি ওয়া সাল্লাম',
        'সাল্লাল্লাহু আলাইহি ওয়া সাল্লাম',
      )
      .replaceAll(
        'সাল্লাল্লাহু ‘আলাইহি ওয়া সাল্লাম',
        'সাল্লাল্লাহু আলাইহি ওয়া সাল্লাম',
      )
      .replaceAll('...', '')
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('ঃ', ':');

  out = _cleanSpace(out);
  if (out.length > 92) {
    out = '${out.substring(0, 89).trimRight()}...';
  }
  return out;
}

String _toBanglaDigits(int value) {
  var out = value.toString();
  const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  for (var i = 0; i < latin.length; i++) {
    out = out.replaceAll(latin[i], bangla[i]);
  }
  return out;
}

Future<int> _updateDuaTitles() async {
  final file = File(_duaPath);
  final raw = await file.readAsString();
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    throw const FormatException('duas.json must be a JSON list.');
  }

  var changed = 0;
  final out = <Map<String, dynamic>>[];
  for (final item in decoded) {
    final map = _asMap(item);
    final original = (map['title_bn'] ?? '').toString();
    final cleaned = _cleanDuaTitleBn(original);
    if (original != cleaned) changed += 1;
    map['title_bn'] = cleaned;
    out.add(map);
  }

  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(out)}\n',
  );
  return changed;
}

Future<int> _updateHadithTitles() async {
  final file = File(_hadithPath);
  final raw = await file.readAsString();
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    throw const FormatException('hadith_bukhari_50.json must be a JSON list.');
  }

  var changed = 0;
  final out = <Map<String, dynamic>>[];
  for (final item in decoded) {
    final map = _asMap(item);
    final id = (map['id'] as num?)?.toInt() ?? 0;
    final original = (map['title_bn'] ?? '').toString();
    final cleaned = _cleanHadithTitleBn(original, id);
    if (original != cleaned) changed += 1;
    map['title_bn'] = cleaned;
    out.add(map);
  }

  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(out)}\n',
  );
  return changed;
}

Future<void> main() async {
  try {
    final duaChanged = await _updateDuaTitles();
    final hadithChanged = await _updateHadithTitles();
    stdout.writeln('Updated dua titles: $duaChanged');
    stdout.writeln('Updated hadith titles: $hadithChanged');
  } catch (e) {
    stderr.writeln('Title review failed: $e');
    exitCode = 1;
  }
}
