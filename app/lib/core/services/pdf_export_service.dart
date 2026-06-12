import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/local/app_database.dart';

class PdfExportService {
  Future<File> generateTravelLog({
    required List<VisitedPoi> visits,
    required String title,
    DateTime? from,
    DateTime? to,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(title,
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          if (from != null || to != null)
            pw.Paragraph(
              text:
                  '${from != null ? dateFormat.format(from) : 'Beginning'} - ${to != null ? dateFormat.format(to) : 'Now'}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          pw.SizedBox(height: 16),
          pw.Text('${visits.length} places visited',
              style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 16),
          ...visits.map((visit) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(visit.poiName,
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      dateFormat.format(visit.visitedAt),
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey600),
                    ),
                    if (visit.userNote != null && visit.userNote!.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Text(visit.userNote!,
                          style: const pw.TextStyle(fontSize: 11)),
                    ],
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${visit.latitude.toStringAsFixed(5)}, ${visit.longitude.toStringAsFixed(5)}',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey500),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/travel_log_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }
}
