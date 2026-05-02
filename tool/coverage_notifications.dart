import 'dart:io';

void main() {
  final f = File('coverage/lcov.info');
  if (!f.existsSync()) {
    print('LCOV_NOT_FOUND');
    exit(0);
  }

  final lines = f.readAsLinesSync();
  String? current;
  final Map<String, Map<String, int>> fileStats =
      {}; // path -> {total, covered}

  for (var line in lines) {
    if (line.startsWith('SF:')) {
      current = line.substring(3);
    } else if (line.startsWith('DA:') && current != null) {
      final curNorm = current.replaceAll('\\', '/');
      if (curNorm.contains('lib/features/notifications')) {
        final rest = line.substring(3).split(',');
        if (rest.length >= 2) {
          final hits = int.tryParse(rest[1]) ?? 0;
          final key = curNorm;
          fileStats.putIfAbsent(key, () => {'total': 0, 'covered': 0});
          fileStats[key]!['total'] = fileStats[key]!['total']! + 1;
          if (hits > 0)
            fileStats[key]!['covered'] = fileStats[key]!['covered']! + 1;
        }
      }
    }
  }

  if (fileStats.isEmpty) {
    print('NO_DATA');
    return;
  }

  int total = 0, covered = 0;
  final keys = fileStats.keys.toList();
  keys.sort();
  for (var k in keys) {
    final t = fileStats[k]!['total']!;
    final c = fileStats[k]!['covered']!;
    total += t;
    covered += c;
    final pct = t == 0 ? 0.0 : c / t * 100.0;
    print('$k => $c/$t => ${pct.toStringAsFixed(2)}%');
  }

  final overall = covered / total * 100.0;
  print('---');
  print('TOTAL => $covered/$total => ${overall.toStringAsFixed(2)}%');
}
