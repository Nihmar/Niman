// The tree's per-file icon: a note looks like a document, an image like
// an image.
import 'package:copist/src/ui/file_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fileIconFor', () {
    test('notes are documents, images are images', () {
      expect(fileIconFor('note.md'), Icons.description_outlined);
      expect(fileIconFor('Shopping list.MD'), Icons.description_outlined);
      expect(fileIconFor('photo.png'), Icons.image_outlined);
      expect(fileIconFor('scan.JPG'), Icons.image_outlined);
      expect(fileIconFor('paper.pdf'), Icons.picture_as_pdf_outlined);
    });

    test('anything else is a plain file', () {
      expect(fileIconFor('data.xyz'), Icons.insert_drive_file_outlined);
      expect(fileIconFor('noextension'), Icons.insert_drive_file_outlined);
      expect(fileIconFor('.hidden'), Icons.insert_drive_file_outlined);
    });
  });
}
