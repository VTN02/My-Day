import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../notes/domain/models/note.dart';
import '../../notes/domain/models/note_block.dart';
import '../../notes/domain/models/note_template.dart';

/// Arguments passed to the DocumentViewerScreen
class DocumentViewerArgs {
  final String filePath;
  final String fileName;
  final String? mimeType;
  final bool isExternal;

  const DocumentViewerArgs({
    required this.filePath,
    required this.fileName,
    this.mimeType,
    this.isExternal = false,
  });
}

/// Standalone, professional offline Document Viewer for MyDay.
/// Supports native PDF rendering, full-screen zoomable images, formatted TXT viewing,
/// and external delegation for Office formats (DOC, DOCX, XLSX).
class DocumentViewerScreen extends ConsumerStatefulWidget {
  final DocumentViewerArgs args;

  const DocumentViewerScreen({super.key, required this.args});

  @override
  ConsumerState<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends ConsumerState<DocumentViewerScreen> {
  // PDF state
  int _totalPages = 0;
  int _currentPage = 1;
  bool _isPdfReady = false;

  // Text state
  String? _textContent;
  bool _isLoadingText = false;

  // Generic state
  String? _errorMessage;
  int _fileSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadFileMetadata();
    if (_isTextFile) {
      _loadTextContent();
    }
  }

  bool get _isPdf {
    final name = widget.args.fileName.toLowerCase();
    final mime = widget.args.mimeType?.toLowerCase() ?? '';
    return name.endsWith('.pdf') || mime.contains('pdf');
  }

  bool get _isImage {
    final name = widget.args.fileName.toLowerCase();
    final mime = widget.args.mimeType?.toLowerCase() ?? '';
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp') ||
        name.endsWith('.gif') ||
        mime.startsWith('image/');
  }

  bool get _isTextFile {
    final name = widget.args.fileName.toLowerCase();
    final mime = widget.args.mimeType?.toLowerCase() ?? '';
    return name.endsWith('.txt') ||
        name.endsWith('.log') ||
        name.endsWith('.csv') ||
        name.endsWith('.md') ||
        mime.contains('text/plain');
  }

  bool get _isOfficeDoc {
    final name = widget.args.fileName.toLowerCase();
    return name.endsWith('.doc') ||
        name.endsWith('.docx') ||
        name.endsWith('.xls') ||
        name.endsWith('.xlsx') ||
        name.endsWith('.ppt') ||
        name.endsWith('.pptx');
  }

  Future<void> _loadFileMetadata() async {
    try {
      final file = File(widget.args.filePath);
      if (await file.exists()) {
        final length = await file.length();
        if (mounted) {
          setState(() => _fileSizeBytes = length);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadTextContent() async {
    setState(() => _isLoadingText = true);
    try {
      final file = File(widget.args.filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (mounted) {
          setState(() {
            _textContent = content;
            _isLoadingText = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load text file: $e';
          _isLoadingText = false;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _shareDocument() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(widget.args.filePath, name: widget.args.fileName)],
          subject: widget.args.fileName,
          text: 'Document: ${widget.args.fileName}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share document: $e')),
        );
      }
    }
  }

  Future<void> _openExternally() async {
    try {
      final result = await OpenFilex.open(widget.args.filePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message.isNotEmpty
                ? result.message
                : 'No compatible app found to open this document.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open externally: $e')),
        );
      }
    }
  }

  Future<void> _showAddToNotesSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.note_add_rounded, color: AppColors.primaryIndigo),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add to MyDay Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          ),
                        ),
                        Text(
                          widget.args.fileName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Option 1: Create New Note
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryIndigo.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: AppColors.primaryIndigo),
                ),
                title: const Text('Create New Note', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Create a new note with this document attached'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _importToNewNote();
                },
              ),
              const Divider(height: 16),
              // Option 2: Add to Existing Note
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryOcean.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.library_books_rounded, color: AppColors.secondaryOcean),
                ),
                title: const Text('Add to Existing Note', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Choose an existing note to attach this file to'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showExistingNotesPicker();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _importToNewNote() async {
    try {
      final newNoteId = const Uuid().v4();
      final docsDir = await getApplicationDocumentsDirectory();
      final notesAttachmentDir = Directory('${docsDir.path}/notes_attachments/$newNoteId');
      if (!await notesAttachmentDir.exists()) {
        await notesAttachmentDir.create(recursive: true);
      }

      final targetPath = '${notesAttachmentDir.path}/${widget.args.fileName}';
      final srcFile = File(widget.args.filePath);
      await srcFile.copy(targetPath);

      // Create new Note record
      final title = widget.args.fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
      final newNote = Note(
        id: newNoteId,
        title: title,
        body: 'Document attached: ${widget.args.fileName}',
        category: 'General',
        templateType: NoteTemplateType.blank,
        blocks: [
          NoteBlock(
            id: 'block_doc',
            type: NoteBlockType.attachment,
            text: widget.args.fileName,
            meta: targetPath,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(notesRepositoryProvider).saveNote(newNote);

      final ext = widget.args.fileName.split('.').last.toLowerCase();
      await ref.read(notesRepositoryProvider).addAttachment(
            noteId: newNoteId,
            fileName: widget.args.fileName,
            filePath: targetPath,
            fileType: ext,
            fileSizeBytes: _fileSizeBytes,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created note "$title" with attached document.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigate to the newly created note editor
        context.push('/notes/$newNoteId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import to note: $e'),
            backgroundColor: AppColors.errorCoral,
          ),
        );
      }
    }
  }

  Future<void> _showExistingNotesPicker() async {
    final notes = await ref.read(notesRepositoryProvider).getAllNotes();
    if (!mounted) return;

    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No existing notes found. Please create a note first.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Note',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: notes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return ListTile(
                      title: Text(
                        note.title.isNotEmpty ? note.title : 'Untitled Note',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        note.body.isNotEmpty ? note.body : 'Empty note',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _attachToExistingNote(note);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _attachToExistingNote(Note note) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final notesAttachmentDir = Directory('${docsDir.path}/notes_attachments/${note.id}');
      if (!await notesAttachmentDir.exists()) {
        await notesAttachmentDir.create(recursive: true);
      }

      final targetPath = '${notesAttachmentDir.path}/${widget.args.fileName}';
      final srcFile = File(widget.args.filePath);
      await srcFile.copy(targetPath);

      final ext = widget.args.fileName.split('.').last.toLowerCase();
      await ref.read(notesRepositoryProvider).addAttachment(
            noteId: note.id,
            fileName: widget.args.fileName,
            filePath: targetPath,
            fileType: ext,
            fileSizeBytes: _fileSizeBytes,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attached to "${note.title}".'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.push('/notes/${note.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to attach document: $e'),
            backgroundColor: AppColors.errorCoral,
          ),
        );
      }
    }
  }

  void _showDocumentInfoDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.info_outline_rounded, color: AppColors.primaryIndigo),
            SizedBox(width: 8),
            Text('Document Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', widget.args.fileName),
            const SizedBox(height: 8),
            _buildInfoRow('Size', _formatFileSize(_fileSizeBytes)),
            const SizedBox(height: 8),
            _buildInfoRow('Path', widget.args.filePath),
            if (_totalPages > 0) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Pages', '$_totalPages pages'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 2),
        SelectableText(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.args.fileName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'Page $_currentPage of $_totalPages',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
              )
            else if (_fileSizeBytes > 0)
              Text(
                _formatFileSize(_fileSizeBytes),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: _shareDocument,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open with External App',
            onPressed: _openExternally,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'info') {
                _showDocumentInfoDialog();
              } else if (val == 'open') {
                _openExternally();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'info',
                child: ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Document Details'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'open',
                child: ListTile(
                  leading: Icon(Icons.launch_rounded),
                  title: Text('Open in Other App'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(isDark),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.note_add_rounded, size: 20),
                  label: const Text('Add to MyDay Notes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showAddToNotesSheet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.errorCoral),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.errorCoral),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Try Opening in External App'),
                onPressed: _openExternally,
              ),
            ],
          ),
        ),
      );
    }

    if (_isPdf) {
      return Stack(
        children: [
          PDFView(
            filePath: widget.args.filePath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            defaultPage: 0,
            fitPolicy: FitPolicy.WIDTH,
            onRender: (pages) {
              setState(() {
                _totalPages = pages ?? 0;
                _isPdfReady = true;
              });
            },
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = (page ?? 0) + 1;
                _totalPages = total ?? _totalPages;
              });
            },
            onError: (error) {
              setState(() => _errorMessage = error.toString());
            },
          ),
          if (!_isPdfReady)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      );
    }

    if (_isImage) {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.file(
            File(widget.args.filePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image_rounded, size: 56, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text('Could not load image: $error'),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    if (_isTextFile) {
      if (_isLoadingText) {
        return const Center(child: CircularProgressIndicator());
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SelectableText(
          _textContent ?? '',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            fontFamily: 'monospace',
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
        ),
      );
    }

    // Fallback for Office Docs & other binary formats
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isOfficeDoc ? Icons.description_rounded : Icons.insert_drive_file_rounded,
                size: 64,
                color: AppColors.primaryIndigo,
              ),
              const SizedBox(height: 16),
              Text(
                widget.args.fileName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Size: ${_formatFileSize(_fileSizeBytes)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open in Installed App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _openExternally,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
