import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../document_viewer/presentation/document_viewer_screen.dart';
import 'package:mobile/core/providers/database_providers.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_radius.dart';
import '../../data/services/note_export_service.dart';
import '../../domain/models/drawing_stroke.dart';
import '../../domain/models/note.dart';
import '../../domain/models/note_block.dart';
import '../../domain/models/note_template.dart';
import '../widgets/drawing_canvas_widget.dart';
import '../widgets/note_template_painter.dart';

/// Full-screen Samsung Notes–inspired rich editor.
class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditorScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final Uuid _uuid = const Uuid();
  late String _noteId;
  late TextEditingController _titleController;
  late TextEditingController _textBodyController;

  String _category = 'General';
  String? _folderId;
  bool _isPinned = false;
  NoteTemplateType _templateType = NoteTemplateType.blank;
  List<NoteBlock> _checklistBlocks = [];
  List<DrawingStroke> _drawingStrokes = [];
  bool _showDrawingCanvas = false;
  DateTime _createdAt = DateTime.now();

  // Autosave & Debounce State
  Timer? _debounceTimer;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _isLoading = true;

  final List<String> _categories = [
    'General',
    'Personal',
    'Work',
    'Study',
    'Ideas',
  ];

  late final FocusNode _bodyFocusNode;

  @override
  void initState() {
    super.initState();
    _noteId = widget.noteId ?? _uuid.v4();
    _titleController = TextEditingController();
    _textBodyController = TextEditingController();
    _bodyFocusNode = FocusNode();

    _loadExistingNote();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _flushSave();
    _titleController.dispose();
    _textBodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadExistingNote() async {
    if (widget.noteId != null) {
      final repo = ref.read(notesRepositoryProvider);
      final existing = await repo.getNoteById(widget.noteId!);
      if (existing != null && mounted) {
        setState(() {
          _titleController.text = existing.title;
          _textBodyController.text = existing.body;
          _category = existing.category;
          _folderId = existing.folderId;
          _isPinned = existing.isPinned;
          _templateType = existing.templateType;
          _drawingStrokes = List.from(existing.drawingStrokes);
          _showDrawingCanvas = existing.hasDrawings;
          _checklistBlocks = existing.blocks
              .where((b) => b.type == NoteBlockType.checklist)
              .toList();
          _createdAt = existing.createdAt;
          _isLoading = false;
        });
        return;
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onContentChanged() {
    setState(() => _hasUnsavedChanges = true);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _saveNote();
    });
  }

  Note _buildCurrentNote() {
    // Combine text blocks + checklist blocks
    final blocks = <NoteBlock>[];
    if (_textBodyController.text.trim().isNotEmpty) {
      blocks.add(
        NoteBlock(
          id: 'text_body',
          type: NoteBlockType.richText,
          text: _textBodyController.text.trim(),
        ),
      );
    }
    blocks.addAll(_checklistBlocks);

    return Note(
      id: _noteId,
      title: _titleController.text.trim(),
      body: _textBodyController.text.trim(),
      category: _category,
      folderId: _folderId,
      isPinned: _isPinned,
      templateType: _templateType,
      blocks: blocks,
      drawingStrokes: _drawingStrokes,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveNote() async {
    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      final note = _buildCurrentNote();
      await ref.read(notesRepositoryProvider).saveNote(note);
      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasUnsavedChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _flushSave() async {
    if (_hasUnsavedChanges) {
      final note = _buildCurrentNote();
      await ref.read(notesRepositoryProvider).saveNote(note);
    }
  }

  void _addChecklistItem() {
    final newBlock = NoteBlock(
      id: _uuid.v4(),
      type: NoteBlockType.checklist,
      text: '',
      isChecked: false,
    );
    setState(() {
      _checklistBlocks.add(newBlock);
    });
    _onContentChanged();
  }

  void _removeChecklistItem(int index) {
    setState(() {
      _checklistBlocks.removeAt(index);
    });
    _onContentChanged();
  }

  void _toggleChecklistItem(int index) {
    setState(() {
      final item = _checklistBlocks[index];
      _checklistBlocks[index] = item.copyWith(isChecked: !item.isChecked);
    });
    _onContentChanged();
  }

  Future<void> _pickAttachment() async {
    try {
      final pickedFile = await FilePicker.pickFile(
        type: FileType.any,
      );

      if (pickedFile != null && pickedFile.path != null) {
        final originalFile = File(pickedFile.path!);
        final fileName = pickedFile.name;
        final fileSize = await originalFile.length();
        final ext = pickedFile.extension?.toLowerCase() ?? 'file';

        // Copy safely into private app documents storage
        final docsDir = await getApplicationDocumentsDirectory();
        final notesAttachmentDir = Directory('${docsDir.path}/notes_attachments/$_noteId');
        if (!await notesAttachmentDir.exists()) {
          await notesAttachmentDir.create(recursive: true);
        }

        final targetPath = '${notesAttachmentDir.path}/$fileName';
        await originalFile.copy(targetPath);

        // Ensure parent note record is persisted in SQLite
        await _saveNote();

        // Record in SQLite NoteAttachmentsTable
        await ref.read(notesRepositoryProvider).addAttachment(
              noteId: _noteId,
              fileName: fileName,
              filePath: targetPath,
              fileType: ext,
              fileSizeBytes: fileSize,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attached "$fileName" to note.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to attach file: $e'),
            backgroundColor: AppColors.errorCoral,
          ),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _insertTextAtCursor(String insertion) {
    final text = _textBodyController.text;
    final selection = _textBodyController.selection;
    int start = selection.start;
    int end = selection.end;

    if (start < 0 || end < 0) {
      start = text.length;
      end = text.length;
    }

    final newText = text.replaceRange(start, end, insertion);
    _textBodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + insertion.length),
    );
    _onContentChanged();
    _bodyFocusNode.requestFocus();
  }

  void _applyFormat(String prefix, String suffix) {
    final text = _textBodyController.text;
    final selection = _textBodyController.selection;
    final start = selection.start;
    final end = selection.end;

    if (start >= 0 && end > start) {
      final selectedText = text.substring(start, end);
      final replacement = '$prefix$selectedText$suffix';
      final newText = text.replaceRange(start, end, replacement);
      _textBodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: start + prefix.length,
          extentOffset: end + prefix.length,
        ),
      );
    } else {
      _insertTextAtCursor('$prefix$suffix');
    }
    _onContentChanged();
    _bodyFocusNode.requestFocus();
  }

  Future<void> _showAddLinkDialog() async {
    final urlController = TextEditingController();
    final titleController = TextEditingController();

    final selection = _textBodyController.selection;
    if (selection.isValid && selection.start < selection.end) {
      titleController.text = _textBodyController.text.substring(selection.start, selection.end);
    }

    final shouldInsert = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.link_rounded, color: AppColors.secondaryOcean),
              const SizedBox(width: 10),
              Text(
                'Attach Web Link',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Link URL *',
                  hintText: 'https://example.com',
                  prefixIcon: const Icon(Icons.language_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Link Title (Optional)',
                  hintText: 'e.g. Reference Documentation',
                  prefixIcon: const Icon(Icons.title_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_link_rounded, size: 18),
              label: const Text('Attach Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (urlController.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, true);
                }
              },
            ),
          ],
        );
      },
    );

    if (shouldInsert == true && mounted) {
      String rawUrl = urlController.text.trim();
      if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
        rawUrl = 'https://$rawUrl';
      }
      final displayTitle = titleController.text.trim().isNotEmpty
          ? titleController.text.trim()
          : rawUrl;

      await _saveNote();

      await ref.read(notesRepositoryProvider).addAttachment(
            noteId: _noteId,
            fileName: displayTitle,
            filePath: rawUrl,
            fileType: 'link',
            fileSizeBytes: 0,
          );

      _insertTextAtCursor('[$displayTitle]($rawUrl) ');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attached link: $displayTitle'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid link URL: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Photo / Image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryIndigo.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryIndigo),
              ),
              title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryOcean.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.secondaryOcean),
              ),
              title: const Text('Choose from Photo Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );

      if (pickedFile != null) {
        final originalFile = File(pickedFile.path);
        final fileName = pickedFile.name.isNotEmpty
            ? pickedFile.name
            : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final fileSize = await originalFile.length();
        final ext = fileName.split('.').last.toLowerCase();

        final docsDir = await getApplicationDocumentsDirectory();
        final notesAttachmentDir = Directory('${docsDir.path}/notes_attachments/$_noteId');
        if (!await notesAttachmentDir.exists()) {
          await notesAttachmentDir.create(recursive: true);
        }

        final targetPath = '${notesAttachmentDir.path}/$fileName';
        await originalFile.copy(targetPath);

        await _saveNote();

        await ref.read(notesRepositoryProvider).addAttachment(
              noteId: _noteId,
              fileName: fileName,
              filePath: targetPath,
              fileType: ext.isEmpty ? 'image' : ext,
              fileSizeBytes: fileSize,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attached photo "$fileName" to note.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to attach photo: $e'),
            backgroundColor: AppColors.errorCoral,
          ),
        );
      }
    }
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
              title: Text(fileName, style: const TextStyle(fontSize: 15, color: Colors.white)),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.open_in_full_rounded, color: Colors.white),
                  tooltip: 'Open in Document Viewer',
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push(
                      '/document-viewer',
                      extra: DocumentViewerArgs(
                        filePath: filePath,
                        fileName: fileName,
                        mimeType: 'image/jpeg',
                      ),
                    );
                  },
                ),
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
                maxScale: 5.0,
                child: Image.file(
                  File(filePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, _) => Center(
                    child: Text('Could not load image: $error', style: const TextStyle(color: Colors.white70)),
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

  void _showTemplatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Page Paper Template',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 16),
              ...NoteTemplateType.values.map((tmpl) {
                final isSel = _templateType == tmpl;
                return ListTile(
                  leading: Icon(
                    tmpl == NoteTemplateType.blank
                        ? Icons.crop_portrait_rounded
                        : tmpl == NoteTemplateType.lined
                            ? Icons.table_rows_rounded
                            : tmpl == NoteTemplateType.grid
                                ? Icons.grid_4x4_rounded
                                : Icons.grain_rounded,
                    color: isSel ? AppColors.primaryIndigo : Colors.grey,
                  ),
                  title: Text(
                    tmpl.label,
                    style: TextStyle(
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? AppColors.primaryIndigo : null,
                    ),
                  ),
                  trailing: isSel ? const Icon(Icons.check, color: AppColors.primaryIndigo) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  selected: isSel,
                  onTap: () {
                    setState(() => _templateType = tmpl);
                    _onContentChanged();
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showFolderPicker() {
    final foldersAsync = ref.read(noteFoldersStreamProvider);
    foldersAsync.whenData((folders) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move Note to Folder',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.folder_off_outlined),
                  title: const Text('No Folder (Root)'),
                  trailing: _folderId == null ? const Icon(Icons.check, color: AppColors.primaryIndigo) : null,
                  onTap: () {
                    setState(() => _folderId = null);
                    _onContentChanged();
                    Navigator.of(ctx).pop();
                  },
                ),
                ...folders.map((f) {
                  final isSel = _folderId == f.id;
                  return ListTile(
                    leading: Icon(Icons.folder_rounded, color: Color(int.parse(f.colorHex.replaceFirst('#', '0xFF')))),
                    title: Text(f.name),
                    trailing: isSel ? const Icon(Icons.check, color: AppColors.primaryIndigo) : null,
                    onTap: () {
                      setState(() => _folderId = f.id);
                      _onContentChanged();
                      Navigator.of(ctx).pop();
                    },
                  );
                }),
              ],
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attachmentsAsync = ref.watch(noteAttachmentsStreamProvider(_noteId));
    final foldersAsync = ref.watch(noteFoldersStreamProvider);

    String? currentFolderName;
    foldersAsync.whenData((folders) {
      final f = folders.where((item) => item.id == _folderId).firstOrNull;
      if (f != null) currentFolderName = f.name;
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () async {
            await _flushSave();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Folder chip button
            GestureDetector(
              onTap: _showFolderPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryIndigo.withValues(alpha: 0.12),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder_outlined, size: 14, color: AppColors.primaryIndigo),
                    const SizedBox(width: 4),
                    Text(
                      currentFolderName ?? 'No Folder',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryIndigo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Auto-save Status Indicator
            Text(
              _isSaving ? 'Saving...' : (_hasUnsavedChanges ? 'Unsaved' : 'Saved'),
              style: TextStyle(
                fontSize: 11,
                color: _isSaving ? AppColors.warningAmber : Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          // Pin / Unpin
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? AppColors.primaryIndigo : null,
              size: 20,
            ),
            tooltip: _isPinned ? 'Unpin Note' : 'Pin Note',
            onPressed: () {
              setState(() => _isPinned = !_isPinned);
              _onContentChanged();
            },
          ),
          // Paper Template Picker
          IconButton(
            icon: const Icon(Icons.style_outlined, size: 20),
            tooltip: 'Paper Style',
            onPressed: _showTemplatePicker,
          ),
          // Export PDF & Share
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            tooltip: 'Export PDF & Share',
            onPressed: () async {
              await _flushSave();
              final note = _buildCurrentNote();
              await NoteExportService.exportAndSharePdf(note);
            },
          ),
          // More Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) async {
              if (val == 'duplicate') {
                await _flushSave();
                final copy = await ref.read(notesRepositoryProvider).duplicateNote(_noteId);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  context.push('/notes/${copy.id}');
                }
              } else if (val == 'trash') {
                await ref.read(notesRepositoryProvider).moveToTrash(_noteId);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            itemBuilder: (ctx) => [
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
                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.errorCoral),
                    SizedBox(width: 10),
                    Text('Move to Trash', style: TextStyle(color: AppColors.errorCoral)),
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
          // 1. Paper Template Painter across full editor background
          CustomPaint(
            painter: NoteTemplatePainter(
              templateType: _templateType,
              isDark: isDark,
            ),
          ),
          // 2. Editor Content List (Tap anywhere to focus body editor and write)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_bodyFocusNode.hasFocus) {
                _bodyFocusNode.requestFocus();
              }
              _textBodyController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textBodyController.text.length),
              );
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 140,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Field
                        TextField(
                          controller: _titleController,
                          onChanged: (_) => _onContentChanged(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Note Title...',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Category Chips Selector
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((cat) {
                              final isSel = _category == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: isSel,
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() => _category = cat);
                                      _onContentChanged();
                                    }
                                  },
                                  selectedColor: AppColors.primaryIndigo.withValues(alpha: 0.2),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                    color: isSel ? AppColors.primaryIndigo : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const Divider(height: 24),

                        // Plain / Rich Text Body Editor (Click anywhere to focus & type)
                        TextField(
                          controller: _textBodyController,
                          focusNode: _bodyFocusNode,
                          onChanged: (_) => _onContentChanged(),
                          maxLines: null,
                          minLines: 8,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Start typing notes, insights, or thoughts... Tap anywhere to write.',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),

                // Interactive Checklist Section
                if (_checklistBlocks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Checklist',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._checklistBlocks.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleChecklistItem(idx),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: item.isChecked ? AppColors.successMint : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: item.isChecked ? AppColors.successMint : Colors.grey,
                                  width: 1.8,
                                ),
                              ),
                              child: item.isChecked
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.text,
                              onChanged: (val) {
                                _checklistBlocks[idx] = item.copyWith(text: val);
                                _onContentChanged();
                              },
                              style: TextStyle(
                                fontSize: 14,
                                decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                color: item.isChecked ? Colors.grey : null,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'List item...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                            onPressed: () => _removeChecklistItem(idx),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                // Vector Handwriting / Drawing Canvas
                if (_showDrawingCanvas) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Handwriting & Sketching',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.visibility_off_outlined, size: 16),
                        label: const Text('Hide Canvas', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          setState(() => _showDrawingCanvas = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DrawingCanvasWidget(
                    initialStrokes: _drawingStrokes,
                    templateType: _templateType,
                    onStrokesChanged: (strokes) {
                      _drawingStrokes = strokes;
                      _onContentChanged();
                    },
                  ),
                ],

                // Attachments & Web Links Section
                attachmentsAsync.when(
                  data: (attachments) {
                    if (attachments.isEmpty) return const SizedBox.shrink();

                    final imageExts = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'image'};
                    final images = attachments
                        .where((a) => imageExts.contains(a.fileType.toLowerCase()))
                        .toList();
                    final links = attachments
                        .where((a) => a.fileType == 'link')
                        .toList();
                    final docs = attachments
                        .where((a) =>
                            a.fileType != 'link' &&
                            !imageExts.contains(a.fileType.toLowerCase()))
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // 1. Photos & Images Gallery Strip
                        if (images.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.photo_library_rounded, size: 16, color: AppColors.primaryIndigo),
                              const SizedBox(width: 6),
                              Text(
                                'Photos & Images (${images.length})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 110,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 10),
                              itemBuilder: (ctx, idx) {
                                final img = images[idx];
                                return Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showImagePreviewDialog(img.filePath, img.fileName),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: 120,
                                          height: 110,
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white10 : Colors.black12,
                                            border: Border.all(
                                              color: isDark ? Colors.white24 : Colors.black12,
                                            ),
                                          ),
                                          child: Image.file(
                                            File(img.filePath),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => const Center(
                                              child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => ref
                                            .read(notesRepositoryProvider)
                                            .deleteAttachment(img.id),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 2. Documents & Files List
                        if (docs.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.insert_drive_file_rounded, size: 16, color: AppColors.primaryIndigo),
                              const SizedBox(width: 6),
                              Text(
                                'Attached Documents (${docs.length})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...docs.map((doc) {
                            final ext = doc.fileType.toLowerCase();
                            final isPdf = ext == 'pdf';
                            final isTxt = ext == 'txt';
                            final isWord = ext == 'doc' || ext == 'docx';
                            final isSheet = ext == 'xls' || ext == 'xlsx' || ext == 'csv';

                            final Color badgeColor = isPdf
                                ? AppColors.errorCoral
                                : isWord
                                    ? AppColors.primaryIndigo
                                    : isSheet
                                        ? AppColors.successMint
                                        : isTxt
                                            ? AppColors.warningAmber
                                            : Colors.blueGrey;

                            final IconData badgeIcon = isPdf
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
                                border: Border.all(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
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
                                  doc.fileName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  _formatBytes(doc.fileSizeBytes).isNotEmpty
                                      ? '${doc.fileType.toUpperCase()} • ${_formatBytes(doc.fileSizeBytes)}'
                                      : doc.fileType.toUpperCase(),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                      tooltip: 'Open',
                                      onPressed: () {
                                        if (isPdf || isTxt) {
                                          context.push(
                                            '/document-viewer',
                                            extra: DocumentViewerArgs(
                                              filePath: doc.filePath,
                                              fileName: doc.fileName,
                                              mimeType: isPdf ? 'application/pdf' : 'text/plain',
                                            ),
                                          );
                                        } else {
                                          OpenFilex.open(doc.filePath);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                                      tooltip: 'Delete',
                                      onPressed: () => ref
                                          .read(notesRepositoryProvider)
                                          .deleteAttachment(doc.id),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  if (isPdf || isTxt) {
                                    context.push(
                                      '/document-viewer',
                                      extra: DocumentViewerArgs(
                                        filePath: doc.filePath,
                                        fileName: doc.fileName,
                                        mimeType: isPdf ? 'application/pdf' : 'text/plain',
                                      ),
                                    );
                                  } else {
                                    OpenFilex.open(doc.filePath);
                                  }
                                },
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],

                        // 3. Web Links Section
                        if (links.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.link_rounded, size: 16, color: AppColors.secondaryOcean),
                              const SizedBox(width: 6),
                              Text(
                                'Web Links (${links.length})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: links.map((link) {
                              return InputChip(
                                avatar: const Icon(Icons.link_rounded, size: 16, color: AppColors.secondaryOcean),
                                label: Text(
                                  link.fileName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondaryOcean,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                tooltip: 'Tap to open: ${link.filePath}',
                                onPressed: () => _openLink(link.filePath),
                                deleteIcon: const Icon(Icons.close, size: 15),
                                onDeleted: () => ref
                                    .read(notesRepositoryProvider)
                                    .deleteAttachment(link.id),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                // Generous tap target to allow clicking anywhere on bottom of page
                const SizedBox(height: 120),
              ],
            ),
          ),
        );
      },
    ),
  ),
],
),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildToolbarAction(
                icon: Icons.check_box_outlined,
                label: 'Checklist',
                onTap: _addChecklistItem,
              ),
              const SizedBox(width: 6),
              _buildToolbarAction(
                icon: Icons.link_rounded,
                label: 'Link',
                color: AppColors.secondaryOcean,
                onTap: _showAddLinkDialog,
              ),
              const SizedBox(width: 6),
              _buildToolbarAction(
                icon: Icons.draw_rounded,
                label: 'Drawing',
                isActive: _showDrawingCanvas,
                onTap: () {
                  setState(() => _showDrawingCanvas = !_showDrawingCanvas);
                  _onContentChanged();
                },
              ),
              const SizedBox(width: 6),
              _buildToolbarAction(
                icon: Icons.image_outlined,
                label: 'Image',
                onTap: _pickImage,
              ),
              const SizedBox(width: 6),
              _buildToolbarAction(
                icon: Icons.attach_file_rounded,
                label: 'File',
                onTap: _pickAttachment,
              ),
              const SizedBox(width: 6),
              _buildToolbarAction(
                icon: Icons.format_list_bulleted_rounded,
                label: 'Bullet',
                onTap: () => _insertTextAtCursor('• '),
              ),
              const SizedBox(width: 6),
              _buildToolbarAction(
                icon: Icons.format_list_numbered_rounded,
                label: 'Numbered',
                onTap: () => _insertTextAtCursor('1. '),
              ),
              const SizedBox(width: 6),
              _buildToolbarAction(
                icon: Icons.title_rounded,
                label: 'Heading',
                onTap: () => _insertTextAtCursor('# '),
              ),
              const SizedBox(width: 6),
              _buildToolbarAction(
                icon: Icons.format_bold_rounded,
                label: 'Bold',
                onTap: () => _applyFormat('**', '**'),
              ),
              const SizedBox(width: 6),
              _buildToolbarAction(
                icon: Icons.style_outlined,
                label: 'Template',
                onTap: _showTemplatePicker,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    bool isActive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = color ?? AppColors.primaryIndigo;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive ? Border.all(color: activeColor.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? activeColor
                  : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? activeColor
                    : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
