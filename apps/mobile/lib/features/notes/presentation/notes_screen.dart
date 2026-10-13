import 'package:flutter/material.dart';
import 'screens/notes_library_screen.dart';

/// Legacy export wrapper forwarding to the full Samsung Notes-inspired NotesLibraryScreen.
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotesLibraryScreen();
  }
}
