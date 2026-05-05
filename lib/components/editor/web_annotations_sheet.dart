import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:saber/data/file_manager/file_manager.dart';

final _log = Logger('WebAnnotationsSheet');

class WebAnnotationsSheet extends StatefulWidget {
  const WebAnnotationsSheet({super.key, required this.filePath});

  final String filePath;

  @override
  State<WebAnnotationsSheet> createState() => _WebAnnotationsSheetState();
}

class _WebAnnotationsSheetState extends State<WebAnnotationsSheet> {
  bool _loading = true;
  String? _text;
  List<_AnnotationImage> _images = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnnotations();
  }

  Future<void> _loadAnnotations() async {
    try {
      // Load Quill delta from .quill.json
      final quillBytes = await FileManager.readFile(
        '${widget.filePath}.sbn2.quill.json',
      );
      if (quillBytes != null) {
        final json = jsonDecode(utf8.decode(quillBytes)) as List<dynamic>;
        // Extract plain text from Quill delta ops
        final buffer = StringBuffer();
        for (final op in json) {
          final insert = op['insert'];
          if (insert is String) buffer.write(insert);
        }
        _text = buffer.toString().trim();
      }

      // Load images from .web.json
      final webBytes = await FileManager.readFile(
        '${widget.filePath}.sbn2.web.json',
      );
      if (webBytes != null) {
        final json = jsonDecode(utf8.decode(webBytes)) as Map<String, dynamic>;
        final images = json['images'] as List<dynamic>? ?? [];
        _images = images.map((img) {
          return _AnnotationImage(
            id: img['id'] as String,
            dataUrl: img['dataUrl'] as String,
            caption: img['caption'] as String? ?? '',
          );
        }).toList();
      }
    } catch (e, st) {
      _log.warning('_loadAnnotations failed: $e', e, st);
      _error = 'Could not load annotations';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Web Annotations',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(_error!, style: TextStyle(color: colorScheme.error))
          else if ((_text == null || _text!.isEmpty) && _images.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No annotations yet.\nAdd notes from the web app.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text section
                    if (_text != null && _text!.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            'NOTES',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _text!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Text copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy'),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: SelectableText(
                          _text!,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Images section
                    if (_images.isNotEmpty) ...[
                      Text(
                        'SCREENSHOTS & IMAGES',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._images.map((img) => _ImageTile(image: img)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnnotationImage {
  final String id;
  final String dataUrl;
  final String caption;
  const _AnnotationImage({
    required this.id,
    required this.dataUrl,
    required this.caption,
  });
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.image});
  final _AnnotationImage image;

  @override
  Widget build(BuildContext context) {
    // Decode base64 data URL
    final base64Data = image.dataUrl.contains(',')
        ? image.dataUrl.split(',').last
        : image.dataUrl;

    late final Uint8List bytes;
    try {
      bytes = base64Decode(base64Data);
    } catch (e) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
          if (image.caption.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                image.caption,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
