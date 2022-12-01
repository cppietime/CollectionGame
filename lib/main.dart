import 'dart:math';

import 'package:collectgame/data/ability/ability.dart';
import 'package:collectgame/data/move/move.dart';
import 'package:collectgame/data/move/move_effect.dart';
import 'package:collectgame/data/species/species.dart';
import 'package:collectgame/ui/bottom_nav_screen.dart';
import 'package:collectgame/world/world_object.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'nav_test.dart';

void main() {
  runApp(MyApp());
}

const navItems = [
  NavItem(
    destination: '/',
    navigationIcon:
        NavigationDestination(label: 'Home', icon: Icon(Icons.home)),
    drawerWidget: NavDrawerItem(title: "Home"),
  ),
  NavItem(
    destination: '/home/A',
    navigationIcon:
        NavigationDestination(label: 'A', icon: Icon(Icons.looks_one)),
    drawerWidget: NavDrawerItem(title: "A"),
  ),
  NavItem(
    destination: '/',
    navigationIcon:
        NavigationDestination(label: 'Home', icon: Icon(Icons.home)),
    drawerWidget: NavDrawerItem(title: "Home", icon: Icon(Icons.home)),
  ),
  NavItem(
    destination: '/home/A',
    navigationIcon:
        NavigationDestination(label: 'A', icon: Icon(Icons.looks_one)),
    drawerWidget: NavDrawerItem(title: "A", icon: Icon(Icons.abc_outlined)),
  ),
];

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const BottomNavScreen(
            title: "Home",
            navItems: navItems,
            child: MyHomePage(title: 'Home page')),
      ),
      GoRoute(
        path: '/home/A',
        builder: (context, state) => const BottomNavScreen(
            title: "Screen A", navItems: navItems, child: ScreenA()),
      ),
      GoRoute(
        path: '/home/B',
        builder: (context, state) =>
            const BottomNavScreen(navItems: navItems, child: ScreenB()),
      ),
      GoRoute(
        path: '/A',
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: Text('A'),
          ),
          body: ScreenA(),
        ),
      ),
      GoRoute(
        path: '/B',
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: Text('B'),
          ),
          body: ScreenB(),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: _router,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String message = "default";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appbar'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= constraints.maxHeight;
          final longer = max(constraints.maxWidth, constraints.maxHeight);
          final headingSize = longer * 0.1;
          return Center(
            child: Flex(
              direction: horizontal ? Axis.horizontal : Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: horizontal ? null : headingSize,
                  width: horizontal ? headingSize : null,
                  child: Text(
                    message,
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth -
                        (horizontal ? headingSize * 3 : 0),
                    maxHeight: constraints.maxHeight -
                        (horizontal ? 0 : headingSize * 3),
                  ),
                  child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          color: Colors.red,
                          child: LayoutBuilder(builder: (context, constraints) {
                            print(constraints);
                            final sqr = min(
                                constraints.maxWidth, constraints.maxHeight);
                            return Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  width: sqr * 0.1,
                                  top: 0,
                                  height: sqr * 0.1,
                                  child: Container(
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      )),
                ),
                SizedBox(
                  height: horizontal ? null : headingSize * 2,
                  width: horizontal ? headingSize * 2 : null,
                  child: TextButton(
                    child: Text('Hit me'),
                    onPressed: () async {
                      String newMsg = await showDialog(
                          context: context,
                          builder: (context) {
                            int base = 0;
                            return StatefulBuilder(
                                builder: (context, setState) => AlertDialog(
                                      title: const Text('an list'),
                                      content: Container(
                                        width: 500,
                                        height: 500,
                                        child: ListView(
                                            children: [
                                              DropdownButton(
                                                  value: base,
                                                  items: const [
                                                    DropdownMenuItem<int>(value: 0, child: Text('Option 1')),
                                                    DropdownMenuItem<int>(value: 1, child: Text('Option 2')),
                                                  ],
                                                  onChanged: (int? value) => setState((){
                                                    base = value ?? 0;
                                                  })
                                              ),
                                              Draggable<String>(
                                                data: 'First',
                                                feedback: Text('Thing ${base + 1}'),
                                                child: DragTarget<String>(
                                                  builder: (context, accepted, rejected) => ListTile(
                                                      title:
                                                          Text('Thing ${base + 1}'),
                                                      onTap: () =>
                                                          Navigator.of(context)
                                                              .pop('Thing 1')),
                                                  onAccept: (value) => print('Accepted value $value')
                                                ),
                                              ),
                                              ListTile(
                                                  title: Text(
                                                      'tHiNgY ${base + 2}'),
                                                  onTap: () =>
                                                      Navigator.of(context)
                                                          .pop('tHiNgY 2')),
                                              ListTile(
                                                title: const Text("What's this?"),
                                                onTap: () => showDialog(context: context, builder: (context) => AlertDialog(
                                                  content: const Text('This is a dialog, duh'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                                                  ],
                                                ))
                                              ),
                                            ],
                                          ),
                                      ),
                                      ),
                                    );
                          },
                          barrierDismissible: false);
                      setState(() {
                        message = newMsg;
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
