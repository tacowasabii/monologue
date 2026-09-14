import 'package:flutter/material.dart';

import '../list/script_list_screen.dart';
import 'collections_screen.dart';

/// 앱 첫 화면. 아래 탭으로 모든 대본과 모음(폴더)을 오가고, 켜면 대본부터 보여 준다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 모음 탭에서 뒤로 가면 앱을 닫지 않고 대본 탭으로 돌아온다
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        // 탭을 오가도 검색어·스크롤 위치가 남도록 두 화면을 모두 살려 둔다
        body: IndexedStack(
          index: _index,
          children: const [ScriptListScreen(home: true), CollectionsScreen()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description_rounded),
              label: '대본',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder_rounded),
              label: '모음',
            ),
          ],
        ),
      ),
    );
  }
}
