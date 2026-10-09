import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/note_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';

/// Notes Management Screen connected to Drift SQLite repository.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Personal',
    'Study',
    'Ideas',
    'Work',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddNoteSheet() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String selectedCategory = _selectedCategory == 'All'
        ? 'Personal'
        : _selectedCategory;
    bool isPinned = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create New Note',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Note Title',
                    hint: 'Note headline...',
                    controller: titleController,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Category: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: selectedCategory,
                            underline: const SizedBox.shrink(),
                            items:
                                [
                                      'Personal',
                                      'Study',
                                      'Ideas',
                                      'Work',
                                      'General',
                                    ]
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() => selectedCategory = v);
                              }
                            },
                          ),
                        ],
                      ),
                      FilterChip(
                        label: const Text(
                          'Pin to Top',
                          style: TextStyle(fontSize: 12),
                        ),
                        selected: isPinned,
                        selectedColor: AppColors.primaryIndigo.withAlpha(50),
                        checkmarkColor: AppColors.primaryIndigo,
                        onSelected: (val) {
                          setModalState(() => isPinned = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Content',
                    hint: 'Write your thoughts or summaries...',
                    maxLines: 4,
                    controller: bodyController,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Save Note',
                    isFullWidth: true,
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final body = bodyController.text.trim();
                      if (title.isEmpty) return;

                      await ref
                          .read(notesRepositoryProvider)
                          .createNote(
                            title: title,
                            body: body,
                            category: selectedCategory,
                            isPinned: isPinned,
                          );

                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddAttachmentSheet(BuildContext parentCtx, String noteId) {
    final nameController = TextEditingController();
    final pathController = TextEditingController();
    String fileType = 'doc';

    showModalBottomSheet(
      context: parentCtx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Attachment to Note',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Attachment Name',
                    hint: 'e.g. Lecture Slides, Reference URL, Receipt',
                    controller: nameController,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'File Path or Link',
                    hint: 'e.g. https://... or /storage/...',
                    controller: pathController,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Attachment Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Document'),
                        selected: fileType == 'doc',
                        onSelected: (_) =>
                            setModalState(() => fileType = 'doc'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Image'),
                        selected: fileType == 'image',
                        onSelected: (_) =>
                            setModalState(() => fileType = 'image'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Link'),
                        selected: fileType == 'link',
                        onSelected: (_) =>
                            setModalState(() => fileType = 'link'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Attach File',
                    icon: Icons.attach_file,
                    isFullWidth: true,
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final path = pathController.text.trim();
                      if (name.isEmpty) return;

                      await ref
                          .read(notesRepositoryProvider)
                          .addAttachment(
                            noteId: noteId,
                            fileName: name,
                            filePath: path.isEmpty ? name : path,
                            fileType: fileType,
                          );

                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNoteDetailSheet(NoteEntry note) {
    final titleController = TextEditingController(text: note.title);
    final bodyController = TextEditingController(text: note.body);
    String selectedCategory = note.category;
    bool isPinned = note.isPinned;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Note',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isPinned
                                    ? Icons.push_pin_rounded
                                    : Icons.push_pin_outlined,
                                color: isPinned
                                    ? AppColors.primaryIndigo
                                    : (isDark
                                          ? AppColors.darkSecondaryText
                                          : AppColors.lightSecondaryText),
                              ),
                              onPressed: () {
                                setModalState(() => isPinned = !isPinned);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Note Title',
                      controller: titleController,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text(
                          'Category: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: selectedCategory,
                          underline: const SizedBox.shrink(),
                          items:
                              ['Personal', 'Study', 'Ideas', 'Work', 'General']
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setModalState(() => selectedCategory = v);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Content',
                      maxLines: 5,
                      controller: bodyController,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attachments',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              _showAddAttachmentSheet(ctx, note.id),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add File'),
                        ),
                      ],
                    ),
                    Consumer(
                      builder: (context, consumerRef, _) {
                        final attachmentsAsync = consumerRef.watch(
                          noteAttachmentsStreamProvider(note.id),
                        );

                        return attachmentsAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (err, _) => Text(
                            'Error: $err',
                            style: const TextStyle(fontSize: 12),
                          ),
                          data: (attachments) {
                            if (attachments.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  'No attachments added yet.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark
                                        ? AppColors.darkSecondaryText
                                        : AppColors.lightSecondaryText,
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: attachments.map((att) {
                                IconData icon;
                                switch (att.fileType) {
                                  case 'image':
                                    icon = Icons.image_outlined;
                                    break;
                                  case 'link':
                                    icon = Icons.link_rounded;
                                    break;
                                  default:
                                    icon = Icons.description_outlined;
                                }

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkBackground
                                        : AppColors.lightBackground,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        icon,
                                        size: 18,
                                        color: AppColors.accentCyan,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              att.fileName,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColors.darkPrimaryText
                                                    : AppColors
                                                          .lightPrimaryText,
                                              ),
                                            ),
                                            if (att.filePath != att.fileName)
                                              Text(
                                                att.filePath,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? AppColors
                                                            .darkSecondaryText
                                                      : AppColors
                                                            .lightSecondaryText,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: AppColors.errorCoral,
                                        ),
                                        onPressed: () => ref
                                            .read(notesRepositoryProvider)
                                            .deleteAttachment(att.id),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await ref
                                  .read(notesRepositoryProvider)
                                  .deleteNote(note.id);
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.errorCoral,
                              side: const BorderSide(
                                color: AppColors.errorCoral,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Delete Note'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            text: 'Save Changes',
                            onPressed: () async {
                              final title = titleController.text.trim();
                              final body = bodyController.text.trim();
                              if (title.isEmpty) return;

                              final updated = note.copyWith(
                                title: title,
                                body: body,
                                category: selectedCategory,
                                isPinned: isPinned,
                                updatedAt: DateTime.now(),
                              );

                              await ref
                                  .read(notesRepositoryProvider)
                                  .updateNote(updated);

                              if (ctx.mounted) Navigator.of(ctx).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(allNotesStreamProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              eyebrow: 'Knowledge & Ideas',
              title: 'Personal Notes',
              subtitle: 'Local SQLite encrypted notes with attachments',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  AppTextField(
                    hint: 'Search notes by keyword or tag...',
                    controller: _searchController,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: StatusChip(
                            label: category,
                            isSelected: isSelected,
                            onTap: () =>
                                setState(() => _selectedCategory = category),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          notesAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: LoadingState(message: 'Loading notes from SQLite...'),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text('Error loading notes: $err')),
              ),
            ),
            data: (notes) {
              final query = _searchController.text.toLowerCase().trim();
              final filteredNotes = notes.where((n) {
                final matchesCategory =
                    _selectedCategory == 'All' ||
                    n.category.toLowerCase() == _selectedCategory.toLowerCase();
                final matchesSearch =
                    query.isEmpty ||
                    n.title.toLowerCase().contains(query) ||
                    n.body.toLowerCase().contains(query);
                return matchesCategory && matchesSearch;
              }).toList();

              if (filteredNotes.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.sticky_note_2_outlined,
                    title: 'No notes found',
                    message: _selectedCategory == 'All'
                        ? 'Keep your study notes, reflections, and ideas organized.'
                        : 'No notes found in category "$_selectedCategory".',
                    actionLabel: 'New Note',
                    onActionPressed: _showAddNoteSheet,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final note = filteredNotes[index];
                    return NoteCard(
                      key: ValueKey(note.id),
                      title: note.title,
                      body: note.body,
                      category: note.category,
                      isPinned: note.isPinned,
                      date: '${note.updatedAt.month}/${note.updatedAt.day}',
                      onTap: () => _showNoteDetailSheet(note),
                      onPinToggle: () => ref
                          .read(notesRepositoryProvider)
                          .updateNote(
                            note.copyWith(
                              isPinned: !note.isPinned,
                              updatedAt: DateTime.now(),
                            ),
                          ),
                      onDelete: () =>
                          ref.read(notesRepositoryProvider).deleteNote(note.id),
                    );
                  }, childCount: filteredNotes.length),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'New Note',
        onPressed: _showAddNoteSheet,
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }
}
