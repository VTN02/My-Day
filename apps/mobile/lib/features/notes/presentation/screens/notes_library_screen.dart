import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/providers/database_providers.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/empty_state.dart';
import 'package:mobile/core/widgets/loading_state.dart';
import 'package:mobile/features/notes/domain/models/note.dart';

enum NotesSortOrder {
  lastModified,
  dateCreated,
  titleAz;

  String get label {
    switch (this) {
      case NotesSortOrder.lastModified:
        return 'Last Modified';
      case NotesSortOrder.dateCreated:
        return 'Date Created';
      case NotesSortOrder.titleAz:
        return 'Title (A-Z)';
    }
  }
}

/// Upgraded Samsung Notes–inspired Notes Library Screen.
class NotesLibraryScreen extends ConsumerStatefulWidget {
  const NotesLibraryScreen({super.key});

  @override
  ConsumerState<NotesLibraryScreen> createState() => _NotesLibraryScreenState();
}

class _NotesLibraryScreenState extends ConsumerState<NotesLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  String _activeTab = 'all'; // 'all', 'pinned', 'folders'
  String? _selectedFolderId;
  NotesSortOrder _sortOrder = NotesSortOrder.lastModified;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateFolderDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Folder name...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(ctx).pop();
                await ref
                    .read(notesRepositoryProvider)
                    .createFolder(name: name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showSortMenu() {
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
                'Sort Notes By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 12),
              ...NotesSortOrder.values.map((order) {
                final isSel = _sortOrder == order;
                return ListTile(
                  title: Text(order.label),
                  trailing: isSel
                      ? const Icon(Icons.check, color: AppColors.primaryIndigo)
                      : null,
                  onTap: () {
                    setState(() => _sortOrder = order);
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

  List<Note> _filterAndSortNotes(List<Note> allNotes) {
    var notes = List<Note>.from(allNotes);

    // 1. Search Query Filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      notes = notes.where((n) {
        final titleMatch = n.title.toLowerCase().contains(query);
        final bodyMatch = n.body.toLowerCase().contains(query);
        final blockMatch = n.blocks.any(
          (b) => b.text.toLowerCase().contains(query),
        );
        return titleMatch || bodyMatch || blockMatch;
      }).toList();
    }

    // 2. Tab Filter
    if (_activeTab == 'pinned') {
      notes = notes.where((n) => n.isPinned).toList();
    } else if (_activeTab == 'folders' && _selectedFolderId != null) {
      notes = notes.where((n) => n.folderId == _selectedFolderId).toList();
    }

    // 3. Sorting
    switch (_sortOrder) {
      case NotesSortOrder.lastModified:
        notes.sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
        break;
      case NotesSortOrder.dateCreated:
        notes.sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case NotesSortOrder.titleAz:
        notes.sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
        break;
    }

    return notes;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notesAsync = ref.watch(activeNotesStreamProvider);
    final foldersAsync = ref.watch(noteFoldersStreamProvider);
    final trashedAsync = ref.watch(trashedNotesStreamProvider);

    final trashCount = trashedAsync.maybeWhen(
      data: (t) => t.length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Notes',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
        elevation: 0.5,
        actions: [
          // Grid / List Toggle
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              size: 22,
            ),
            tooltip: _isGridView ? 'List View' : 'Grid View',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          // Sort Options
          IconButton(
            icon: const Icon(Icons.sort_rounded, size: 22),
            tooltip: 'Sort Notes',
            onPressed: _showSortMenu,
          ),
          // Trash Bin Navigation
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 22),
                tooltip: 'Trash Bin',
                onPressed: () => context.push('/notes/trash'),
              ),
              if (trashCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.errorCoral,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$trashCount',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Filter Header
          Container(
            color: isDark ? AppColors.darkCardSurface : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Input
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search titles and note text...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Tabs (All Notes, Pinned, Folders)
                Row(
                  children: [
                    _buildTabChip('all', 'All Notes'),
                    const SizedBox(width: 8),
                    _buildTabChip('pinned', 'Pinned'),
                    const SizedBox(width: 8),
                    _buildTabChip('folders', 'Folders'),
                  ],
                ),
              ],
            ),
          ),

          // Sub-folder horizontal strip when 'folders' tab is active
          if (_activeTab == 'folders')
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: isDark
                  ? AppColors.darkBackground
                  : const Color(0xFFF1F5F9),
              child: foldersAsync.when(
                data: (folders) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: const Text('New Folder'),
                          onPressed: _showCreateFolderDialog,
                        ),
                        const SizedBox(width: 8),
                        ...folders.map((f) {
                          final isSel = _selectedFolderId == f.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: Icon(
                                Icons.folder_rounded,
                                size: 16,
                                color: Color(
                                  int.parse(
                                    f.colorHex.replaceFirst('#', '0xFF'),
                                  ),
                                ),
                              ),
                              label: Text('${f.name} (${f.noteCount})'),
                              selected: isSel,
                              onSelected: (val) {
                                setState(() {
                                  _selectedFolderId = val ? f.id : null;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),

          // Notes List / Grid
          Expanded(
            child: notesAsync.when(
              data: (allNotes) {
                final notes = _filterAndSortNotes(allNotes);

                if (notes.isEmpty) {
                  return EmptyState(
                    icon: Icons.note_alt_outlined,
                    title: 'No notes found',
                    message: _searchController.text.isNotEmpty
                        ? 'No notes match your search query.'
                        : 'Tap the "+" button below to jot down your first note or drawing.',
                    actionLabel: 'Create Note',
                    onActionPressed: () => context.push('/notes/create'),
                  );
                }

                if (_isGridView) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      return _buildNoteGridCard(notes[index], isDark);
                    },
                  );
                } else {
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildNoteListCard(notes[index], isDark);
                    },
                  );
                }
              },
              loading: () => const LoadingState(),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'New Note',
        onPressed: () => context.push('/notes/create'),
        child: const Icon(Icons.edit_note_rounded, size: 28),
      ),
    );
  }

  Widget _buildTabChip(String key, String label) {
    final isSel = _activeTab == key;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primaryIndigo : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel
                ? AppColors.primaryIndigo
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            color: isSel ? Colors.white : null,
          ),
        ),
      ),
    );
  }

  Widget _buildNoteGridCard(Note note, bool isDark) {
    final dateFormat = DateFormat('MMM d');

    return GestureDetector(
      onTap: () => context.push('/notes/${note.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
            width: note.isPinned ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category pill & Pin icon
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryIndigo,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (note.isPinned)
                  const Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: AppColors.primaryIndigo,
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Title
            Text(
              note.title.isEmpty ? 'Untitled' : note.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 6),

            // Body preview
            Expanded(
              child: Text(
                note.body.isEmpty
                    ? (note.hasDrawings ? 'Contains drawing' : 'Empty note')
                    : note.body,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                ),
              ),
            ),

            // Bottom Badges (Drawing, Checklist, Attachment, Date)
            Row(
              children: [
                if (note.hasDrawings)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.draw_rounded,
                      size: 14,
                      color: AppColors.primaryIndigo,
                    ),
                  ),
                if (note.hasChecklists)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.check_box_outlined,
                      size: 14,
                      color: AppColors.successMint,
                    ),
                  ),
                if (note.attachmentCount > 0)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.attach_file,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                const Spacer(),
                Text(
                  dateFormat.format(note.updatedAt),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteListCard(Note note, bool isDark) {
    final dateFormat = DateFormat('MMM d, y');

    return GestureDetector(
      onTap: () => context.push('/notes/${note.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
            width: note.isPinned ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Left indicator icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                note.hasDrawings
                    ? Icons.draw_rounded
                    : note.hasChecklists
                    ? Icons.checklist_rounded
                    : Icons.description_rounded,
                size: 20,
                color: AppColors.primaryIndigo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title.isEmpty ? 'Untitled' : note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                      ),
                      if (note.isPinned)
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 16,
                          color: AppColors.primaryIndigo,
                        ),
                    ],
                  ),
                  if (note.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      note.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dateFormat.format(note.updatedAt),
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
