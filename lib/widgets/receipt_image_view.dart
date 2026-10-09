import 'dart:io';

import 'package:flutter/material.dart';

/// Receipt photo on the Review screen (FR-4.1). Tapping it opens a full
/// screen viewer with pinch-to-zoom (`InteractiveViewer`).
class ReceiptImageView extends StatelessWidget {
  const ReceiptImageView({super.key, required this.path, this.height = 200});

  final String path;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ảnh hóa đơn, chạm để phóng to',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openViewer(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const _Unavailable(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openViewer(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 6,
              child: Center(
                child: Image.file(
                  File(path),
                  errorBuilder: (context, error, stackTrace) =>
                      const _Unavailable(),
                ),
              ),
            ),
          ),
          SafeArea(
            child: IconButton.filledTonal(
              tooltip: 'Đóng',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image_outlined, size: 40),
        SizedBox(height: 4),
        Text('Không mở được ảnh'),
      ],
    ),
  );
}
