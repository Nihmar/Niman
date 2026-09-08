import 'package:flutter/material.dart';

/// The tree icon for a file, chosen by its extension.
///
/// A note is a document, an image is an image: the icon says what the row
/// opens as, which is the one thing the name does not always make
/// obvious at a glance.
IconData fileIconFor(String name) {
  final dot = name.lastIndexOf('.');
  final extension = dot <= 0 ? '' : name.substring(dot + 1).toLowerCase();
  return switch (extension) {
    'md' || 'markdown' || 'txt' || 'text' => Icons.description_outlined,
    'png' ||
    'jpg' ||
    'jpeg' ||
    'gif' ||
    'webp' ||
    'bmp' ||
    'svg' ||
    'heic' ||
    'avif' => Icons.image_outlined,
    'pdf' => Icons.picture_as_pdf_outlined,
    'mp3' || 'wav' || 'm4a' || 'ogg' || 'flac' => Icons.audiotrack_outlined,
    'mp4' || 'mov' || 'mkv' || 'webm' || 'avi' => Icons.movie_outlined,
    'zip' || 'gz' || 'tar' || '7z' || 'rar' => Icons.folder_zip_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}
