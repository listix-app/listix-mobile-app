import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listix/src/core/widgets/content_width.dart';

void main() {
  testWidgets('ContentWidth caps width on wide screens', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ContentWidth(child: SizedBox.expand(key: Key('content'))),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('content'))).width,
      ContentWidth.readingWidth,
    );
  });

  testWidgets('ContentWidth keeps narrow screens full width', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ContentWidth(child: SizedBox.expand(key: Key('content'))),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('content'))).width, 400);
  });
}
