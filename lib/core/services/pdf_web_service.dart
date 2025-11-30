import 'dart:typed_data';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart';
import 'pdf_service.dart';

/// Web PDF service implementation using JavaScript libraries
class WebPDFService implements PDFService {
  @override
  Future<PDFResult> generatePDF(PDFMetadata metadata) async {
    try {
      if (!kIsWeb) {
        throw PDFServiceException('Web PDF service can only be used on web platform');
      }

      final pdf = _createPDFDocument();
      _addTitlePage(pdf, metadata);
      _addGridPage(pdf, metadata);
      _addMaterialPage(pdf, metadata);
      _addTechnicalPage(pdf, metadata);

      final dataUri = _getPDFDataUri(pdf);
      final bytes = _dataUriToBytes(dataUri);

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
      if (!kIsWeb) {
        throw PDFServiceException('Web PDF service can only be used on web platform');
      }

      return await _downloadPDF(pdfResult);
    } catch (e) {
      throw PDFServiceException('Failed to download PDF: ${e.toString()}');
    }
  }

  dynamic _createPDFDocument() {
    // Access jsPDF from global window
    final jsPDFConstructor = globalThis.getProperty('jsPDF'.toJS);
    return jsPDFConstructor.callAsFunction(
      globalThis,
      {
        'orientation': 'portrait'.toJS,
        'unit': 'mm'.toJS,
        'format': 'a4'.toJS
      }.jsify()
    );
  }

  void _addTitlePage(dynamic pdf, PDFMetadata metadata) {
    pdf.callMethod('setFontSize'.toJS, [24.toJS]);
    pdf.callMethod('setFont'.toJS, ['helvetica'.toJS, 'bold'.toJS]);
    pdf.callMethod('text'.toJS, ['LatticeLock Security Pattern'.toJS, 20.toJS, 30.toJS]);

    pdf.callMethod('setFontSize'.toJS, [16.toJS]);
    pdf.callMethod('setFont'.toJS, ['helvetica'.toJS, 'normal'.toJS]);
    pdf.callMethod('text'.toJS, ['Blueprint Document'.toJS, 20.toJS, 45.toJS]);

    pdf.callMethod('setFontSize'.toJS, [14.toJS]);
    pdf.callMethod('text'.toJS, ['Batch Code: ${metadata.batchCode}'.toJS, 20.toJS, 70.toJS]);
    pdf.callMethod('text'.toJS, ['Algorithm: ${metadata.algorithm}'.toJS, 20.toJS, 80.toJS]);
    pdf.callMethod('text'.toJS, ['Material Profile: ${metadata.materialProfile}'.toJS, 20.toJS, 90.toJS]);
    pdf.callMethod('text'.toJS, ['Generated: ${metadata.timestamp.toIso8601String()}'.toJS, 20.toJS, 100.toJS]);
  }

  void _addGridPage(dynamic pdf, PDFMetadata metadata) {
    pdf.callMethod('addPage'.toJS, [].jsify());
    pdf.callMethod('setFontSize'.toJS, [18.toJS]);
    pdf.callMethod('setFont'.toJS, ['helvetica'.toJS, 'bold'.toJS]);
    pdf.callMethod('text'.toJS, ['Pattern Grid (${metadata.pattern.length}×${metadata.pattern.isNotEmpty ? metadata.pattern[0].length : 0})'.toJS, 20.toJS, 30.toJS]);

    // Draw grid using rectangles
    const cellSize = 10.0;
    const startX = 20.0;
    const startY = 50.0;

    for (int row = 0; row < metadata.pattern.length; row++) {
      for (int col = 0; col < metadata.pattern[row].length; col++) {
        final inkType = metadata.pattern[row][col];
        final color = _getInkColorHex(inkType);

        final x = startX + (col * cellSize);
        final y = startY + (row * cellSize);

        pdf.callMethod('setFillColor'.toJS, [color.toJS]);
        pdf.callMethod('rect'.toJS, [x.toJS, y.toJS, cellSize.toJS, cellSize.toJS, 'F'.toJS]);
        pdf.callMethod('setDrawColor'.toJS, [0.toJS, 0.toJS, 0.toJS]);
        pdf.callMethod('rect'.toJS, [x.toJS, y.toJS, cellSize.toJS, cellSize.toJS]);
      }
    }
  }

  void _addMaterialPage(dynamic pdf, PDFMetadata metadata) {
    pdf.callMethod('addPage'.toJS, [].jsify());
    pdf.callMethod('setFontSize'.toJS, [18.toJS]);
    pdf.callMethod('setFont'.toJS, ['helvetica'.toJS, 'bold'.toJS]);
    pdf.callMethod('text'.toJS, ['Material Reference Guide'.toJS, 20.toJS, 30.toJS]);

    pdf.callMethod('setFontSize'.toJS, [12.toJS]);
    pdf.callMethod('setFont'.toJS, ['helvetica'.toJS, 'normal'.toJS]);

    final materials = [
      {'ink': '75R', 'temp': '75°C', 'description': 'High-temperature data encoding'},
      {'ink': '75P', 'temp': '75°C', 'description': 'Fake element for anti-counterfeiting'},
      {'ink': '55R', 'temp': '55°C', 'description': 'Low-temperature data encoding'},
      {'ink': '55P', 'temp': '55°C', 'description': 'Additional fake element'},
      {'ink': '35M', 'temp': '35°C', 'description': 'Metadata and alignment marking'},
    ];

    double yPosition = 50;
    for (final material in materials) {
      final text = '${material['ink']} - ${material['temp']} - ${material['description']}';
      pdf.callMethod('text'.toJS, [text.toJS, 20.toJS, yPosition.toJS]);
      yPosition += 10;
    }
  }

  void _addTechnicalPage(dynamic pdf, PDFMetadata metadata) {
    pdf.callMethod('addPage'.toJS, [].jsify());
    pdf.callMethod('setFontSize'.toJS, [18.toJS]);
    pdf.callMethod('setFont'.toJS, ['helvetica'.toJS, 'bold'.toJS]);
    pdf.callMethod('text'.toJS, ['Technical Details'.toJS, 20.toJS, 30.toJS]);

    pdf.callMethod('setFontSize'.toJS, [12.toJS]);
    pdf.callMethod('setFont'.toJS, ['helvetica'.toJS, 'normal'.toJS]);

    final specs = [
      'Pattern Size: ${metadata.pattern.length}×${metadata.pattern.isNotEmpty ? metadata.pattern[0].length : 0} grid (${metadata.pattern.length * (metadata.pattern.isNotEmpty ? metadata.pattern[0].length : 0)} cells)',
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

    double yPosition = 50;
    for (final spec in specs) {
      if (spec.isNotEmpty) {
        pdf.callMethod('text'.toJS, [spec.toJS, 20.toJS, yPosition.toJS]);
      }
      yPosition += 8;
    }
  }

  String _getInkColorHex(int inkType) {
    switch (inkType) {
      case 0: return '#FF6B6B'; // 75R - Red
      case 1: return '#8B0000'; // 75P - Dark Red
      case 2: return '#FFA500'; // 55R - Orange
      case 3: return '#FFFF00'; // 55P - Yellow
      case 4: return '#32CD32'; // 35M - Green
      default: return '#E0E0E0'; // Unknown - Light Gray
    }
  }

  String _getPDFDataUri(dynamic pdf) {
    return pdf.callMethod('output'.toJS, ['datauristring'.toJS]).toDart;
  }

  Uint8List _dataUriToBytes(String dataUri) {
    // Extract base64 part from data URI
    final base64String = dataUri.split(',')[1];
    return base64.decode(base64String);
  }

  Future<bool> _downloadPDF(PDFResult pdfResult) async {
    try {
      // Use package:web for download functionality
      final base64Data = base64.encode(pdfResult.bytes);
      
      // Create JavaScript code for download
      final jsCode = '''
        (function() {
          const base64Data = '$base64Data';
          const bytes = Uint8Array.from(atob(base64Data), c => c.charCodeAt(0));
          const blob = new Blob([bytes], { type: 'application/pdf' });
          const url = URL.createObjectURL(blob);

          const a = document.createElement('a');
          a.href = url;
          a.download = '${pdfResult.metadata.filename}';
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);

          return true;
        })()
      ''';

      // Execute the JavaScript
      globalThis.callMethod(jsCode.toJS);
      
      return true;
    } catch (e) {
      throw PDFServiceException('Failed to trigger download: ${e.toString()}');
    }
  }
}