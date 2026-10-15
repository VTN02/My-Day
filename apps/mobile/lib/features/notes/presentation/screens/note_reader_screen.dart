import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile/core/providers/database_providers.dart';
import 'package:mobile/core/services/document_launcher_service.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_radius.dart';
import '../../data/services/note_export_service.dart';
import '../../domain/models/drawing_stroke.dart';
import '../../domain/models/note.dart';
import '../../domain/models/note_block.dart';
import '../widgets/drawing_canvas_widget.dart';
import '../widgets/note_template_painter.dart';

/// Professional Reading Mode screen for MyDay Notes.
/// Presents a finished document page without soft keyboards or form input boxes.
/// Supports rich typography, checklists, resizable images, vector drawings,
/// and document attachments.
class NoteReaderScreen extends ConsumerStatefulWidget {
  final String noteId;

  const NoteReaderScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteReaderScreen> createState() => _NoteReaderScreenState();
}

class _NoteReaderScreenState extends ConsumerState<NoteReaderScreen> {
  Note? _note;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    try {
      final repo = ref.read(notesRepositoryProvider);
      final note = await repo.getNoteById(widget.noteId);
      if (mounted) {
        setState(() {
          _note = note;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleChecklist(int blockIndex) async {
    if (_note == null) return;
    final updatedBlocks = List<NoteBlock>.from(_note!.blocks);
    final block = updatedBlocks[blockIndex];
    updatedBlocks[blockIndex] = block.copyWith(isChecked: !block.isChecked);

    final updatedNote = _note!.copyWith(
      blocks: updatedBlocks,
      updatedAt: DateTime.now(),
    );

    setState(() => _note = updatedNote);
    await ref.read(notesRepositoryProvider).saveNote(updatedNote);
  }

  void _showImagePreviewDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                fileName,
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  tooltip: 'Share',
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(filePath, name: fileName)],
                      text: fileName,
                    ),
                  ),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  File(filePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, _) => const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      size: 48,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_note == null || _errorMessage != null) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(title: const Text('Note')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.note_alt_outlined, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Note not found or has been removed.',
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Notes'),
              ),
            ],
          ),
        ),
      );
    }

    final note = _note!;
    final dateFormat = DateFormat('MMMM d, y • h:mm a');
    final formattedDate = dateFormat.format(note.updatedAt);
    final attachmentsAsync = ref.watch(noteAttachmentsStreamProvider(note.id));
    final foldersAsync = ref.watch(noteFoldersStreamProvider);

    String? folderName;
    foldersAsync.whenData((folders) {
      final f = folders.where((item) => item.id == note.folderId).firstOrNull;
      if (f != null) folderName = f.name;
    });

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title.isNotEmpty ? note.title : 'Untitled Note',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (folderName != null)
              Text(
                folderName!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryIndigo,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          // Prominent Edit Action Button (Switches to Edit Mode)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text(
                'Edit',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryIndigo,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                // Navigate to Edit Mode
                await context.push('/notes/${note.id}/edit');
                // Reload on return to catch changes
                _loadNote();
              },
            ),
          ),
          const SizedBox(width: 4),
          // Share / Export PDF
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            tooltip: 'Share Note',
            onPressed: () async {
              await NoteExportService.exportAndSharePdf(note);
            },
          ),
          // More Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) async {
              if (val == 'pin') {
                await ref
                    .read(notesRepositoryProvider)
                    .togglePin(note.id, !note.isPinned);
                _loadNote();
              } else if (val == 'duplicate') {
                final copy = await ref
                    .read(notesRepositoryProvider)
                    .duplicateNote(note.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  context.push('/notes/${copy.id}');
                }
              } else if (val == 'trash') {
                await ref.read(notesRepositoryProvider).moveToTrash(note.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'pin',
                child: Row(
                  children: [
                    Icon(
                      note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(note.isPinned ? 'Unpin Note' : 'Pin Note'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Duplicate Note'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'trash',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.errorCoral,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Move to Trash',
                      style: TextStyle(color: AppColors.errorCoral),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Paper Template Painter across full document canvas
          CustomPaint(
            painter: NoteTemplatePainter(
              templateType: note.templateType,
              isDark: isDark,
            ),
          ),
          // 2. Continuous Document Page Layout
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Note Title
                SelectableText(
                  note.title.isNotEmpty ? note.title : 'Untitled Note',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.25,
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 10),

                // Category pill & Last Updated
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryIndigo.withValues(alpha: 0.12),
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        note.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryIndigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),

                // Render Content Blocks
                if (note.blocks.isEmpty && note.body.isNotEmpty) ...[
                  // Legacy note fallback
                  SelectableText(
                    note.body,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                ] else ...[
                  ..._buildDocumentBlocks(note.blocks, isDark),
                ],

                // Vector Drawings & Handwriting
                if (note.hasDrawings) ...[
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Icon(
                        Icons.draw_rounded,
                        size: 16,
                        color: AppColors.primaryIndigo,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Handwritten Notes & Sketches',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 420,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D1527)
                          : const Color(0xFFFBFDFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: NoteTemplatePainter(
                            templateType: note.templateType,
                            isDark: isDark,
                          ),
                        ),
                        CustomPaint(
                          painter: StrokesPainter(
                            strokes: note.drawingStrokes,
                            inProgressPoints: const [],
                            inProgressTool: StrokeTool.pen,
                            inProgressColor: '#1565C0',
                            inProgressWidth: 3.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Document Attachments Section
                attachmentsAsync.when(
                  data: (attachments) {
                    if (attachments.isEmpty) return const SizedBox.shrink();

                    final imageExts = {
                      'jpg',
                      'jpeg',
                      'png',
                      'webp',
                      'gif',
                      'image',
                    };
                    final docs = attachments
                        .where(
                          (a) =>
                              a.fileType != 'link' &&
                              !imageExts.contains(a.fileType.toLowerCase()),
                        )
                        .toList();

                    if (docs.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            const Icon(
                              Icons.attach_file_rounded,
                              size: 16,
                              color: AppColors.primaryIndigo,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Attached Files (${docs.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...docs.map((doc) => _buildAttachmentCard(doc, isDark)),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDocumentBlocks(List<NoteBlock> blocks, bool isDark) {
    final widgets = <Widget>[];

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];

      switch (block.type) {
        case NoteBlockType.heading1:
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 6),
              child: SelectableText(
                block.text,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
            ),
          );
          break;

        case NoteBlockType.heading2:
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: SelectableText(
                block.text,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
            ),
          );
          break;

        case NoteBlockType.heading3:
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: SelectableText(
                block.text,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
            ),
          );
          break;

        case NoteBlockType.bullet:
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: SelectableText(
                      block.text,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          break;

        case NoteBlockType.numbered:
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      block.text,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          break;

        case NoteBlockType.checklist:
          final idx = i;
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleChecklist(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: block.isChecked
                            ? AppColors.successMint
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: block.isChecked
                              ? AppColors.successMint
                              : Colors.grey,
                          width: 1.8,
                        ),
                      ),
                      child: block.isChecked
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      block.text,
                      style: TextStyle(
                        fontSize: 15,
                        decoration: block.isChecked
                            ? TextDecoration.lineThrough
                            : null,
                        color: block.isChecked
                            ? Colors.grey
                            : (isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          break;

        case NoteBlockType.image:
          final imgMeta = ImageBlockMeta.tryDecode(block.meta);
          final filePath = imgMeta?.filePath ?? block.text;
          final widthFactor = imgMeta?.widthPercent ?? 1.0;
          final alignmentStr = imgMeta?.alignment ?? 'center';

          Alignment geomAlignment = Alignment.center;
          if (alignmentStr == 'left') geomAlignment = Alignment.centerLeft;
          if (alignmentStr == 'right') geomAlignment = Alignment.centerRight;

          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Align(
                alignment: geomAlignment,
                child: FractionallySizedBox(
                  widthFactor: widthFactor.clamp(0.25, 1.0),
                  child: GestureDetector(
                    onTap: () => _showImagePreviewDialog(filePath, block.text),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.file(
                          File(filePath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, error, _) => Container(
                            height: 120,
                            color: Colors.grey.withValues(alpha: 0.1),
                            child: const Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                size: 36,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          break;

        case NoteBlockType.textBox:
          final boxMeta = TextBoxMeta.tryDecode(block.meta);
          if (boxMeta != null) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: boxMeta.backgroundColorHex != null
                        ? Color(
                            int.parse(
                              boxMeta.backgroundColorHex!.replaceFirst(
                                '#',
                                '0xFF',
                              ),
                            ),
                          )
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: SelectableText(
                    block.text,
                    style: TextStyle(
                      fontSize: boxMeta.fontSize,
                      fontWeight: boxMeta.isBold
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontStyle: boxMeta.isItalic
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: boxMeta.colorHex != null
                          ? Color(
                              int.parse(
                                boxMeta.colorHex!.replaceFirst('#', '0xFF'),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }
          break;

        case NoteBlockType.divider:
          widgets.add(const Divider(height: 24, thickness: 1));
          break;

        case NoteBlockType.richText:
        default:
          if (block.text.trim().isNotEmpty) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SelectableText(
                  block.text,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                  ),
                ),
              ),
            );
          }
          break;
      }
    }

    return widgets;
  }

  Widget _buildAttachmentCard(dynamic doc, bool isDark) {
    final fileName = doc.fileName as String;
    final filePath = doc.filePath as String;
    final fileType = (doc.fileType as String).toLowerCase();
    final fileSizeBytes = doc.fileSizeBytes as int? ?? 0;

    final isPdf = fileType == 'pdf' || fileName.toLowerCase().endsWith('.pdf');
    final isWord =
        fileType == 'doc' ||
        fileType == 'docx' ||
        fileName.toLowerCase().endsWith('.docx');
    final isTxt = fileType == 'txt' || fileName.toLowerCase().endsWith('.txt');
    final isSheet =
        fileType == 'xls' ||
        fileType == 'xlsx' ||
        fileName.toLowerCase().endsWith('.xlsx');

    final badgeColor = isPdf
        ? AppColors.errorCoral
        : isWord
        ? AppColors.primaryIndigo
        : isSheet
        ? AppColors.successMint
        : isTxt
        ? AppColors.warningAmber
        : Colors.blueGrey;

    final badgeIcon = isPdf
        ? Icons.picture_as_pdf_rounded
        : isWord
        ? Icons.description_rounded
        : isSheet
        ? Icons.table_chart_rounded
        : isTxt
        ? Icons.text_snippet_rounded
        : Icons.insert_drive_file_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(badgeIcon, color: badgeColor, size: 22),
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatBytes(fileSizeBytes).isNotEmpty
              ? '${fileType.toUpperCase()} • ${_formatBytes(fileSizeBytes)}'
              : fileType.toUpperCase(),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          tooltip: 'Open Document',
          onPressed: () {
            DocumentLauncherService.openDocument(
              context: context,
              filePath: filePath,
              fileName: fileName,
              fileType: fileType,
            );
          },
        ),
        onTap: () {
          DocumentLauncherService.openDocument(
            context: context,
            filePath: filePath,
            fileName: fileName,
            fileType: fileType,
          );
        },
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
