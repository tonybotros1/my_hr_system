import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_hr_system/consts.dart';
import 'package:my_hr_system/widgets/form_fields/app_date_form_field.dart';

void main() {
  testWidgets('shared date field clears from its button and keyboard', (
    tester,
  ) async {
    final controller = TextEditingController(text: '2026-09-01');
    addTearDown(controller.dispose);
    DateTime? changedDate = DateTime(2000);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: AppDateFormField(
            label: 'Test Date',
            controller: controller,
            onChanged: (date) => changedDate = date,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Clear Test Date'));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(changedDate, isNull);

    controller.text = '2026-09-02';
    await tester.pump();
    final dateEditor = find.byWidgetPredicate(
      (widget) =>
          widget is EditableText && widget.controller.text == '2026-09-02',
    );
    tester.state<EditableTextState>(dateEditor).widget.focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(controller.text, isEmpty);
  });

  testWidgets('shared date field selects and formats a date', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    DateTime? changedDate;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: AppDateFormField(
            label: 'Test Date',
            controller: controller,
            initialDate: DateTime(2026, 1, 10),
            firstDate: DateTime(2026, 1),
            lastDate: DateTime(2026, 1, 31),
            onChanged: (date) => changedDate = date,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Select Test Date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(controller.text, '2026-01-15');
    expect(changedDate, DateTime(2026, 1, 15));
  });
}
