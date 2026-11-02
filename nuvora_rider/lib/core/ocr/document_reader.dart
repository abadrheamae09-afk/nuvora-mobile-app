import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// License codes offered by the register form, in display order. Shared with
/// [DocumentReader] so a scanned code selects the matching dropdown option.
const List<String> licenseCodeOptions = [
  'A — Motorcycle',
  'A1 — Tricycle',
  'B — Up to 4,500 KGS GVW / 8 seats',
];

/// What a document photo gave us: values keyed by register-form field id.
class DocumentScan {
  const DocumentScan({required this.fields, required this.rawText});

  final Map<String, String> fields;
  final String rawText;

  bool get isEmpty => fields.isEmpty;
}

/// Reads a photo of a Philippine driver's license or OR / CR on the device
/// with ML Kit, then pulls the printed values out of the recognised text.
///
/// Nothing leaves the phone — only the parsed values are handed back to the
/// form, which the rider can review before submitting.
class DocumentReader {
  DocumentReader._();

  static Future<DocumentScan> license(String path) =>
      _scan(path, readLicenseText);

  static Future<DocumentScan> orCr(String path) => _scan(path, readOrCrText);

  static Future<DocumentScan> _scan(
    String path,
    Map<String, String> Function(List<String> lines) parse,
  ) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognised = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      final lines = <String>[
        for (final block in recognised.blocks)
          for (final line in block.lines) line.text,
      ];
      return DocumentScan(fields: parse(lines), rawText: lines.join('\n'));
    } finally {
      await recognizer.close();
    }
  }

  // ── Driver's license ────────────────────────────────────────────────────

  /// Field ids match `register_screen.dart` (dlLast, dlFirst, dlAddress…).
  static Map<String, String> readLicenseText(List<String> rawLines) {
    final lines = _lines(rawLines);
    final fields = <String, String>{};

    final last = _labelValue(lines, const ['LAST NAME', 'SURNAME']);
    final first = _labelValue(lines, const ['FIRST NAME', 'GIVEN NAME']);
    final middle = _labelValue(lines, const ['MIDDLE NAME', 'MIDDLE INITIAL']);
    if (last != null) fields['dlLast'] = _titleCase(last);
    if (first != null) fields['dlFirst'] = _titleCase(first);
    if (middle != null) fields['dlMiddle'] = _titleCase(middle);

    // Cards print the rider's name as "DELA CRUZ, JUAN SANTOS" above the labels.
    if (!fields.containsKey('dlLast') || !fields.containsKey('dlFirst')) {
      final comma = _commaName(lines);
      if (comma != null) {
        fields.putIfAbsent('dlLast', () => comma.$1);
        fields.putIfAbsent('dlFirst', () => comma.$2);
        if (comma.$3 != null) fields.putIfAbsent('dlMiddle', () => comma.$3!);
      }
    }

    final number = _licenseNumber(lines);
    if (number != null) fields['dlLicenseNo'] = number;

    final expiration = _date(
      _labelValue(lines, const [
        'EXPIRATION DATE',
        'EXPIRY DATE',
        'VALID UNTIL',
        'EXPIRATION',
        'EXPIRY',
      ]),
    );
    if (expiration != null) fields['dlExpiration'] = expiration;

    final nationality = _labelValue(lines, const ['NATIONALITY']);
    if (nationality != null) fields['dlNationality'] = _titleCase(nationality);

    final address = _labelValue(lines, const ['ADDRESS'], nextLines: 2);
    if (address != null) fields['dlAddress'] = address;

    final code = _licenseCode(lines);
    if (code != null) fields['dlCode'] = code;

    return fields;
  }

  static final RegExp _licensePattern = RegExp(
    r'\b([A-Z]{1,2}\d{2}[-\s]?\d{2}[-\s]?\d{6,7})\b',
  );

  static String? _licenseNumber(List<String> lines) {
    final labelled = _labelValue(lines, const ['LICENSE NO', 'LICENSE NUMBER']);
    if (labelled != null) {
      final upper = _upper(labelled);
      final match = _licensePattern.firstMatch(upper);
      if (match != null) return match.group(1);
      final compact = upper.replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (compact.length >= 10) return _spaceOut(labelled);
    }
    for (final line in lines) {
      final match = _licensePattern.firstMatch(_upper(line));
      if (match != null) return match.group(1);
    }
    return null;
  }

  static final Set<String> _blockedNameWords = {
    'CITY',
    'PROVINCE',
    'BARANGAY',
    'BRGY',
    'STREET',
    'ROAD',
    'AVENUE',
    'PHILIPPINES',
    'REGION',
    'MUNICIPALITY',
    'DISTRICT',
    'NATIONAL',
    'CAPITAL',
    'REPUBLIC',
    'TRANSPORTATION',
    'OFFICE',
    'LICENSE',
    'DATE',
    'BIRTH',
    'SEX',
    'WEIGHT',
    'HEIGHT',
    'BLOOD',
    'ADDRESS',
  };

  /// "DELA CRUZ, JUAN SANTOS" → (Dela Cruz, Juan, Santos)
  static (String, String, String?)? _commaName(List<String> lines) {
    final pattern = RegExp(
      r'^([A-ZÑ][A-ZÑ.\-\s]{1,40}),\s*([A-ZÑ][A-ZÑ.\-\s]{1,60})$',
    );
    for (final line in lines) {
      final upper = _upper(line).trim();
      final match = pattern.firstMatch(upper);
      if (match == null) continue;

      final last = match.group(1)!.trim();
      final parts = match.group(2)!.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty) continue;

      final words = <String>{...last.split(RegExp(r'\s+')), ...parts};
      if (words.any(_blockedNameWords.contains)) continue;

      return (
        _titleCase(last),
        _titleCase(parts.first),
        parts.length > 1 ? _titleCase(parts.sublist(1).join(' ')) : null,
      );
    }
    return null;
  }

  static String? _licenseCode(List<String> lines) {
    final labelled = _labelValue(lines, const [
      'LICENSE CODE',
      'AGENCY CODE',
      'LICENSE TYPE',
      'CODE',
    ]);
    if (labelled != null) {
      final upper = _upper(labelled);
      final match = RegExp(r'\b(A1|A|B1|B2|BE|B|C|D)\b').firstMatch(upper);
      if (match != null) return _codeOption(match.group(1)!);
    }
    // Fallback: a line that is nothing but the code.
    for (final line in lines) {
      final token = _upper(line).trim();
      if (token.length <= 4 &&
          RegExp(r'^(A1|A|B1|B2|BE|B|C|D)$').hasMatch(token)) {
        return _codeOption(token);
      }
    }
    return null;
  }

  static String _codeOption(String code) {
    if (code.startsWith('A1')) return licenseCodeOptions[1];
    if (code.startsWith('A')) return licenseCodeOptions[0];
    // B / B1 / B2 / C / D / BE all need the heavier-vehicle license.
    return licenseCodeOptions[2];
  }

  // ── OR / CR ─────────────────────────────────────────────────────────────

  static Map<String, String> readOrCrText(List<String> rawLines) {
    final lines = _lines(rawLines);
    final fields = <String, String>{};

    final mvFile = _labelValue(lines, const [
      'MV FILE NO',
      'MV FILE NUMBER',
      'MV FILE',
    ]);
    if (mvFile != null) {
      final compact = _upper(mvFile).replaceAll(RegExp(r'[^A-Z0-9\-]'), '');
      if (compact.length >= 6) fields['mvFile'] = _spaceOut(mvFile);
    }

    final plate = _labelValue(lines, const [
      'PLATE NO',
      'PLATE NUMBER',
      'PLATE',
    ]);
    final plateValue = _plateValue(plate) ?? _plateValue(lines.join(' '));
    if (plateValue != null) {
      fields['orPlate'] = plateValue;
      fields['plate'] = plateValue;
    }

    final make = _labelValue(lines, const ['MAKE', 'BRAND']);
    if (make != null) fields['make'] = _titleCase(make);

    final series = _labelValue(lines, const [
      'SERIES',
      'MODEL',
      'SERIES / MODEL',
    ]);
    if (series != null) fields['series'] = series.toUpperCase();

    final body = _labelValue(lines, const ['BODY TYPE', 'BODY']);
    if (body != null) {
      fields['body'] = _titleCase(body);
      final vehicle = _vehicleFrom(body);
      if (vehicle != null) fields['vehicleType'] = vehicle;
    }

    final color = _labelValue(lines, const ['COLOR']);
    if (color != null) fields['color'] = _titleCase(color);

    final year = _labelValue(lines, const ['YEAR MODEL', 'YEAR']);
    if (year != null) {
      final match = RegExp(r'(19|20)\d{2}').firstMatch(year);
      if (match != null) fields['year'] = match.group(0)!;
    }

    final engine = _labelValue(lines, const [
      'ENGINE NO',
      'ENGINE NUMBER',
      'ENGINE',
    ]);
    if (engine != null) fields['engine'] = _codeValue(engine);

    final chassis = _labelValue(lines, const [
      'CHASSIS NO',
      'CHASSIS NUMBER',
      'CHASSIS',
      'VIN',
    ]);
    if (chassis != null) fields['chassis'] = _codeValue(chassis);

    final owner = _labelValue(lines, const [
      'REGISTERED OWNER',
      'OWNER NAME',
      "OWNER'S NAME",
      'OWNER',
    ]);
    if (owner != null) fields['owner'] = _titleCase(owner);

    final ownerAddress = _labelValue(lines, const [
      "OWNER'S ADDRESS",
      'OWNER ADDRESS',
      'ADDRESS',
    ], nextLines: 1);
    if (ownerAddress != null) fields['ownerAddress'] = ownerAddress;

    final expiration = _date(
      _labelValue(lines, const [
        'REGISTRATION EXPIRATION',
        'VALID UNTIL',
        'EXPIRATION DATE',
        'EXPIRY',
      ]),
    );
    if (expiration != null) fields['regExp'] = expiration;

    return fields;
  }

  static final RegExp _platePattern = RegExp(r'\b([A-Z]{2,3}[-\s]?\d{3,5})\b');

  static String? _plateValue(String? text) {
    if (text == null) return null;
    final match = _platePattern.firstMatch(_upper(text));
    return match?.group(1)?.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String? _vehicleFrom(String body) {
    final upper = _upper(body);
    if (upper.contains('MOTOR') || upper == 'MC') return 'Motorcycle';
    if (upper.contains('TRUCK')) return 'Truck';
    if (upper.contains('VAN')) return 'Van';
    if (upper.contains('L300') || upper.contains('L-300')) return 'L300';
    return null;
  }

  // ── Shared helpers ──────────────────────────────────────────────────────

  static final RegExp _datePattern = RegExp(
    r'(\d{1,4})\s*[/\-.]\s*(\d{1,2})\s*[/\-.]\s*(\d{1,4})',
  );

  /// Normalises any printed date to the form's `mm/dd/yyyy`.
  static String? _date(String? text) {
    if (text == null) return null;
    final match = _datePattern.firstMatch(text);
    if (match == null) return null;

    var a = int.parse(match.group(1)!);
    var b = int.parse(match.group(2)!);
    var c = int.parse(match.group(3)!);

    int year;
    int month;
    int day;
    if (a > 31) {
      year = a;
      month = b;
      day = c;
    } else {
      month = a;
      day = b;
      year = c;
    }
    if (year < 100) year += 2000;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year < 1950 || year > 2100) return null;

    return '${_pad(month)}/${_pad(day)}/$year';
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');

  static const List<String> _labelKeywords = [
    'LAST NAME',
    'FIRST NAME',
    'MIDDLE NAME',
    'SURNAME',
    'LICENSE',
    'EXPIRATION',
    'EXPIRY',
    'DATE OF BIRTH',
    'BIRTH',
    'NATIONALITY',
    'ADDRESS',
    'SEX',
    'WEIGHT',
    'HEIGHT',
    'BLOOD',
    'AGENCY',
    'CODE',
    'SIGNATURE',
    'MV FILE',
    'PLATE',
    'MAKE',
    'SERIES',
    'BODY',
    'COLOR',
    'YEAR',
    'ENGINE',
    'CHASSIS',
    'OWNER',
    'REGISTERED',
    'OFFICIAL RECEIPT',
    'CERTIFICATE OF REGISTRATION',
    'VALID UNTIL',
  ];

  /// True when a line starts a new labelled block, so an address value taken
  /// from the next lines does not swallow the following field.
  static bool _looksLikeLabel(String line) {
    final upper = _upper(line);
    if (upper.length > 46) return false;
    return _labelKeywords.any(upper.startsWith);
  }

  static String? _labelValue(
    List<String> lines,
    List<String> labels, {
    int nextLines = 0,
  }) {
    for (var i = 0; i < lines.length; i++) {
      final upper = _upper(lines[i]);
      for (final label in labels) {
        final at = upper.indexOf(label);
        if (at < 0) continue;
        if (!_boundaryOk(upper, at, label.length)) continue;

        final rest = _clean(lines[i].substring(at + label.length));
        if (rest.isNotEmpty) {
          final extra = <String>[];
          for (var j = i + 1; j <= i + nextLines && j < lines.length; j++) {
            final line = _clean(lines[j]);
            if (line.isEmpty || _looksLikeLabel(line)) break;
            extra.add(line);
          }
          return _spaceOut([rest, ...extra].join(' '));
        }

        if (nextLines > 0) {
          for (var j = i + 1; j <= i + nextLines && j < lines.length; j++) {
            final line = _clean(lines[j]);
            if (line.isEmpty) continue;
            if (_looksLikeLabel(line)) break;
            return _spaceOut(line);
          }
        }
      }
    }
    return null;
  }

  /// The label must stand on its own, so "MAKE" does not match inside "MAKER".
  static bool _boundaryOk(String haystack, int start, int length) {
    final before = start == 0 ? ' ' : haystack[start - 1];
    final afterIndex = start + length;
    final after = afterIndex >= haystack.length ? ' ' : haystack[afterIndex];
    final letter = RegExp(r'[A-Z]');
    return !letter.hasMatch(before) && !letter.hasMatch(after);
  }

  static List<String> _lines(List<String> rawLines) => [
    for (final line in rawLines)
      if (_clean(line).isNotEmpty) _clean(line),
  ];

  static String _clean(String value) => value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s:;,\-–—#|.]+'), '')
      .trim();

  static String _upper(String value) => value.toUpperCase();

  static String _spaceOut(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _codeValue(String value) =>
      _upper(value).replaceAll(RegExp(r'[^A-Z0-9\-]'), '');

  static String _titleCase(String value) => value
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}
