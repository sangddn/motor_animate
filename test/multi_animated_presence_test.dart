import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motor_animate/motor_animate.dart';

List<String> _renderedTexts(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((Text text) => text.data!)
      .toList(growable: false);
}

Widget _buildColumnHost(
  List<String> items, {
  void Function(MultiAnimatedPresenceDelegate<String, String> delegate)?
      onDelegate,
  MultiAnimatedPresenceTransitionBuilder<String, String>? onAppear,
  MultiAnimatedPresenceTransitionBuilder<String, String>? onDisappear,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MultiAnimatedPresence<String, String>(
      items: items,
      keyOf: (String item) => item,
      itemBuilder: (BuildContext context,
              MultiAnimatedPresenceEntry<String, String> entry) =>
          Text(entry.item),
      onAppear: onAppear ??
          (_, __, Animate child) => child.fadeIn(motion: Motion.linear(100.ms)),
      onDisappear: onDisappear ??
          (_, __, Animate child) =>
              child.fadeOut(motion: Motion.linear(100.ms)),
      builder: (BuildContext context,
          MultiAnimatedPresenceDelegate<String, String> delegate) {
        onDelegate?.call(delegate);
        return Column(children: delegate.buildChildren(context));
      },
    ),
  );
}

Widget _buildListViewHost(
  List<String> items, {
  required void Function(MultiAnimatedPresenceDelegate<String, String> delegate)
      onDelegate,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      height: 240,
      child: MultiAnimatedPresence<String, String>(
        items: items,
        keyOf: (String item) => item,
        itemBuilder: (BuildContext context,
                MultiAnimatedPresenceEntry<String, String> entry) =>
            Text(entry.item),
        onAppear: (_, __, Animate child) =>
            child.fadeIn(motion: Motion.linear(100.ms)),
        onDisappear: (_, __, Animate child) =>
            child.fadeOut(motion: Motion.linear(100.ms)),
        builder: (BuildContext context,
            MultiAnimatedPresenceDelegate<String, String> delegate) {
          onDelegate(delegate);
          return ListView.builder(
            itemCount: delegate.itemCount,
            itemBuilder: delegate.itemBuilder,
            findChildIndexCallback: delegate.findChildIndexCallback,
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets(
      'MultiAnimatedPresence keeps removed items mounted until exit completes',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildColumnHost(<String>['a', 'b', 'c']));
    await tester.pump(0.ms);
    expect(_renderedTexts(tester), <String>['a', 'b', 'c']);

    await tester.pumpWidget(_buildColumnHost(<String>['a', 'c']));
    await tester.pump(0.ms);
    expect(_renderedTexts(tester), <String>['a', 'b', 'c']);

    await tester.pump(100.ms);
    await tester.pump(0.ms);
    expect(_renderedTexts(tester), <String>['a', 'c']);
  });

  testWidgets(
      'MultiAnimatedPresence revives an exiting item when its key returns',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildColumnHost(<String>['a', 'b']));
    await tester.pump(0.ms);

    await tester.pumpWidget(_buildColumnHost(<String>['a']));
    await tester.pump(0.ms);
    await tester.pump(50.ms);
    expect(_renderedTexts(tester), <String>['a', 'b']);

    await tester.pumpWidget(_buildColumnHost(<String>['a', 'b']));
    await tester.pump(0.ms);
    expect(_renderedTexts(tester), <String>['a', 'b']);

    await tester.pump(100.ms);
    await tester.pump(0.ms);
    expect(_renderedTexts(tester), <String>['a', 'b']);
  });

  testWidgets(
      'MultiAnimatedPresence delegate supports builder hosts and key lookup',
      (WidgetTester tester) async {
    late MultiAnimatedPresenceDelegate<String, String> latestDelegate;

    await tester.pumpWidget(
      _buildListViewHost(
        <String>['a', 'b', 'c'],
        onDelegate: (MultiAnimatedPresenceDelegate<String, String> delegate) {
          latestDelegate = delegate;
        },
      ),
    );
    await tester.pump(0.ms);

    expect(latestDelegate.itemCount, 3);
    expect(latestDelegate.indexOfKey('a'), 0);
    expect(latestDelegate.indexOfKey('b'), 1);
    expect(latestDelegate.entries[1].isExiting, isFalse);
    expect(_renderedTexts(tester), <String>['a', 'b', 'c']);

    await tester.pumpWidget(
      _buildListViewHost(
        <String>['a', 'c'],
        onDelegate: (MultiAnimatedPresenceDelegate<String, String> delegate) {
          latestDelegate = delegate;
        },
      ),
    );
    await tester.pump(0.ms);

    expect(latestDelegate.itemCount, 3);
    expect(latestDelegate.indexOfKey('b'), 1);
    expect(latestDelegate.entries[1].isExiting, isTrue);
    expect(_renderedTexts(tester), <String>['a', 'b', 'c']);

    await tester.pump(100.ms);
    await tester.pump(0.ms);

    expect(latestDelegate.itemCount, 2);
    expect(latestDelegate.indexOfKey('b'), isNull);
    expect(_renderedTexts(tester), <String>['a', 'c']);
  });

  testWidgets('MultiAnimatedPresence can use default transitions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildColumnHost(
        <String>['a'],
        onAppear: null,
        onDisappear: null,
      ),
    );
    await tester.pump(0.ms);
    expect(_renderedTexts(tester), <String>['a']);

    await tester.pumpWidget(
      _buildColumnHost(
        const <String>[],
        onAppear: null,
        onDisappear: null,
      ),
    );
    await tester.pump(0.ms);
    expect(_renderedTexts(tester), <String>['a']);

    await tester.pump(300.ms);
    await tester.pump(0.ms);
    expect(_renderedTexts(tester), isEmpty);
  });
}
