import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proplinq/core/services/deep_link_router.dart';
import 'package:proplinq/core/services/deep_linking_service.dart';
import 'package:proplinq/main.dart';

void main() {
  testWidgets('App starts with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(PropLinqApp(
      deepLinkRouter: DeepLinkRouter(),
      deepLinkingService: DeepLinkingService(),
    ));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
