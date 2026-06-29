import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/camera_data.dart';
import '../../utils/camera_constants.dart';
import '../../utils/app_private_gallery_service.dart';
import 'employee_preview_screen.dart';
import '../../../../common/widgets/loading_widget.dart';

class CustomGalleryScreen extends StatefulWidget {
  final bool picAgain;
  const CustomGalleryScreen({super.key, this.picAgain = false});

  @override
  State<CustomGalleryScreen> createState() => _CustomGalleryScreenState();
}

class _CustomGalleryScreenState extends State<CustomGalleryScreen> {
  List<File> _files = [];
  final Set<int> _selectedIndices = {};
  bool _loading = true;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    if (mounted) setState(() => _loading = true);
    final files = await AppPrivateGalleryService.instance.getGalleryFiles();
    if (mounted) {
      setState(() {
        _files = files;
        _loading = false;
      });
    }
  }

  Future<void> _importFromPhone() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);

    try {
      final picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultipleMedia();

      if (pickedFiles.isNotEmpty) {
        // Show a progress indicator snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Importing media files...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        for (final xFile in pickedFiles) {
          await AppPrivateGalleryService.instance.saveToGallery(File(xFile.path));
        }

        // Reload the grid
        await _loadFiles();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported ${pickedFiles.length} item(s)'),
              backgroundColor: colorEmployeeGreen1,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error importing media: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to import media files'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _confirm() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(currentLat)?.toString() ?? '0';
    final lon = prefs.getDouble(currentLon)?.toString() ?? '0';
    final address = prefs.getString(currentAddress) ?? '';
    final country = prefs.getString(currentCountry) ?? '';
    final city = prefs.getString(currentCity) ?? '';
    final state = prefs.getString(currentState) ?? '';
    final now = DateFormat("HH:mm, dd MMM yyyy").format(DateTime.now());

    final List<CameraData> result = [];
    for (final idx in _selectedIndices) {
      if (idx >= _files.length) continue;
      final file = _files[idx];
      final mimeStr = lookupMimeType(file.path) ?? '';
      String mimeType = 'image';
      String videoThumbnailPath = '';

      if (mimeStr.startsWith('video/')) {
        mimeType = 'video';
        // Retrieve the generated video thumbnail path
        videoThumbnailPath = await AppPrivateGalleryService.instance
                .getOrGenerateThumbnail(file) ??
            '';
      } else if (mimeStr.startsWith('audio/')) {
        mimeType = 'audio';
      }

      result.add(
        CameraData(
          path: file.path,
          mimeType: mimeType,
          videoImagePath: videoThumbnailPath,
          latitude: lat,
          longitude: lon,
          dateTime: now,
          location: address,
          country: country,
          city: city,
          state: state,
          fromGallary: true,
        ),
      );
    }

    if (!mounted) return;
    if (result.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.picAgain) {
      Navigator.pop(context, result);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmployeePreviewScreen(
            cameraData: null,
            pickAgain: widget.picAgain,
            type: 'camera',
            cameraListData: result,
            mediaList: const [],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Gallery',
          style: TextStyle(
            color: Colors.white,
            fontSize: size.width * numD045,
            fontWeight: FontWeight.w600,
            fontFamily: 'AirbnbCereal',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
            tooltip: 'Import from Phone',
            onPressed: _isImporting ? null : _importFromPhone,
          ),
          if (_selectedIndices.isNotEmpty)
            TextButton(
              onPressed: _confirm,
              child: Text(
                'Done (${_selectedIndices.length})',
                style: const TextStyle(
                  color: colorEmployeeGreen1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const LoadingWidget()
          : _files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white38,
                        size: size.width * numD22,
                      ),
                      SizedBox(height: size.width * numD04),
                      Text(
                        'No media found',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: size.width * numD045,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                      SizedBox(height: size.width * numD02),
                      Text(
                        'Import photos/videos or capture new ones',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: size.width * numD035,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                      SizedBox(height: size.width * numD06),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorEmployeeGreen1,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * numD06,
                            vertical: size.width * numD03,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(size.width * numD02),
                          ),
                        ),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text(
                          'Import from Phone',
                          style: TextStyle(
                            fontFamily: 'AirbnbCereal',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _isImporting ? null : _importFromPhone,
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(2),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final isSelected = _selectedIndices.contains(index);
                    final isVid = file.path.toLowerCase().endsWith('.mp4') ||
                        file.path.toLowerCase().endsWith('.mov') ||
                        file.path.toLowerCase().endsWith('.3gp') ||
                        file.path.toLowerCase().endsWith('.avi');

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIndices.remove(index);
                          } else {
                            if (_selectedIndices.length < 10) {
                              _selectedIndices.add(index);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('You can select up to 10 items'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        });
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (isVid)
                            FutureBuilder<String?>(
                              future: AppPrivateGalleryService.instance
                                  .getOrGenerateThumbnail(file),
                              builder: (context, snap) {
                                if (snap.hasData && snap.data != null) {
                                  return Image.file(File(snap.data!),
                                      fit: BoxFit.cover);
                                }
                                return Container(
                                  color: Colors.grey[900],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white30),
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            Image.file(file, fit: BoxFit.cover),
                          if (isVid)
                            const Positioned(
                              right: 4,
                              bottom: 4,
                              child: Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          if (isSelected)
                            Container(
                              color: colorEmployeeGreen1.withOpacity(0.4),
                              child: const Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// Small helper class to use p.extension
class p {
  static String extension(String path) {
    return path.substring(path.lastIndexOf('.'));
  }
}
