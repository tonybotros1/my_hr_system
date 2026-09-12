import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_hr_system/consts.dart';
import 'package:my_hr_system/widgets/drop_down_menu.dart';
import 'package:my_hr_system/widgets/form_fields/app_text_form_field.dart';

void main() {
  testWidgets('dropdowns without supplied nodes participate in Tab traversal', (
    tester,
  ) async {
    final beforeController = TextEditingController();
    final afterController = TextEditingController();
    final beforeFocus = FocusNode(debugLabel: 'before dropdown');
    final afterFocus = FocusNode(debugLabel: 'after dropdown');
    addTearDown(() {
      beforeController.dispose();
      afterController.dispose();
      beforeFocus.dispose();
      afterFocus.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Column(
            children: [
              AppTextFormField(
                label: 'Before',
                hintText: 'Before',
                controller: beforeController,
                focusNode: beforeFocus,
                autofocus: true,
              ),
              const CustomDropdown(
                width: 320,
                hintText: 'Focusable menu',
                items: {
                  'one': {'name': 'One'},
                },
                showedSelectedName: 'name',
              ),
              AppTextFormField(
                label: 'After',
                hintText: 'After',
                controller: afterController,
                focusNode: afterFocus,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(beforeFocus.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'CustomDropdown(Focusable menu)',
    );
    final dropdown = find.byWidgetPredicate(
      (widget) =>
          widget is CustomDropdown && widget.hintText == 'Focusable menu',
    );
    final focusedBorders = tester
        .widgetList<Container>(
          find.descendant(of: dropdown, matching: find.byType(Container)),
        )
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .map((decoration) => decoration.border)
        .whereType<Border>()
        .where(
          (border) =>
              border.top.color == AppColors.primary && border.top.width == 1.3,
        );
    expect(focusedBorders, isNotEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(afterFocus.hasFocus, isTrue);
  });

  testWidgets('Tab closes an open dropdown and moves to the following field', (
    tester,
  ) async {
    final afterController = TextEditingController();
    final afterFocus = FocusNode(debugLabel: 'after open dropdown');
    addTearDown(() {
      afterController.dispose();
      afterFocus.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Column(
            children: [
              const CustomDropdown(
                width: 320,
                hintText: 'Open menu',
                items: {
                  'one': {'name': 'One'},
                },
                showedSelectedName: 'name',
              ),
              AppTextFormField(
                label: 'After open menu',
                hintText: 'After open menu',
                controller: afterController,
                focusNode: afterFocus,
              ),
            ],
          ),
        ),
      ),
    );

    final searchField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == 'Search…',
    );
    await tester.tap(find.text('Open menu'));
    await tester.pumpAndSettle();
    expect(searchField, findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(searchField, findsNothing);
    expect(afterFocus.hasFocus, isTrue);
  });

  testWidgets('opened dropdown uses the shared 250 pixel height limit', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: CustomDropdown(
              width: 320,
              hintText: 'Tall menu',
              items: {
                for (var index = 0; index < 20; index++)
                  '$index': {'name': 'Option $index'},
              },
              showedSelectedName: 'name',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tall menu'));
    await tester.pumpAndSettle();

    final searchField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == 'Search…',
    );
    final popup = find.ancestor(
      of: searchField,
      matching: find.byWidgetPredicate(
        (widget) => widget is Material && widget.elevation == 8,
      ),
    );

    expect(popup, findsOneWidget);
    expect(tester.getSize(popup).height, AppSizes.dropdownMenuMaxHeight);
  });
}
