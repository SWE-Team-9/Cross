import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/picked_image_file.dart';

void main() {
  group('PickedImageFile', () {
    test('formats byte, kilobyte, and megabyte sizes', () {
      expect(
        const PickedImageFile(
          name: 'tiny',
          extension: 'jpg',
          sizeInBytes: 512,
          path: '/tmp/tiny.jpg',
        ).formattedSize,
        '512 B',
      );
      expect(
        const PickedImageFile(
          name: 'medium',
          extension: 'png',
          sizeInBytes: 1536,
          path: '/tmp/medium.png',
        ).formattedSize,
        '1.5 KB',
      );
      expect(
        const PickedImageFile(
          name: 'large',
          extension: 'webp',
          sizeInBytes: 2 * 1024 * 1024,
          path: '/tmp/large.webp',
        ).formattedSize,
        '2.0 MB',
      );
    });

    test('uses value equality props', () {
      const first = PickedImageFile(
        name: 'cover',
        extension: 'jpg',
        sizeInBytes: 42,
        path: '/tmp/cover.jpg',
      );
      const second = PickedImageFile(
        name: 'cover',
        extension: 'jpg',
        sizeInBytes: 42,
        path: '/tmp/cover.jpg',
      );

      expect(first, second);
      expect(first.props, ['cover', 'jpg', 42, '/tmp/cover.jpg']);
    });
  });
}
