import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/providers/database_providers.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/empty_state.dart';
import 'package:mobile/core/widgets/loading_state.dart';
import 'package:mobile/features/notes/domain/models/note.dart';

/// Screen managing soft-deleted notes (Trash Bin).
class NotesTrashScreen extends ConsumerWidget {
  const NotesTrashScreen({super.key});

  void _confirmEmptyTrash(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'All notes and attachments in the trash will be permanently deleted from the database. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorCoral),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(notesRepositoryProvider).emptyTrash();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trash emptied permanently.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Empty Permanently'),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(BuildContext context, WidgetRef ref, Note note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete "${note.title.isEmpty ? "Untitled Note" : note.title}"?',
        ),
        content: const Text(
          'This note and its attachments will be permanently removed from your device storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorCoral),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(notesRepositoryProvider)
                  .permanentlyDeleteNote(note.id);
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trashedAsync = ref.watch(trashedNotesStreamProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Trash'),
        backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
        elevation: 0.5,
        actions: [
          trashedAsync.maybeWhen(
            data: (notes) => notes.isNotEmpty
                ? TextButton(
                    onPressed: () => _confirmEmptyTrash(context, ref),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.errorCoral,
                    ),
                    child: const Text('Empty Trash'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: trashedAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const EmptyState(
              icon: Icons.delete_outline_rounded,
              title: 'Trash is empty',
              message:
                  'Notes moved to trash will appear here for safe keeping.',
            );
          }

          final dateFormat = DateFormat('MMM d, y • h:mm a');

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final note = notes[index];
              final trashedDateStr = note.trashedAt != null
                  ? 'Deleted: ${dateFormat.format(note.trashedAt!)}'
                  : '';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? 'Untitled Note' : note.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                            ),
                          ),
                        ),
                        Text(
                          trashedDateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                    if (note.body.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Restore Button
                        TextButton.icon(
                          icon: const Icon(
                            Icons.restore_from_trash_rounded,
                            size: 16,
                          ),
                          label: const Text('Restore'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.successMint,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () async {
                            await ref
                                .read(notesRepositoryProvider)
                                .restoreFromTrash(note.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Restored "${note.title.isEmpty ? "Note" : note.title}".',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        // Permanent Delete Button
                        TextButton.icon(
                          icon: const Icon(
                            Icons.delete_forever_rounded,
                            size: 16,
                          ),
                          label: const Text('Delete Forever'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.errorCoral,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () =>
                              _confirmPermanentDelete(context, ref, note),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
