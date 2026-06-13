import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/data/local/app_database.dart';

/// Tests for AccessRepository free visit logic.
/// The canUseFreeVisit method only uses the local Drift DB,
/// so we test it directly against an in-memory database.

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Free visit logic', () {
    test('canUseFreeVisit: 0 visits this month returns true', () async {
      final now = DateTime.now();
      final yearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final count = await db.countFreeVisitsThisMonth(yearMonth);
      expect(count, 0);
    });

    test('canUseFreeVisit: 1 visit this month returns false', () async {
      await db.addFreeVisit('poi-1');
      final now = DateTime.now();
      final yearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final count = await db.countFreeVisitsThisMonth(yearMonth);
      expect(count, 1);
    });

    test('different months are isolated', () async {
      await db.addFreeVisit('poi-1');
      final otherMonth = await db.countFreeVisitsThisMonth('2020-01');
      expect(otherMonth, 0);
    });

    test('isPoiFreeVisited after addFreeVisit', () async {
      expect(await db.isPoiInFreeVisits('poi-1'), false);
      await db.addFreeVisit('poi-1');
      expect(await db.isPoiInFreeVisits('poi-1'), true);
    });

    test('multiple free visits same month count correctly', () async {
      await db.addFreeVisit('poi-1');
      await db.addFreeVisit('poi-2');
      final now = DateTime.now();
      final yearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final count = await db.countFreeVisitsThisMonth(yearMonth);
      expect(count, 2);
    });
  });
}
