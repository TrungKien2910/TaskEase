import 'package:flutter/material.dart';
import 'package:buoi6/manhinh/ListViewTaskScreen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:buoi6/manhinh/ThongKeScreen.dart';

class MainApp extends StatefulWidget {
  final int userId;

  const MainApp({super.key, required this.userId});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  @override
  void dispose() {
    _controller.dispose(); // Giải phóng controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> dsManHinh = [
      ListViewTaskScreen(userId: widget.userId),
      ThongKeScreen(userId: widget.userId),
    ];

    return PersistentTabView(
      context,
      controller: _controller,
      screens: dsManHinh,
      items: [
        PersistentBottomNavBarItem(icon: Icon(Icons.home), title: "Home"),
        PersistentBottomNavBarItem(icon: Icon(Icons.settings), title: "Settings"),
      ],
      navBarStyle: NavBarStyle.style1,
    );
  }
}