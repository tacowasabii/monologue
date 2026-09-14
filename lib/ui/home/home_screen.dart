import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/adaptive.dart';
import '../list/script_list_screen.dart';
import 'collections_screen.dart';

/// 앱 첫 화면. 탭으로 모든 대본과 모음(폴더)을 오가고, 켜면 대본부터 보여 준다.
/// 탭은 아래에 두고, 아이패드처럼 넓은 창에서는 왼쪽 레일로 옮긴다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    final rail = usesSideRail(context);
    return PopScope(
      // 모음 탭에서 뒤로 가면 앱을 닫지 않고 대본 탭으로 돌아온다
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        body: Row(
          children: [
            if (rail) ...[
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: _select,
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.description_outlined),
                    selectedIcon: Icon(Icons.description_rounded),
                    label: Text('대본'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.folder_outlined),
                    selectedIcon: Icon(Icons.folder_rounded),
                    label: Text('모음'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
            ],
            // 탭을 오가도 검색어·스크롤 위치가 남도록 두 화면을 모두 살려 둔다.
            // 레일이 생기거나 없어져도 늘 마지막 칸이라 새로 만들어지지 않는다
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [ScriptListScreen(home: true), CollectionsScreen()],
              ),
            ),
          ],
        ),
        bottomNavigationBar: rail
            ? null
            : Builder(
                builder: (context) {
                  // Scaffold가 위쪽 여백을 뺀 뒤의 값이어야 한다. 화면 전체 값을 쓰면 상태 표시줄 여백이 탭 위에 붙는다
                  final media = MediaQuery.of(context);
                  // 아이폰은 기본 높이(80) 아래에 홈 인디케이터 여백(34)이 붙어 탭이 너무 높고, 줄이면 아이콘이 위로 붙는다.
                  // 홈 인디케이터 여백 일부를 탭 안쪽으로 옮겨 전체 높이는 줄이고 아이콘·글자는 아래로 내린다
                  final shift = ios ? math.min(24.0, media.padding.bottom) : 0.0;
                  return MediaQuery(
                    data: media.copyWith(padding: media.padding.copyWith(bottom: media.padding.bottom - shift)),
                    child: NavigationBar(
                      height: ios ? 60 + shift : null,
                      selectedIndex: _index,
                      onDestinationSelected: _select,
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
                  );
                },
              ),
      ),
    );
  }
}
