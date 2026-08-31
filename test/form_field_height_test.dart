import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_hr_system/consts.dart';
import 'package:my_hr_system/widgets/drop_down_menu.dart';
import 'package:my_hr_system/widgets/form_fields/app_dropdown_form_field.dart';
import 'package:my_hr_system/widgets/form_fields/app_text_form_field.dart';

void main() {
  testWidgets('shared single-line form controls render at 35 pixels', (
    tester,
  ) async {
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    addTearDown(textController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AppTextFormField(
              label: 'Name',
              hintText: 'Name',
              controller: textController,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(TextField)).height,
      AppSizes.inputMinHeight,
    );

    expect(formKey.currentState?.validate(), isFalse);
    await tester.pump();

    expect(find.text('Required'), findsOneWidget);
    expect(
      tester.getSize(find.byType(TextField)).height,
      AppSizes.inputMinHeight,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppDropdownFormField<String>(
            label: 'Country',
            items: const [],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(InputDecorator)).height,
      AppSizes.inputMinHeight,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: CustomDropdown(width: 240),
          ),
        ),
      ),
    );

    final customDropdownField = find.descendant(
      of: find.byType(CustomDropdown),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.minHeight == AppSizes.inputMinHeight &&
            widget.constraints?.maxHeight == AppSizes.inputMinHeight,
      ),
    );
    expect(customDropdownField, findsOneWidget);
    expect(tester.getSize(customDropdownField).height, AppSizes.inputMinHeight);
  });
}
