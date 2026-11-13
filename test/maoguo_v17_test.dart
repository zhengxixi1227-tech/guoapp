import 'package:duanju_app/design_tokens.dart';
import 'package:duanju_app/detail_screen.dart';
import 'package:duanju_app/local_store.dart';
import 'package:duanju_app/models.dart';
import 'package:duanju_app/settings_screen.dart';
import 'package:duanju_app/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';
import 'library_feature_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  EditableText.debugDeterministicCursor = true;

  Future<LocalStore> create() async {
    SharedPreferences.setMockInitialValues({});
    final store = testStore(await SharedPreferences.getInstance());
    addTearDown(store.dispose);
    return store;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  Finder greenRing() => find.byWidgetPredicate((widget) {
    if (widget is AnimatedContainer) {
      final decoration = widget.decoration;
      if (decoration is BoxDecoration) {
        final border = decoration.border;
        if (border is Border) {
          return border.top.color == TvColor.focusRing;
        }
      }
    }
    return false;
  });

  testWidgets('settings exposes the source gate and unlocking shows all sources', (
    tester,
  ) async {
    final store = await create();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          repository: FixtureRepository(),
          store: store,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('站源密码锁'), findsOneWidget);
    expect(find.textContaining('隐藏的源默认隐藏'), findsOneWidget);

    await tester.tap(find.text('站源密码锁'));
    await settle(tester);
    expect(find.text('设置密码（3 至 12 位数字）'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '666');
    await tester.enterText(find.byType(TextField).last, '666');
    await tester.tap(find.text('启用密码锁'));
    await settle(tester);
    expect(store.sourceGateEnabled, isTrue);
    expect(store.sourcesUnlocked, isTrue);
    expect(store.sources.length, SourceSite.values.length);
    expect(find.textContaining('已解锁'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('tapping a phone tile shows the green focus ring', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: DramaTile(
              key: const ValueKey('hongguo:100'),
              drama: FixtureRepository.free,
              repository: FixtureRepository(),
              onTap: () => tapped++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(greenRing(), findsNothing);
    await tester.tap(find.byKey(const ValueKey('hongguo:100')));
    await tester.pump();
    expect(tapped, 1);
    expect(greenRing(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail page labels the season row as 合季', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const seasonOne = Drama(
      id: 'hongguo:series-one',
      source: 'hongguo',
      title: '合成系列 第一季',
      episodes: 12,
    );
    const seasonTwo = Drama(
      id: 'hongguo:series-two',
      source: 'hongguo',
      title: '合成系列 第二季',
      episodes: 10,
    );
    final store = await create();
    await store.refreshDramas([seasonOne, seasonTwo]);
    final repository = LibraryFeatureRepository()
      ..details[seasonOne.id] = LibraryFeatureRepository.makeDetail(
        seasonOne,
        12,
      )
      ..details[seasonTwo.id] = LibraryFeatureRepository.makeDetail(
        seasonTwo,
        10,
      );
    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          drama: seasonOne,
          repository: repository,
          store: store,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('合季'), findsOneWidget);
    expect(find.text('相关推荐'), findsNothing);
    expect(find.byKey(ValueKey('series-${seasonTwo.id}')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
