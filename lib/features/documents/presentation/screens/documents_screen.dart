import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../config/di/injection.dart';
import '../../../../common/widgets/loading_widget.dart';
import '../../../../features/camera/utils/upload_progress_notifier.dart';
import '../../../../features/map/core/map_constants.dart';
import '../../../../common/widgets/app_app_bar.dart';
import '../../../../features/mileage/presentation/widgets/custom_dropdown.dart';

import 'package:go_router/go_router.dart';
import '../../../../config/routes/app_router.dart';
import '../bloc/documents_bloc.dart';
import '../../domain/entities/document_entity.dart';

const double numD036 = 0.036;
const double numD028 = 0.028;

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DocumentsBloc>()..add(const FetchDocuments()),
      child: const _DocumentsView(),
    );
  }
}

class _DocumentsView extends StatefulWidget {
  const _DocumentsView();

  @override
  State<_DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<_DocumentsView> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _selectedSort = 'Recent';
  List<DocumentEntity>? _documents;

  List<DocumentEntity> get _sortedDocuments {
    final list = List<DocumentEntity>.from(_documents ?? []);
    if (_selectedSort == 'Recent') {
      return list;
    } else if (_selectedSort == 'Name A-Z') {
      list.sort((a, b) => a.name.compareTo(b.name));
    } else if (_selectedSort == 'Size') {
      list.sort((a, b) {
        final valA = _parseSizeValue(a.size);
        final valB = _parseSizeValue(b.size);
        return valB.compareTo(valA);
      });
    }
    return list;
  }

  int _parseSizeValue(String? sizeStr) {
    if (sizeStr == null || sizeStr.isEmpty) return 0;
    final clean = sizeStr.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    final value = double.tryParse(clean) ?? 0.0;
    if (sizeStr.toUpperCase().contains('MB')) {
      return (value * 1000000).toInt();
    } else if (sizeStr.toUpperCase().contains('KB')) {
      return (value * 1000).toInt();
    }
    return value.toInt();
  }

  IconData _getIcon(DocumentEntity doc) {
    final name = doc.name.toLowerCase();
    final cat = doc.category.toLowerCase();
    if (cat.contains('contract')) return LucideIcons.file_text;
    if (cat.contains('certificate')) return LucideIcons.award;
    if (cat.contains('id_proof')) {
      if (name.endsWith('.pdf')) return LucideIcons.file_x;
      return LucideIcons.image;
    }
    if (name.endsWith('.pdf')) return LucideIcons.file_text;
    return LucideIcons.image;
  }

  Color _getIconColor(DocumentEntity doc) {
    final name = doc.name.toLowerCase();
    final cat = doc.category.toLowerCase();
    if (cat.contains('contract')) return const Color(0xFF2563EB);
    if (cat.contains('certificate')) return const Color(0xFFEA580C);
    if (cat.contains('id_proof')) {
      if (name.endsWith('.pdf')) return const Color.fromARGB(255, 255, 16, 16);
      return const Color(0xFF0D9488);
    }
    if (name.endsWith('.pdf')) return const Color(0xFF2563EB);
    return const Color(0xFF0D9488);
  }

  Color _getIconBg(DocumentEntity doc) {
    final name = doc.name.toLowerCase();
    final cat = doc.category.toLowerCase();
    if (cat.contains('contract')) return const Color(0xFFEFF6FF);
    if (cat.contains('certificate')) return const Color(0xFFFFF7ED);
    if (cat.contains('id_proof')) {
      if (name.endsWith('.pdf')) {
        return const Color.fromARGB(255, 255, 241, 241);
      }
      return const Color(0xFFE6FFFA);
    }
    if (name.endsWith('.pdf')) return const Color(0xFFEFF6FF);
    return const Color(0xFFE6FFFA);
  }

  // Real upload: file → media flow → POST /app/documents, via the bloc.
  // The result is handled in the BlocConsumer listener.
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'AirbnbCereal')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Pick an image (camera/gallery) and upload. Handles cancel + errors.
  Future<void> _pickImageAndUpload(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      debugPrint('[Docs] picked image: ${image?.path}');
      if (image == null) {
        _toast('No file selected');
        return;
      }
      _uploadDocument(File(image.path), 'id_proofs');
    } catch (e) {
      debugPrint('[Docs] image pick error: $e');
      _toast('Could not open the picker. Check permissions.');
    }
  }

  // Pick a PDF and upload. Handles cancel + errors.
  Future<void> _pickPdfAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      final path = result?.files.single.path;
      debugPrint('[Docs] picked pdf: $path');
      if (path == null || path.isEmpty) {
        _toast('No file selected');
        return;
      }
      _uploadDocument(File(path), 'contracts');
    } catch (e) {
      debugPrint('[Docs] pdf pick error: $e');
      _toast('Could not open the file picker.');
    }
  }

  void _uploadDocument(File file, String category) {
    Navigator.pop(context); // Close bottom sheet
    final fileName = file.path.split('/').last;
    debugPrint('[Docs] uploading "$fileName" ($category) from ${file.path}');
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    UploadProgressNotifier.instance.startUpload(
      taskId: 'doc_upload',
      title: fileName,
      progressTitle: 'Uploading document',
    );

    context.read<DocumentsBloc>().add(
          UploadDocument(file: file, name: fileName, category: category),
        );

    _animateUploadProgress();
  }

  // Cosmetic progress while the real upload runs (a single POST gives no % ).
  void _animateUploadProgress() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted || !_isUploading) return false;
      setState(() {
        _uploadProgress = (_uploadProgress + 0.08).clamp(0.0, 0.9);
      });
      UploadProgressNotifier.instance.updateProgress(_uploadProgress);
      return _isUploading && _uploadProgress < 0.9;
    });
  }

  void _showUploadBottomSheet() {
    final size = MediaQuery.of(context).size;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Upload New Document",
                style: TextStyle(
                  fontFamily: "AirbnbCereal",
                  fontSize: size.width * 0.045,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickImageAndUpload(ImageSource.camera),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          border: Border.all(
                            color: const Color(0xFF93C5FD),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/icons/ic_camera1.png",
                              width: 26,
                              height: 26,
                              color: const Color(0xFF2563EB),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Camera",
                              style: TextStyle(
                                fontFamily: "AirbnbCereal",
                                fontSize: size.width * 0.035,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickImageAndUpload(ImageSource.gallery),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(
                            color: const Color(0xFF86EFAC),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/icons/ic_gallary.png",
                              width: 24,
                              height: 26,
                              color: const Color(0xFF16A34A),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Gallery",
                              style: TextStyle(
                                fontFamily: "AirbnbCereal",
                                fontSize: size.width * 0.035,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF14532D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickPdfAndUpload,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    border: Border.all(
                      color: const Color(0xFFFCA5A5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/icons/ic_form_icon1.svg",
                        width: 26,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFDC2626),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Upload PDF Document",
                        style: TextStyle(
                          fontFamily: "AirbnbCereal",
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7F1D1D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDocumentActions(DocumentEntity doc) {
    final bloc = context.read<DocumentsBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  doc.name,
                  style: const TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(LucideIcons.eye, color: Colors.blue),
                  title: const Text(
                    "View Document",
                    style: TextStyle(fontFamily: 'AirbnbCereal'),
                  ),
                  onTap: () {
                    context.push(AppRoutes.documentPreview, extra: doc);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    LucideIcons.download,
                    color: Colors.green,
                  ),
                  title: const Text(
                    "Download",
                    style: TextStyle(fontFamily: 'AirbnbCereal'),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Downloading ${doc.name}..."),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.trash_2, color: Colors.red),
                  title: const Text(
                    "Delete Document",
                    style: TextStyle(fontFamily: 'AirbnbCereal'),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    bloc.add(DeleteDocument(doc.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${doc.name} deleted."),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppAppBar(
        title: "My documents",
        elevation: 0.5,
        centerTitle: false,
        titleSpacing: 0,
        showBack: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            BlocConsumer<DocumentsBloc, DocumentsState>(
              listener: (context, state) {
                if (state is DocumentUploadSuccess) {
                  setState(() {
                    _documents = state.documents;
                    _isUploading = false;
                  });
                  UploadProgressNotifier.instance.completeUpload(
                    title: 'Upload complete',
                    body: '${state.document.name} uploaded successfully!',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${state.document.name} uploaded successfully!',
                        style: const TextStyle(fontFamily: 'AirbnbCereal'),
                      ),
                      backgroundColor: colorEmployeeGreen1,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (state is DocumentActionFailure) {
                  setState(() {
                    _documents = state.documents;
                    _isUploading = false;
                  });
                  UploadProgressNotifier.instance.failUpload();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (state is DocumentsLoaded) {
                  setState(() => _documents = state.documents);
                }
              },
              builder: (context, state) {
                if (state is DocumentsLoading && _documents == null) {
                  return const LoadingWidget();
                }

                final docsList = _documents ?? const <DocumentEntity>[];

                return RefreshIndicator(
                  color: colorEmployeeGreen1,
                  onRefresh: () async {
                    context.read<DocumentsBloc>().add(const FetchDocuments());
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * numD04,
                      vertical: size.width * numD03,
                    ),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Text(
                        "All your important documents in one place",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontFamily: 'AirbnbCereal',
                          fontSize: size.width * numD03,
                        ),
                      ),
                      SizedBox(height: size.width * numD04),

                      GestureDetector(
                        onTap: _showUploadBottomSheet,
                        child: CustomPaint(
                          painter: DashedBorderPainter(
                            color: const Color(0xFFBFDBFE),
                            strokeWidth: 1.5,
                            borderRadius: size.width * numD04,
                          ),
                          child: Container(
                            padding: EdgeInsets.all(size.width * numD04),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                size.width * numD04,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: size.width * 0.12,
                                  height: size.width * 0.12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(
                                      size.width * numD03,
                                    ),
                                  ),
                                  child: Icon(
                                    LucideIcons.plus,
                                    color: const Color(0xFF2563EB),
                                    size: size.width * numD06,
                                  ),
                                ),
                                SizedBox(width: size.width * numD04),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Upload New Document",
                                        style: TextStyle(
                                          color: const Color(0xFF2563EB),
                                          fontSize: size.width * numD036,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: "AirbnbCereal",
                                        ),
                                      ),
                                      SizedBox(height: size.width * numD005),
                                      Text(
                                        "Add and store your documents securely",
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: size.width * numD028,
                                          fontFamily: "AirbnbCereal",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: const Color(0xFF2563EB),
                                  size: size.width * numD05,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: size.width * numD05),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Your Uploaded Documents",
                            style: TextStyle(
                              fontSize: size.width * numD04,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: "AirbnbCereal",
                            ),
                          ),
                          CustomDropdown<String>(
                            value: _selectedSort,
                            items: const ['Recent', 'Name A-Z', 'Size'],
                            buttonWidth: size.width * 0.28,
                            buttonColor: Colors.white,
                            itemBuilder: (value, isSelected) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.sliders_horizontal,
                                    size: size.width * numD03,
                                    color: isSelected
                                        ? Colors.black87
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    value,
                                    style: TextStyle(
                                      fontFamily: 'AirbnbCereal',
                                      fontSize: size.width * numD028,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.black87
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              );
                            },
                            onChanged: (String newValue) {
                              setState(() {
                                _selectedSort = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: size.width * numD03),

                      if (docsList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Center(
                            child: Text(
                              "No documents found",
                              style: TextStyle(
                                fontFamily: "AirbnbCereal",
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._sortedDocuments.map((doc) {
                          final statusStr =
                              doc.status == 'pending' ? 'Pending' : 'Submitted';
                          return InkWell(
                            onTap: () {
                              context.push(
                                AppRoutes.documentPreview,
                                extra: doc,
                              );
                            },
                            borderRadius: BorderRadius.circular(
                              size.width * numD04,
                            ),
                            child: Container(
                              margin: EdgeInsets.only(
                                bottom: size.width * numD03,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  size.width * numD04,
                                ),
                                border: Border.all(
                                  color: const Color(0xFFEFF1F6),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.015,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(size.width * numD035),
                              child: Row(
                                children: [
                                  Container(
                                    width: size.width * 0.12,
                                    height: size.width * 0.12,
                                    decoration: BoxDecoration(
                                      color: _getIconBg(doc),
                                      borderRadius: BorderRadius.circular(
                                        size.width * numD03,
                                      ),
                                    ),
                                    child: Icon(
                                      _getIcon(doc),
                                      color: _getIconColor(doc),
                                      size: size.width * numD05,
                                    ),
                                  ),
                                  SizedBox(width: size.width * numD035),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc.name,
                                          style: TextStyle(
                                            fontSize: size.width * numD035,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            fontFamily: "AirbnbCereal",
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: size.width * numD01),
                                        Text(
                                          "${doc.categoryLabel}  •  ${(doc.size ?? '').isEmpty ? 'Unknown' : doc.size}  •  ${doc.uploadedAt != null ? DateFormat('dd MMM yyyy').format(doc.uploadedAt!) : 'Unknown'}",
                                          style: TextStyle(
                                            fontSize: size.width * numD028,
                                            color: Colors.grey.shade500,
                                            fontFamily: "AirbnbCereal",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: size.width * numD02),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: size.width * numD02,
                                          vertical: size.width * numD008,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusStr == "Pending"
                                              ? Colors.red.shade100
                                              : const Color(0xFFE6F9F2),
                                          borderRadius: BorderRadius.circular(
                                            size.width * numD02,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              statusStr == "Pending"
                                                  ? Icons.close
                                                  : Icons.check_circle,
                                              color: statusStr == "Pending"
                                                  ? Colors.red
                                                  : const Color(0xFF10B981),
                                              size: size.width * numD03,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              statusStr,
                                              style: TextStyle(
                                                fontSize: size.width * numD022,
                                                fontWeight: FontWeight.bold,
                                                color: statusStr == "Pending"
                                                    ? Colors.red
                                                    : const Color(0xFF10B981),
                                                fontFamily: "AirbnbCereal",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: Colors.grey.shade400,
                                          size: size.width * numD05,
                                        ),
                                        onPressed: () =>
                                            _showDocumentActions(doc),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      SizedBox(height: size.width * numD04),

                      Container(
                        padding: EdgeInsets.all(size.width * numD035),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(
                            size.width * numD03,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(size.width * numD02),
                              decoration: const BoxDecoration(
                                color: Color(0xFFBFDBFE),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.lock,
                                color: const Color(0xFF1E40AF),
                                size: size.width * numD045,
                              ),
                            ),
                            SizedBox(width: size.width * numD03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Your security is our priority",
                                    style: TextStyle(
                                      fontFamily: 'AirbnbCereal',
                                      fontSize: size.width * numD03,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E40AF),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "All documents are encrypted and stored securely",
                                    style: TextStyle(
                                      fontFamily: 'AirbnbCereal',
                                      fontSize: size.width * numD026,
                                      color: const Color(
                                        0xFF1E40AF,
                                      ).withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: size.width * numD05),
                    ],
                  ),
                );
              },
            ),

            if (_isUploading)
              Container(
                color: Colors.black26,
                child: Center(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: _uploadProgress,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              colorEmployeeGreen1,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "Uploading document... ${(100 * _uploadProgress).toInt()}%",
                            style: const TextStyle(
                              fontFamily: 'AirbnbCereal',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 4.0,
    this.dashGap = 4.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashGap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
