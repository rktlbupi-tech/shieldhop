import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:presshop_enterprise/common/widgets/app_app_bar.dart';
import '../../domain/entities/document_entity.dart';

class DocumentPreviewScreen extends StatelessWidget {
  final DocumentEntity document;

  const DocumentPreviewScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final String docName = document.name;
    final bool isPdf = docName.toLowerCase().endsWith('.pdf');
    final String? fileUrl = document.fileUrl;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(
        elevation: 0,
        titleSpacing: 0,
        showBack: true,
        titleWidget: Text(
          docName,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'AirbnbCereal',
            fontSize: size.width * 0.045,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(
                  LucideIcons.share_2,
                  color: Colors.black87,
                  size: size.width * 0.055,
                ),
                onPressed: () {
                  final box = context.findRenderObject() as RenderBox?;
                  // ignore: deprecated_member_use
                  Share.share(
                    'Check out this document: $docName\n${fileUrl ?? "https://dummy.link/$docName"}',
                    sharePositionOrigin: box != null
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null,
                  );
                },
              );
            },
          ),
          SizedBox(width: size.width * 0.02),
        ],
      ),
      body: Container(
        color: const Color(0xFFF8F9FA),
        width: double.infinity,
        height: double.infinity,
        child: _buildPreviewWidget(isPdf, fileUrl),
      ),
    );
  }

  Widget _buildPreviewWidget(bool isPdf, String? fileUrl) {
    final hasLocal =
        fileUrl != null &&
        !fileUrl.startsWith('http') &&
        !fileUrl.startsWith('https');

    if (isPdf) {
      if (hasLocal) {
        return SfPdfViewer.file(File(fileUrl));
      } else {
        return SfPdfViewer.network(
          fileUrl ??
              'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        );
      }
    } else {
      if (hasLocal) {
        return Image.file(File(fileUrl), fit: BoxFit.contain);
      } else {
        return Image.network(
          fileUrl ?? 'https://via.placeholder.com/600x800?text=Preview+Image',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                'Unable to load preview',
                style: TextStyle(fontFamily: 'AirbnbCereal'),
              ),
            );
          },
        );
      }
    }
  }
}
