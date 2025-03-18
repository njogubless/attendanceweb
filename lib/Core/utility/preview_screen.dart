import 'package:attendanceweb/Core/utility/pdf_service.dart';
import 'package:flutter/material.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfPreviewScreen extends StatelessWidget {
  final pw.Document pdf;
  final String title;
  final String fileName;

  const PdfPreviewScreen({
    Key? key,
    required this.pdf,
    required this.title,
    required this.fileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save to device',
            onPressed: () async {
              try {
                final file = await AttendancePdfService.savePdf(fileName, pdf);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved to ${file.path}')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to save file')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
            onPressed: () async {
              try {
                final file = await AttendancePdfService.savePdf(fileName, pdf);
                await Share.shareXFiles([XFile(file.path)], text: title);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to share file')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print document',
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (format) async => pdf.save(),
                name: fileName,
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdf.save(),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}