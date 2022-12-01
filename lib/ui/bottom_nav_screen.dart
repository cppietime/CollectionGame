import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavDrawerItem {
  const NavDrawerItem({this.icon, this.title});

  final Icon? icon;
  final String? title;

  Widget build(Function() onTap) {
    assert(icon != null || title != null, "Icon or title must be non-null");
    if (icon == null) {
      return ListTile(
        title: Text(title!),
        onTap: onTap,
      );
    }
    if (title == null) {
      return IconButton(onPressed: onTap, icon: icon!);
    }
    return ListTile(
        onTap: onTap, leading: icon!, title: Text(title!));
  }
}

class NavItem {
  const NavItem(
      {required this.destination,
      required this.navigationIcon,
      required this.drawerWidget});

  final String destination;
  final NavigationDestination navigationIcon;
  final NavDrawerItem drawerWidget;
}

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen(
      {required this.child, this.navItems = const [], this.title, super.key});

  final Widget child;
  final String? title;
  final List<NavItem> navItems;

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  static int _selected = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.title == null
          ? null
          : AppBar(
              title: Text(widget.title!),
            ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected,
        destinations: widget.navItems
            .map((navItem) => navItem.navigationIcon)
            .toList(growable: false),
        onDestinationSelected: (index) {
          setState(() {_selected = index;});
          GoRouter.of(context).go(widget.navItems[index].destination);
        },
      ),
      drawer: Drawer(
          child: ListView(
        children: widget.navItems
            .map((navItem) => navItem.drawerWidget
                .build(() {
                  Navigator.pop(context);
                  GoRouter.of(context).go(navItem.destination);
                }))
            .toList(growable: false),
      )),
    );
  }
}
