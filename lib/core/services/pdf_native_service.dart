import 'dart:io' show Directory, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_service.dart';
import '../utils/platform_detector.dart';

/// Native PDF service implementation for desktop and mobile platforms
class NativePDFService implements PDFService {
  @override
  Future<PDFResult> generatePDF(PDFMetadata metadata) async {
    try {
      if (kIsWeb) {
        throw PDFServiceException('Native PDF service cannot be used on web platform');
      }

      final pdf = pw.Document();

      // Add title page
      pdf.addPage(_buildTitlePage(metadata));

      // Add grid visualization
      pdf.addPage(_buildGridPage(metadata));

      // Add material reference
      pdf.addPage(_buildMaterialPage(metadata));

      // Add technical details
      pdf.addPage(_buildTechnicalPage(metadata));

      final bytes = await pdf.save();

      return PDFResult(
        bytes: bytes,
        metadata: metadata,
      );
    } catch (e) {
      return PDFResult.error(
        metadata: metadata,
        error: 'Failed to generate PDF: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> downloadOrSharePDF(PDFResult pdfResult) async {
    try {
      if (kIsWeb) {
        throw PDFServiceException('Native PDF service cannot be used on web platform');
      }

      if (PlatformDetector.isMobile) {
        return await _sharePDF(pdfResult);
      } else {
        return await _savePDF(pdfResult);
      }
    } catch (e) {
      throw PDFServiceException('Failed to download/share PDF: ${e.toString()}');
    }
  }

  pw.Page _buildTitlePage(PDFMetadata metadata) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 80),
            pw.Text(
              'LatticeLock Security Pattern',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                font: pw.Font.helvetica(),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Blueprint Document',
              style: pw.TextStyle(
                fontSize: 16,
                font: pw.Font.helvetica(),
              ),
            ),
            pw.SizedBox(height: 40),
            pw.Text(
              'Batch Code: ${metadata.batchCode}',
              style: pw.TextStyle(
                fontSize: 14,
                font: pw.Font.helvetica(),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Algorithm: ${metadata.algorithm}',
              style: pw.TextStyle(
                fontSize: 14,
                font: pw.Font.helvetica(),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Material Profile: ${metadata.materialProfile}',
              style: pw.TextStyle(
                fontSize: 14,
                font: pw.Font.helvetica(),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Generated: ${metadata.timestamp.toIso8601String()}',
              style: pw.TextStyle(
                fontSize: 14,
                font: pw.Font.helvetica(),
              ),
            ),
          ],
        );
      },
    );
  }

  pw.Page _buildGridPage(PDFMetadata metadata) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 80),
            pw.Text(
              'Pattern Grid (8×8)',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                font: pw.Font.helvetica(),
              ),
            ),
            pw.SizedBox(height: 40),
            // Draw 8x8 grid
            pw.SizedBox(
              width: 400,
              height: 400,
              child: pw.GridView(
                crossAxisCount: metadata.pattern.isNotEmpty ? metadata.pattern[0].length : 8,
                childAspectRatio: 1,
                children: List.generate(
                  metadata.pattern.length * (metadata.pattern.isNotEmpty ? metadata.pattern[0].length : 8),
                  (index) {
                    final row = index ~/ (metadata.pattern.isNotEmpty ? metadata.pattern[0].length : 8);
                    final col = index % (metadata.pattern.isNotEmpty ? metadata.pattern[0].length : 8);
                    final inkType = row < metadata.pattern.length && col < metadata.pattern[row].length
                        ? metadata.pattern[row][col]
                        : 0;
                    final color = _getInkColor(inkType);

                    return pw.Container(
                      decoration: pw.BoxDecoration(
                        color: color,
                        border: pw.Border.all(color: PdfColors.black, width: 0.5),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  pw.Page _buildMaterialPage(PDFMetadata metadata) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        // Material reference
        final materials = [
          {'ink': '75R', 'temp': '75°C', 'description': 'High-temperature data encoding'},
          {'ink': '75P', 'temp': '75°C', 'description': 'Fake element for anti-counterfeiting'},
          {'ink': '55R', 'temp': '55°C', 'description': 'Low-temperature data encoding'},
          {'ink': '55P', 'temp': '55°C', 'description': 'Additional fake element'},
          {'ink': '35M', 'temp': '35°C', 'description': 'Metadata and alignment marking'},
        ];

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 80),
            pw.Text(
              'Material Reference Guide',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                font: pw.Font.helvetica(),
              ),
            ),
            pw.SizedBox(height: 40),
            ...materials.map((material) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 15),
              child: pw.Text(
                '${material['ink']} - ${material['temp']} - ${material['description']}',
                style: pw.TextStyle(
                  fontSize: 12,
                  font: pw.Font.helvetica(),
                ),
              ),
            )),
          ],
        );
      },
    );
  }

  pw.Page _buildTechnicalPage(PDFMetadata metadata) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        // Technical specifications
        final specs = [
          'Pattern Size: 8×8 grid (64 cells)',
          'Encryption Algorithm: ${metadata.algorithm}',
          'Material Set: ${metadata.materialProfile}',
          'Generation Time: ${metadata.timestamp.toIso8601String()}',
          'Pattern Data: ${metadata.pattern.length}×${metadata.pattern.isNotEmpty ? metadata.pattern[0].length : 0}',
          '',
          'Security Features:',
          '- Chaos-based cryptography',
          '- Temperature-reactive inks',
          '- Anti-counterfeiting fake elements',
          '- Metadata encoding',
        ];

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 80),
            pw.Text(
              'Technical Details',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                font: pw.Font.helvetica(),
              ),
            ),
            pw.SizedBox(height: 40),
            ...specs.map((spec) => spec.isNotEmpty
                ? pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Text(
                      spec,
                      style: pw.TextStyle(
                        fontSize: 12,
                        font: pw.Font.helvetica(),
                      ),
                    ),
                  )
                : pw.SizedBox(height: 15)),
          ],
        );
      },
    );
  }

  PdfColor _getInkColor(int inkType) {
    switch (inkType) {
      case 0: return PdfColor.fromHex('#FF6B6B'); // 75R - Red
      case 1: return PdfColor.fromHex('#8B0000'); // 75P - Dark Red
      case 2: return PdfColor.fromHex('#FFA500'); // 55R - Orange
      case 3: return PdfColor.fromHex('#FFFF00'); // 55P - Yellow
      case 4: return PdfColor.fromHex('#32CD32'); // 35M - Green
      default: return PdfColor.fromHex('#E0E0E0'); // Unknown - Light Gray
    }
  }

  Future<bool> _sharePDF(PDFResult pdfResult) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = XFile.fromData(
        pdfResult.bytes,
        name: pdfResult.metadata.filename,
        path: '${tempDir.path}/${pdfResult.metadata.filename}',
      );

      final params = ShareParams(
        files: [file],
        subject: 'LatticeLock Pattern PDF',
        text: 'LatticeLock Security Pattern',
      );

      final result = await SharePlus.instance.share(params);
      return result.status == ShareResultStatus.success;
    } catch (e) {
      throw PDFServiceException('Failed to share PDF: ${e.toString()}');
    }
  }

  Future<bool> _savePDF(PDFResult pdfResult) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/latticelock_blueprints/${pdfResult.metadata.filename}';

      // Create directory if it doesn't exist
      final blueprintDir = '${directory.path}/latticelock_blueprints';
      await Directory(blueprintDir).create(recursive: true);

      final file = File(path);
      await file.writeAsBytes(pdfResult.bytes);

      return true;
    } catch (e) {
      throw PDFServiceException('Failed to save PDF: ${e.toString()}');
    }
  }
}