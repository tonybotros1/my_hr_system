import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_hr_system/consts.dart';
import 'package:my_hr_system/widgets/form_fields/app_date_form_field.dart';

void main() {
  testWidgets('shared date field clears from its button and keyboard', (
    tester,
  ) async {
    final controller = TextEditingController(text: '01-09-2026');
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

    controller.text = '02-09-2026';
    await tester.pump();
    final dateEditor = find.byWidgetPredicate(
      (widget) =>
          widget is EditableText && widget.controller.text == '02-09-2026',
    );
    final editable = tester.state<EditableTextState>(dateEditor).widget;
    editable.focusNode.requestFocus();
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
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

    expect(controller.text, '15-01-2026');
    expect(changedDate, DateTime(2026, 1, 15));
  });

  testWidgets('shared date field formats typing and rejects invalid dates', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    DateTime? changedDate;
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AppDateFormField(
              label: 'Test Date',
              controller: controller,
              onChanged: (date) => changedDate = date,
            ),
          ),
        ),
      ),
    );

    final input = find.byType(TextField);
    await tester.enterText(input, '31022026');
    await tester.pump();
    expect(controller.text, '31-02-2026');
    expect(changedDate, isNull);
    expect(formKey.currentState!.validate(), isFalse);
    expect(
      find.text('Enter a valid date in DD-MM-YYYY format.'),
      findsOneWidget,
    );

    await tester.enterText(input, '29022024');
    await tester.pump();
    expect(controller.text, '29-02-2024');
    expect(changedDate, DateTime(2024, 2, 29));
    expect(formKey.currentState!.validate(), isTrue);
    expect(find.text('Enter a valid date in DD-MM-YYYY format.'), findsNothing);
    expect(find.byTooltip('Select Test Date'), findsOneWidget);
    expect(find.byTooltip('Clear Test Date'), findsOneWidget);
  });
}
