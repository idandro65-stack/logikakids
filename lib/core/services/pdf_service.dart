import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasources/local_store.dart';

class PdfService {
  static Future<void> generateAndPrintRaport(
      BuildContext context, String childName) async {
    final notulens = LocalStore.instance.notulens
        .where((n) => n.childName == childName)
        .toList();

    if (notulens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Belum ada data notulen untuk $childName')),
      );
      return;
    }

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context pdfContext) => [
          // Header Kop Klinik Resmi
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.red300, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LOGIKA KIDS',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800,
                      ),
                    ),
                    pw.Text(
                      'Pusat Terapi Harian & Tumbuh Kembang Anak',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'RAPORT EVALUASI',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red900,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Informational Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Nama Anak: $childName',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Total: ${notulens.length} Sesi Terapi Tercatat',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Sesi Notulen List
          ...notulens.map((n) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Tanggal: ${n.date} | Ruang: ${n.room}',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Text('Terapis: Bunda ${n.notulen}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  if (n.notes.isNotEmpty)
                    pw.Text('Catatan Khusus: "${n.notes}"',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.red900)),
                ],
              ),
            );
          }),

          pw.SizedBox(height: 30),
          // Signature Block
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text('Bunda Terapis Pencatat,'),
                  pw.SizedBox(height: 40),
                  pw.Text('( ____________________ )',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('Kepala Klinik Logika Kids,'),
                  pw.SizedBox(height: 40),
                  pw.Text('( Admin Logika Kids )',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Raport_Logika_Kids_$childName.pdf',
    );
  }

  static Future<void> shareToWhatsApp(
      BuildContext context, String childName) async {
    final notulens = LocalStore.instance.notulens
        .where((n) => n.childName == childName)
        .toList();

    if (notulens.isEmpty) return;

    StringBuffer buffer = StringBuffer();
    buffer.writeln('*RAPORT EVALUASI LOGIKA KIDS*');
    buffer.writeln('Nama Anak: *$childName*');
    buffer.writeln('Total Sesi: ${notulens.length} Sesi Terapi');
    buffer.writeln('-------------------------------------');

    for (var n in notulens.take(3)) {
      buffer.writeln('Tanggal: *${n.date}* (${n.room})');
      buffer.writeln('Bunda Terapis: ${n.notulen}');
      if (n.notes.isNotEmpty) buffer.writeln('Catatan: "${n.notes}"');
      buffer.writeln('');
    }
    buffer.writeln('_Logika Kids - Notulen Terapi Harian Anak_');

    final encoded = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse('https://wa.me/?text=$encoded');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Share.share(buffer.toString(), subject: 'Raport Logika Kids - $childName');
    }
  }
}
