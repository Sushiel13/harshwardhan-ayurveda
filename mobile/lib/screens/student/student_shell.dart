import 'package:flutter/material.dart';

import 'home_tab.dart';
import 'catalog_tabs.dart';
import 'profile_tab.dart';

class StudentShell extends StatefulWidget {
  final VoidCallback? onAdminView;
  const StudentShell({super.key, this.onAdminView});
  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(goTo: (t) => setState(() => i = t)),
      const CoursesTab(),
      const TestsTab(),
      const LibraryTab(),
      ProfileTab(onAdminView: widget.onAdminView),
    ];
    return Scaffold(
      body: IndexedStack(index: i, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle), label: 'Courses'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: 'Tests'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}
