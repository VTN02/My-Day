import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile/core/providers/database_providers.dart';
import 'package:mobile/core/services/document_launcher_service.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_radius.dart';
import '../../domain/models/drawing_stroke.dart';
import '../../domain/models/note.dart';
import '../../domain/models/note_block.dart';
import '../../domain/models/note_template.dart';
import '../widgets/drawing_canvas_widget.dart';
import '../widgets/note_template_painter.dart';

/// Professional Document Editor Screen for MyDay Notes.
/// Features a continuous Word-style document page surface, rich text blocks,
/// resizable images, free-positioned text boxes, expandable handwriting canvas,
/// and a Done action that flushes autosave and returns to Reading Mode.
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

  String _category = 'General';
  String? _folderId;
  bool _isPinned = false;
  NoteTemplateType _templateType = NoteTemplateType.blank;
  List<NoteBlock> _documentBlocks = [];
  List<DrawingStroke> _drawingStrokes = [];
  bool _showDrawingCanvas = false;
  DateTime _createdAt = DateTime.now();

  // Autosave & Debounce State
  Timer? _debounceTimer;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _isLoading = true;

  // Selected Block & Formatting State
  String? _selectedBlockId;
  String? _selectedImageBlockId;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  final List<String> _categories = [
    'General',
    'Personal',
    'Work',
    'Study',
    'Ideas',
  ];

  final Map<String, TextEditingController> _blockControllers = {};
  final Map<String, FocusNode> _blockFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _noteId = widget.noteId ?? _uuid.v4();
    _titleController = TextEditingController();
    _loadExistingNote();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    for (final c in _blockControllers.values) {
      c.dispose();
    }
    for (final f in _blockFocusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  TextEditingController _getControllerForBlock(NoteBlock block) {
    if (!_blockControllers.containsKey(block.id)) {
      final ctrl = TextEditingController(text: block.text);
      ctrl.addListener(() {
        final idx = _documentBlocks.indexWhere((b) => b.id == block.id);
        if (idx != -1 && _documentBlocks[idx].text != ctrl.text) {
          _documentBlocks[idx] = _documentBlocks[idx].copyWith(text: ctrl.text);
          _onContentChanged();
        }
      });
      _blockControllers[block.id] = ctrl;
    }
    return _blockControllers[block.id]!;
  }

  FocusNode _getFocusNodeForBlock(String blockId) {
    if (!_blockFocusNodes.containsKey(blockId)) {
      _blockFocusNodes[blockId] = FocusNode();
    }
    return _blockFocusNodes[blockId]!;
  }

  Future<void> _loadExistingNote() async {
    if (widget.noteId != null) {
      final repo = ref.read(notesRepositoryProvider);
      final existing = await repo.getNoteById(widget.noteId!);
      if (existing != null && mounted) {
        setState(() {
          _titleController.text = existing.title;
          _category = existing.category;
          _folderId = existing.folderId;
          _isPinned = existing.isPinned;
          _templateType = existing.templateType;
          _drawingStrokes = List.from(existing.drawingStrokes);
          _showDrawingCanvas = existing.hasDrawings;
          _createdAt = existing.createdAt;

          if (existing.blocks.isNotEmpty) {
            _documentBlocks = List.from(existing.blocks);
          } else if (existing.body.isNotEmpty) {
            // Upgrade legacy note body to initial paragraph block
            _documentBlocks = [
              NoteBlock(
                id: _uuid.v4(),
                type: NoteBlockType.richText,
                text: existing.body,
              ),
            ];
          } else {
            _documentBlocks = [
              NoteBlock(id: _uuid.v4(), type: NoteBlockType.richText, text: ''),
            ];
          }

          _isLoading = false;
        });
        return;
      }
    }

    // New note
    if (mounted) {
      setState(() {
        _documentBlocks = [
          NoteBlock(id: _uuid.v4(), type: NoteBlockType.richText, text: ''),
        ];
        _isLoading = false;
      });
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
    // Generate text summary for note list preview
    final textSummary = _documentBlocks
        .where((b) => b.text.trim().isNotEmpty)
        .map((b) => b.text.trim())
        .take(3)
        .join(' • ');

    return Note(
      id: _noteId,
      title: _titleController.text.trim(),
      body: textSummary,
      category: _category,
      folderId: _folderId,
      isPinned: _isPinned,
      templateType: _templateType,
      blocks: _documentBlocks,
      drawingStrokes: _drawingStrokes,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<bool> _saveNote() async {
    if (!mounted) return true;
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
      return true;
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note: $e'),
            backgroundColor: AppColors.errorCoral,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _handleDone() async {
    _debounceTimer?.cancel();
    final success = await _saveNote();
    if (!success) return;

    if (mounted) {
      FocusScope.of(context).unfocus();
      // Navigate back to Reading Mode
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/notes/$_noteId');
      }
    }
  }

  // --- Block Operations ---

  void _insertParagraphAt(
    int index, {
    NoteBlockType type = NoteBlockType.richText,
    String text = '',
  }) {
    final newBlock = NoteBlock(id: _uuid.v4(), type: type, text: text);
    setState(() {
      if (index >= 0 && index <= _documentBlocks.length) {
        _documentBlocks.insert(index, newBlock);
      } else {
        _documentBlocks.add(newBlock);
      }
      _selectedBlockId = newBlock.id;
    });
    _onContentChanged();

    // Focus newly added block
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getFocusNodeForBlock(newBlock.id).requestFocus();
    });
  }

  void _convertActiveBlockType(NoteBlockType newType) {
    if (_selectedBlockId == null) {
      _insertParagraphAt(_documentBlocks.length, type: newType);
      return;
    }

    final idx = _documentBlocks.indexWhere((b) => b.id == _selectedBlockId);
    if (idx != -1) {
      setState(() {
        _documentBlocks[idx] = _documentBlocks[idx].copyWith(type: newType);
      });
      _onContentChanged();
    }
  }

  void _removeBlock(String blockId) {
    setState(() {
      _documentBlocks.removeWhere((b) => b.id == blockId);
      _blockControllers.remove(blockId)?.dispose();
      _blockFocusNodes.remove(blockId)?.dispose();
      if (_documentBlocks.isEmpty) {
        _insertParagraphAt(0);
      }
    });
    _onContentChanged();
  }

  // --- Image Insertion & Resizing ---

  Future<void> _pickAndInsertImage({required ImageSource source}) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );

      if (pickedFile == null) return;

      final originalFile = File(pickedFile.path);
      final fileName = pickedFile.name.isNotEmpty
          ? pickedFile.name
          : 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileSize = await originalFile.length();
      final ext = fileName.split('.').last.toLowerCase();

      final docsDir = await getApplicationDocumentsDirectory();
      final notesAttachmentDir = Directory(
        '${docsDir.path}/notes_attachments/$_noteId',
      );
      if (!await notesAttachmentDir.exists()) {
        await notesAttachmentDir.create(recursive: true);
      }

      final targetPath = '${notesAttachmentDir.path}/$fileName';
      await originalFile.copy(targetPath);

      // Save attachment in database
      await ref
          .read(notesRepositoryProvider)
          .addAttachment(
            noteId: _noteId,
            fileName: fileName,
            filePath: targetPath,
            fileType: ext.isEmpty ? 'image' : ext,
            fileSizeBytes: fileSize,
          );

      // Create inline image block with metadata
      final imgMeta = ImageBlockMeta(
        filePath: targetPath,
        widthPercent: 1.0,
        alignment: 'center',
        caption: fileName,
      );

      final imgBlock = NoteBlock(
        id: _uuid.v4(),
        type: NoteBlockType.image,
        text: fileName,
        meta: imgMeta.encode(),
      );

      setState(() {
        _documentBlocks.add(imgBlock);
        _selectedImageBlockId = imgBlock.id;
      });
      _onContentChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Inserted image "$fileName". Tap to resize or align.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to insert image: $e'),
            backgroundColor: AppColors.errorCoral,
          ),
        );
      }
    }
  }

  void _updateImageSize(String blockId, double newWidthPercent) {
    final idx = _documentBlocks.indexWhere((b) => b.id == blockId);
    if (idx != -1) {
      final block = _documentBlocks[idx];
      final currentMeta =
          ImageBlockMeta.tryDecode(block.meta) ??
          ImageBlockMeta(filePath: block.text);
      final updatedMeta = ImageBlockMeta(
        filePath: currentMeta.filePath,
        widthPercent: newWidthPercent.clamp(0.25, 1.0),
        alignment: currentMeta.alignment,
        aspectRatio: currentMeta.aspectRatio,
        caption: currentMeta.caption,
      );
      setState(() {
        _documentBlocks[idx] = block.copyWith(meta: updatedMeta.encode());
      });
      _onContentChanged();
    }
  }

  void _updateImageAlignment(String blockId, String alignment) {
    final idx = _documentBlocks.indexWhere((b) => b.id == blockId);
    if (idx != -1) {
      final block = _documentBlocks[idx];
      final currentMeta =
          ImageBlockMeta.tryDecode(block.meta) ??
          ImageBlockMeta(filePath: block.text);
      final updatedMeta = ImageBlockMeta(
        filePath: currentMeta.filePath,
        widthPercent: currentMeta.widthPercent,
        alignment: alignment,
        aspectRatio: currentMeta.aspectRatio,
        caption: currentMeta.caption,
      );
      setState(() {
        _documentBlocks[idx] = block.copyWith(meta: updatedMeta.encode());
      });
      _onContentChanged();
    }
  }

  // --- Free-Positioned Text Boxes ---

  void _insertTextBox() {
    final meta = TextBoxMeta(
      x: 0.1,
      y: 120.0,
      width: 220.0,
      height: 90.0,
      fontSize: 15.0,
      fontFamily: 'Inter',
    );
    final block = NoteBlock(
      id: _uuid.v4(),
      type: NoteBlockType.textBox,
      text: 'Type anywhere in this text box...',
      meta: meta.encode(),
    );
    setState(() {
      _documentBlocks.add(block);
      _selectedBlockId = block.id;
    });
    _onContentChanged();
  }

  // --- Attachments ---

  Future<void> _pickAttachment() async {
    try {
      final pickedFile = await FilePicker.pickFile(type: FileType.any);
      if (pickedFile != null && pickedFile.path != null) {
        final originalFile = File(pickedFile.path!);
        final fileName = pickedFile.name;
        final fileSize = await originalFile.length();
        final ext = pickedFile.extension?.toLowerCase() ?? 'file';

        final docsDir = await getApplicationDocumentsDirectory();
        final notesAttachmentDir = Directory(
          '${docsDir.path}/notes_attachments/$_noteId',
        );
        if (!await notesAttachmentDir.exists()) {
          await notesAttachmentDir.create(recursive: true);
        }

        final targetPath = '${notesAttachmentDir.path}/$fileName';
        await originalFile.copy(targetPath);

        await _saveNote();

        await ref
            .read(notesRepositoryProvider)
            .addAttachment(
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

  void _showInsertMenu() {
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insert Content',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildInsertMenuItem(
                    icon: Icons.text_fields_rounded,
                    label: 'Paragraph',
                    onTap: () {
                      Navigator.pop(ctx);
                      _insertParagraphAt(
                        _documentBlocks.length,
                        type: NoteBlockType.richText,
                      );
                    },
                  ),
                  _buildInsertMenuItem(
                    icon: Icons.title_rounded,
                    label: 'Heading 1',
                    onTap: () {
                      Navigator.pop(ctx);
                      _insertParagraphAt(
                        _documentBlocks.length,
                        type: NoteBlockType.heading1,
                      );
                    },
                  ),
                  _buildInsertMenuItem(
                    icon: Icons.format_size_rounded,
                    label: 'Heading 2',
                    onTap: () {
                      Navigator.pop(ctx);
                      _insertParagraphAt(
                        _documentBlocks.length,
                        type: NoteBlockType.heading2,
                      );
                    },
                  ),
                  _buildInsertMenuItem(
                    icon: Icons.check_box_outlined,
                    label: 'Checklist',
                    onTap: () {
                      Navigator.pop(ctx);
                      _insertParagraphAt(
                        _documentBlocks.length,
                        type: NoteBlockType.checklist,
                      );
                    },
                  ),
                  _buildInsertMenuItem(
                    icon: Icons.format_list_bulleted_rounded,
                    label: 'Bullet List',
                    onTap: () {
                      Navigator.pop(ctx);
                      _insertParagraphAt(
                        _documentBlocks.length,
                        type: NoteBlockType.bullet,
                      );
                    },
                  ),
                  _buildInsertMenuItem(
                    icon: Icons.format_list_numbered_rounded,
                    label: 'Numbered List',
                    onTap: () {
                      Navigator.pop(ctx);
                      _insertParagraphAt(
                        _documentBlocks.length,
                        type: NoteBlockType.numbered,
                      );
                    },
                  ),
                  _buildInsertMenuItem(
                    icon: Icons.photo_library_rounded,
                    label: 'Photo Gallery',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndInsertImage(source: ImageSource.gallery);
                    },
                  ),
                  _buildInsertMenuItem(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera Photo',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndInsertImage(source: ImageSource.camera);
                    },
                  ),
                  _buildInsertMenuItem(
                    icon: Icons.open_with_rounded,
                    label: 'Text Box',
                    onTap: () {
                      Navigator.pop(ctx);
                      _insertTextBox();
                    },
                  ),
                  _buildInsertMenuItem(
                    icon: Icons.draw_rounded,
                    label: 'Drawing',
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _showDrawingCanvas = true);
                      _onContentChanged();
                    },
                  ),
                  _buildInsertMenuItem(
                    icon: Icons.horizontal_rule_rounded,
                    label: 'Divider',
                    onTap: () {
                      Navigator.pop(ctx);
                      _insertParagraphAt(
                        _documentBlocks.length,
                        type: NoteBlockType.divider,
                      );
                    },
                  ),
                  _buildInsertMenuItem(
                    icon: Icons.attach_file_rounded,
                    label: 'Attachment',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAttachment();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsertMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryIndigo.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: AppColors.primaryIndigo),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _handleDone,
        ),
        title: Row(
          children: [
            // Folder chip button
            GestureDetector(
              onTap: _showFolderPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryIndigo.withValues(alpha: 0.12),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.folder_outlined,
                      size: 14,
                      color: AppColors.primaryIndigo,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currentFolderName ?? 'No Folder',
                      style: const TextStyle(
                        fontSize: 11,
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
              _isSaving
                  ? 'Saving...'
                  : (_hasUnsavedChanges ? 'Unsaved' : 'Saved'),
              style: TextStyle(
                fontSize: 11,
                color: _isSaving ? AppColors.warningAmber : Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          // Explicit Done Action Button (Flushes autosave, persists, and returns to Reading Mode)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text(
                'Done',
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
              onPressed: _handleDone,
            ),
          ),
          const SizedBox(width: 4),
          // More Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) async {
              if (val == 'template') {
                _showTemplatePicker();
              } else if (val == 'trash') {
                await ref.read(notesRepositoryProvider).moveToTrash(_noteId);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'template',
                child: Row(
                  children: [
                    Icon(Icons.style_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Paper Style'),
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
          // 1. Paper Template Painter across full editor background
          CustomPaint(
            painter: NoteTemplatePainter(
              templateType: _templateType,
              isDark: isDark,
            ),
          ),
          // 2. Continuous Document Page Surface (No rectangular form border)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // Tap below all content appends or focuses the last paragraph block
              if (_documentBlocks.isNotEmpty &&
                  _documentBlocks.last.type.isTextual) {
                _getFocusNodeForBlock(_documentBlocks.last.id).requestFocus();
              } else {
                _insertParagraphAt(_documentBlocks.length);
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document Note Title (Natural title without form border)
                  TextField(
                    controller: _titleController,
                    onChanged: (_) => _onContentChanged(),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Note Title...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 10),

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
                            selectedColor: AppColors.primaryIndigo.withValues(
                              alpha: 0.2,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSel ? AppColors.primaryIndigo : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 24),

                  // Render Document Blocks (Headings, Paragraphs, Images, Lists, Text Boxes)
                  ..._buildEditableBlocks(isDark),

                  // Vector Handwriting & Drawing Canvas
                  if (_showDrawingCanvas) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Handwriting & Drawing Studio',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text(
                            'Hide Canvas',
                            style: TextStyle(fontSize: 11),
                          ),
                          onPressed: () {
                            setState(() => _showDrawingCanvas = false);
                            _onContentChanged();
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
                          const SizedBox(height: 24),
                          Text(
                            'Attached Documents (${docs.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...docs.map(
                            (doc) => _buildAttachmentTile(doc, isDark),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),

                  // Generous bottom whitespace for typing
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomToolbar(isDark),
    );
  }

  List<Widget> _buildEditableBlocks(bool isDark) {
    final widgets = <Widget>[];

    for (int i = 0; i < _documentBlocks.length; i++) {
      final block = _documentBlocks[i];

      switch (block.type) {
        case NoteBlockType.heading1:
          widgets.add(
            _buildHeadingField(block, i, 22, FontWeight.w800, isDark),
          );
          break;
        case NoteBlockType.heading2:
          widgets.add(
            _buildHeadingField(block, i, 19, FontWeight.w700, isDark),
          );
          break;
        case NoteBlockType.heading3:
          widgets.add(
            _buildHeadingField(block, i, 17, FontWeight.w600, isDark),
          );
          break;
        case NoteBlockType.checklist:
          widgets.add(_buildChecklistField(block, i, isDark));
          break;
        case NoteBlockType.bullet:
          widgets.add(_buildBulletField(block, i, isDark));
          break;
        case NoteBlockType.numbered:
          widgets.add(_buildNumberedField(block, i, isDark));
          break;
        case NoteBlockType.image:
          widgets.add(_buildResizableImageBlock(block, i, isDark));
          break;
        case NoteBlockType.textBox:
          widgets.add(_buildTextBoxBlock(block, i, isDark));
          break;
        case NoteBlockType.divider:
          widgets.add(_buildDividerBlock(block, i, isDark));
          break;
        case NoteBlockType.richText:
        default:
          widgets.add(_buildParagraphField(block, i, isDark));
          break;
      }
    }

    return widgets;
  }

  Widget _buildParagraphField(NoteBlock block, int index, bool isDark) {
    final ctrl = _getControllerForBlock(block);
    final focus = _getFocusNodeForBlock(block.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: ctrl,
        focusNode: focus,
        maxLines: null,
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
          decoration: _isUnderline ? TextDecoration.underline : null,
          color: isDark
              ? AppColors.darkPrimaryText
              : AppColors.lightPrimaryText,
        ),
        decoration: InputDecoration(
          hintText: index == 0 ? 'Start typing your document...' : '',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onTap: () => setState(() => _selectedBlockId = block.id),
      ),
    );
  }

  Widget _buildHeadingField(
    NoteBlock block,
    int index,
    double size,
    FontWeight weight,
    bool isDark,
  ) {
    final ctrl = _getControllerForBlock(block);
    final focus = _getFocusNodeForBlock(block.id);

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: TextField(
        controller: ctrl,
        focusNode: focus,
        maxLines: null,
        style: TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: isDark
              ? AppColors.darkPrimaryText
              : AppColors.lightPrimaryText,
        ),
        decoration: InputDecoration(
          hintText: 'Heading...',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onTap: () => setState(() => _selectedBlockId = block.id),
      ),
    );
  }

  Widget _buildChecklistField(NoteBlock block, int index, bool isDark) {
    final ctrl = _getControllerForBlock(block);
    final focus = _getFocusNodeForBlock(block.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _documentBlocks[index] = block.copyWith(
                  isChecked: !block.isChecked,
                );
              });
              _onContentChanged();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: block.isChecked
                    ? AppColors.successMint
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: block.isChecked ? AppColors.successMint : Colors.grey,
                  width: 1.8,
                ),
              ),
              child: block.isChecked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              focusNode: focus,
              style: TextStyle(
                fontSize: 15,
                decoration: block.isChecked ? TextDecoration.lineThrough : null,
                color: block.isChecked
                    ? Colors.grey
                    : (isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText),
              ),
              decoration: const InputDecoration(
                hintText: 'Checklist item...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => setState(() => _selectedBlockId = block.id),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
            visualDensity: VisualDensity.compact,
            onPressed: () => _removeBlock(block.id),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletField(NoteBlock block, int index, bool isDark) {
    final ctrl = _getControllerForBlock(block);
    final focus = _getFocusNodeForBlock(block.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              focusNode: focus,
              maxLines: null,
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
              decoration: const InputDecoration(
                hintText: 'List item...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => setState(() => _selectedBlockId = block.id),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
            visualDensity: VisualDensity.compact,
            onPressed: () => _removeBlock(block.id),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedField(NoteBlock block, int index, bool isDark) {
    final ctrl = _getControllerForBlock(block);
    final focus = _getFocusNodeForBlock(block.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              focusNode: focus,
              maxLines: null,
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
              decoration: const InputDecoration(
                hintText: 'Numbered item...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => setState(() => _selectedBlockId = block.id),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
            visualDensity: VisualDensity.compact,
            onPressed: () => _removeBlock(block.id),
          ),
        ],
      ),
    );
  }

  Widget _buildResizableImageBlock(NoteBlock block, int index, bool isDark) {
    final isSelected = _selectedImageBlockId == block.id;
    final imgMeta =
        ImageBlockMeta.tryDecode(block.meta) ??
        ImageBlockMeta(filePath: block.text);
    final widthFactor = imgMeta.widthPercent;
    final alignmentStr = imgMeta.alignment;

    Alignment geomAlignment = Alignment.center;
    if (alignmentStr == 'left') geomAlignment = Alignment.centerLeft;
    if (alignmentStr == 'right') geomAlignment = Alignment.centerRight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: geomAlignment,
            child: FractionallySizedBox(
              widthFactor: widthFactor.clamp(0.25, 1.0),
              child: GestureDetector(
                onTap: () => setState(
                  () => _selectedImageBlockId = isSelected ? null : block.id,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryIndigo
                          : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(imgMeta.filePath),
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
                      // Resize handle indicator on bottom-right when selected
                      if (isSelected)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              final screenWidth =
                                  MediaQuery.of(context).size.width - 40;
                              final newWidth =
                                  (screenWidth * widthFactor) +
                                  details.delta.dx;
                              final newFactor = (newWidth / screenWidth).clamp(
                                0.25,
                                1.0,
                              );
                              _updateImageSize(block.id, newFactor);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryIndigo,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.aspect_ratio_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Contextual Image Resizing Toolbar (Active when image tapped)
          if (isSelected) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryIndigo.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Presets: 25%, 50%, 75%, 100%
                  _buildSizePresetButton(
                    '25%',
                    () => _updateImageSize(block.id, 0.25),
                    widthFactor == 0.25,
                  ),
                  _buildSizePresetButton(
                    '50%',
                    () => _updateImageSize(block.id, 0.50),
                    widthFactor == 0.50,
                  ),
                  _buildSizePresetButton(
                    '75%',
                    () => _updateImageSize(block.id, 0.75),
                    widthFactor == 0.75,
                  ),
                  _buildSizePresetButton(
                    'Full',
                    () => _updateImageSize(block.id, 1.0),
                    widthFactor == 1.0,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 18,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 8),
                  // Alignment: Left, Center, Right
                  IconButton(
                    icon: const Icon(Icons.format_align_left_rounded, size: 16),
                    onPressed: () => _updateImageAlignment(block.id, 'left'),
                    color: alignmentStr == 'left'
                        ? AppColors.primaryIndigo
                        : Colors.grey,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.format_align_center_rounded,
                      size: 16,
                    ),
                    onPressed: () => _updateImageAlignment(block.id, 'center'),
                    color: alignmentStr == 'center'
                        ? AppColors.primaryIndigo
                        : Colors.grey,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.format_align_right_rounded,
                      size: 16,
                    ),
                    onPressed: () => _updateImageAlignment(block.id, 'right'),
                    color: alignmentStr == 'right'
                        ? AppColors.primaryIndigo
                        : Colors.grey,
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.errorCoral,
                    ),
                    onPressed: () => _removeBlock(block.id),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSizePresetButton(
    String label,
    VoidCallback onTap,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryIndigo : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTextBoxBlock(NoteBlock block, int index, bool isDark) {
    final ctrl = _getControllerForBlock(block);
    final focus = _getFocusNodeForBlock(block.id);
    final boxMeta = TextBoxMeta.tryDecode(block.meta) ?? const TextBoxMeta();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        width: boxMeta.width,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryIndigo.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.open_with_rounded,
                      size: 12,
                      color: AppColors.primaryIndigo,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Text Box',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primaryIndigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _removeBlock(block.id),
                ),
              ],
            ),
            TextField(
              controller: ctrl,
              focusNode: focus,
              maxLines: null,
              style: TextStyle(
                fontSize: boxMeta.fontSize,
                fontWeight: boxMeta.isBold
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontStyle: boxMeta.isItalic
                    ? FontStyle.italic
                    : FontStyle.normal,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
              decoration: const InputDecoration(
                hintText: 'Type inside text box...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => setState(() => _selectedBlockId = block.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerBlock(NoteBlock block, int index, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 1)),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
            visualDensity: VisualDensity.compact,
            onPressed: () => _removeBlock(block.id),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(dynamic doc, bool isDark) {
    final fileName = doc.fileName as String;
    final filePath = doc.filePath as String;
    final fileType = (doc.fileType as String).toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(
          Icons.insert_drive_file_rounded,
          color: AppColors.primaryIndigo,
          size: 20,
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          fileType.toUpperCase(),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              tooltip: 'Open',
              onPressed: () => DocumentLauncherService.openDocument(
                context: context,
                filePath: filePath,
                fileName: fileName,
                fileType: fileType,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: Colors.grey,
              ),
              tooltip: 'Remove',
              onPressed: () =>
                  ref.read(notesRepositoryProvider).deleteAttachment(doc.id),
            ),
          ],
        ),
        onTap: () => DocumentLauncherService.openDocument(
          context: context,
          filePath: filePath,
          fileName: fileName,
          fileType: fileType,
        ),
      ),
    );
  }

  Widget _buildBottomToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
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
            // Insert Menu (+)
            IconButton.filled(
              icon: const Icon(Icons.add_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryIndigo,
                foregroundColor: Colors.white,
              ),
              tooltip: 'Insert Content',
              onPressed: _showInsertMenu,
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 22,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 8),
            // Bold
            _buildToolbarAction(
              icon: Icons.format_bold_rounded,
              label: 'Bold',
              isActive: _isBold,
              onTap: () => setState(() => _isBold = !_isBold),
            ),
            const SizedBox(width: 4),
            // Italic
            _buildToolbarAction(
              icon: Icons.format_italic_rounded,
              label: 'Italic',
              isActive: _isItalic,
              onTap: () => setState(() => _isItalic = !_isItalic),
            ),
            const SizedBox(width: 4),
            // Underline
            _buildToolbarAction(
              icon: Icons.format_underlined_rounded,
              label: 'Underline',
              isActive: _isUnderline,
              onTap: () => setState(() => _isUnderline = !_isUnderline),
            ),
            const SizedBox(width: 4),
            // Checklist
            _buildToolbarAction(
              icon: Icons.check_box_outlined,
              label: 'Checklist',
              onTap: () => _convertActiveBlockType(NoteBlockType.checklist),
            ),
            const SizedBox(width: 4),
            // Bullet List
            _buildToolbarAction(
              icon: Icons.format_list_bulleted_rounded,
              label: 'Bullet',
              onTap: () => _convertActiveBlockType(NoteBlockType.bullet),
            ),
            const SizedBox(width: 4),
            // Heading 1
            _buildToolbarAction(
              icon: Icons.title_rounded,
              label: 'H1',
              onTap: () => _convertActiveBlockType(NoteBlockType.heading1),
            ),
            const SizedBox(width: 4),
            // Heading 2
            _buildToolbarAction(
              icon: Icons.format_size_rounded,
              label: 'H2',
              onTap: () => _convertActiveBlockType(NoteBlockType.heading2),
            ),
            const SizedBox(width: 4),
            // Drawing
            _buildToolbarAction(
              icon: Icons.draw_rounded,
              label: 'Draw',
              isActive: _showDrawingCanvas,
              onTap: () {
                setState(() => _showDrawingCanvas = !_showDrawingCanvas);
                _onContentChanged();
              },
            ),
            const SizedBox(width: 4),
            // Photo Gallery
            _buildToolbarAction(
              icon: Icons.image_outlined,
              label: 'Image',
              onTap: () => _pickAndInsertImage(source: ImageSource.gallery),
            ),
            const SizedBox(width: 4),
            // Paper Style
            _buildToolbarAction(
              icon: Icons.style_outlined,
              label: 'Style',
              onTap: _showTemplatePicker,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primaryIndigo;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: activeColor.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? activeColor
                  : (isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? activeColor
                    : (isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText),
              ),
            ),
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
                'Select Page Paper Style',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
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
                  title: Text(tmpl.label),
                  trailing: isSel
                      ? const Icon(Icons.check, color: AppColors.primaryIndigo)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.folder_off_outlined),
                  title: const Text('No Folder (Root)'),
                  trailing: _folderId == null
                      ? const Icon(Icons.check, color: AppColors.primaryIndigo)
                      : null,
                  onTap: () {
                    setState(() => _folderId = null);
                    _onContentChanged();
                    Navigator.of(ctx).pop();
                  },
                ),
                ...folders.map((f) {
                  final isSel = _folderId == f.id;
                  return ListTile(
                    leading: Icon(
                      Icons.folder_rounded,
                      color: Color(
                        int.parse(f.colorHex.replaceFirst('#', '0xFF')),
                      ),
                    ),
                    title: Text(f.name),
                    trailing: isSel
                        ? const Icon(
                            Icons.check,
                            color: AppColors.primaryIndigo,
                          )
                        : null,
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
}
