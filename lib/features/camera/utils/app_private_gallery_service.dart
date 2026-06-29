import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

class AppPrivateGalleryService {
  static final AppPrivateGalleryService instance = AppPrivateGalleryService._internal();
  AppPrivateGalleryService._internal();

  static const String _galleryFolderName = 'presshop_gallery';
  static const String _thumbnailFolderName = '.thumbnails';

  Future<Directory> get _galleryDir async {
    final docDir = await getApplicationDocumentsDirectory();
    final gallery = Directory(p.join(docDir.path, _galleryFolderName));
    if (!await gallery.exists()) {
      await gallery.create(recursive: true);
    }
    return gallery;
  }

  Future<Directory> get _thumbnailDir async {
    final gallery = await _galleryDir;
    final thumb = Directory(p.join(gallery.path, _thumbnailFolderName));
    if (!await thumb.exists()) {
      await thumb.create(recursive: true);
    }
    return thumb;
  }

  /// Copies a captured/imported media file into the app's persistent gallery.
  /// If it is a video, it automatically pre-generates a thumbnail.
  Future<File> saveToGallery(File sourceFile) async {
    final gallery = await _galleryDir;
    final extension = p.extension(sourceFile.path);
    final fileName = 'PS_${DateTime.now().millisecondsSinceEpoch}$extension';
    final targetFile = File(p.join(gallery.path, fileName));
    
    // Copy the file
    final copiedFile = await sourceFile.copy(targetFile.path);
    
    // Pre-generate thumbnail for videos
    if (_isVideo(copiedFile.path)) {
      await getOrGenerateThumbnail(copiedFile);
    }
    
    return copiedFile;
  }

  /// Returns a list of local files in the gallery, sorted by creation date (newest first).
  Future<List<File>> getGalleryFiles() async {
    try {
      final gallery = await _galleryDir;
      final entities = await gallery.list().toList();
      final List<File> files = [];

      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.webp' ||
              ext == '.mp4' || ext == '.mov' || ext == '.3gp' || ext == '.avi') {
            files.add(entity);
          }
        }
      }

      // Sort files by last modified date (newest first)
      files.sort((a, b) {
        final aTime = a.lastModifiedSync();
        final bTime = b.lastModifiedSync();
        return bTime.compareTo(aTime);
      });

      return files;
    } catch (e) {
      debugPrint('Error listing local gallery files: $e');
      return [];
    }
  }

  /// Retrieves or pre-generates a thumbnail for a video.
  Future<String?> getOrGenerateThumbnail(File videoFile) async {
    try {
      final thumbDir = await _thumbnailDir;
      final videoName = p.basenameWithoutExtension(videoFile.path);
      final thumbPath = p.join(thumbDir.path, '$videoName.png');
      final thumbFile = File(thumbPath);

      if (await thumbFile.exists()) {
        return thumbPath;
      }

      // Generate thumbnail
      final generated = await vt.VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: thumbDir.path,
        imageFormat: vt.ImageFormat.PNG,
        maxWidth: 256,
        quality: 50,
      );

      if (generated != null) {
        final generatedFile = File(generated);
        // Rename generated file to match our naming structure
        final renamedFile = await generatedFile.rename(thumbPath);
        return renamedFile.path;
      }
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
    }
    return null;
  }

  bool _isVideo(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.mp4' || ext == '.mov' || ext == '.3gp' || ext == '.avi';
  }
}
