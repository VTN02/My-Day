import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/note_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';

/// Notes Management Screen Foundation.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Personal',
    'Study',
    'Ideas',
    'Work',
  ];

  void _showAddNoteSheet() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

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
              AppTextField(
                label: 'Content',
                hint: 'Write your thoughts or summaries...',
                maxLines: 4,
                controller: bodyController,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Attach File / Image'),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Save Note',
                isFullWidth: true,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note saved locally')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              eyebrow: 'Knowledge & Ideas',
              title: 'Personal Notes',
              subtitle: '4 notes saved with local attachments',
              trailing: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () {},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SingleChildScrollView(
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
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                NoteCard(
                  title: 'Clean Architecture in Flutter',
                  body:
                      'Key concepts: Presentation, Domain, Data separation. Drift ORM handles persistence, Riverpod handles reactivity.',
                  category: 'Study',
                  date: 'Today, 11:20 AM',
                  attachmentName: 'diagram.png',
                  onTap: () {},
                ),
                NoteCard(
                  title: 'Q4 Personal Budget Optimization',
                  body:
                      'Focus on reducing discretionary dining expenses by 15% and allocating the surplus towards emergency savings.',
                  category: 'Personal',
                  date: 'Yesterday',
                  onTap: () {},
                ),
                NoteCard(
                  title: 'App Ideas: Offline-First Synchronizer',
                  body:
                      'Use append-only transaction logs with Vector Clocks for seamless peer-to-peer conflict resolution.',
                  category: 'Ideas',
                  date: 'Oct 04',
                  attachmentName: 'specs.pdf',
                  onTap: () {},
                ),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          'New Note',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: _showAddNoteSheet,
      ),
    );
  }
}
