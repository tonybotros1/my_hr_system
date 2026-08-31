import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/employee_controllers/employees_controller.dart';
import '../../models/employees/employee_model.dart';
import '../../services/browser_dialog_history.dart';
import '../dialogs/app_alert_dialog.dart';
import '../drop_down_menu.dart';
import '../form_fields/app_text_form_field.dart';
import 'employee_records_table.dart';

Future<bool> showEmployeeRecordDialog(
  BuildContext context, {
  required EmployeeRecordKind kind,
  EmployeeRecord? record,
}) async {
  final size = MediaQuery.sizeOf(context);
  final layout = _layoutFor(kind);
  final availableWidth = math.max(280, size.width - (AppSpacing.md * 2));
  final availableHeight = math.max(260, size.height - (AppSpacing.md * 2));
  bool? result;
  final history = BrowserDialogHistory.open(() {
    if (Get.isDialogOpen == true) Get.back<bool>(result: false);
  });
  try {
    result = await Get.dialog<bool>(
      Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.editor),
        ),
        child: SizedBox(
          width: math.min(layout.width, availableWidth).toDouble(),
          height: math.min(layout.height, availableHeight).toDouble(),
          child: _EmployeeRecordEditor(
            kind: kind,
            record: record,
            preferredColumns: layout.columns,
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: AppColors.dialogScrim,
    );
  } finally {
    history.complete();
  }
  return result == true;
}

_RecordDialogLayout _layoutFor(EmployeeRecordKind kind) => switch (kind) {
  EmployeeRecordKind.address ||
  EmployeeRecordKind.nationality => const _RecordDialogLayout(
    width: AppSizes.employeeRecordDialogMediumWidth,
    height: 270,
    columns: 3,
  ),
  EmployeeRecordKind.phone => const _RecordDialogLayout(
    width: AppSizes.employeeRecordDialogSmallWidth,
    height: 270,
    columns: 2,
  ),
  EmployeeRecordKind.socialContact => const _RecordDialogLayout(
    width: AppSizes.employeeRecordDialogSmallWidth,
    height: 350,
    columns: 2,
  ),
  EmployeeRecordKind.bankAccount => const _RecordDialogLayout(
    width: AppSizes.employeeRecordDialogMediumWidth,
    height: 350,
    columns: 2,
  ),
  EmployeeRecordKind.healthCard => const _RecordDialogLayout(
    width: AppSizes.employeeRecordDialogWideWidth,
    height: 460,
    columns: 3,
  ),
  EmployeeRecordKind.payrollElement ||
  EmployeeRecordKind.loanAdvance => const _RecordDialogLayout(
    width: AppSizes.employeeRecordDialogMediumWidth,
    height: 455,
    columns: 2,
  ),
  EmployeeRecordKind.leave => const _RecordDialogLayout(
    width: AppSizes.employeeRecordDialogMediumWidth,
    height: 540,
    columns: 2,
  ),
  EmployeeRecordKind.contactRelative => const _RecordDialogLayout(
    width: AppSizes.employeeRecordDialogWideWidth,
    height: 620,
    columns: 3,
  ),
};

class _RecordDialogLayout {
  const _RecordDialogLayout({
    required this.width,
    required this.height,
    required this.columns,
  });

  final double width;
  final double height;
  final int columns;
}

class _EmployeeRecordEditor extends StatefulWidget {
  const _EmployeeRecordEditor({
    required this.kind,
    required this.preferredColumns,
    this.record,
  });

  final EmployeeRecordKind kind;
  final int preferredColumns;
  final EmployeeRecord? record;

  @override
  State<_EmployeeRecordEditor> createState() => _EmployeeRecordEditorState();
}

class _EmployeeRecordEditorState extends State<_EmployeeRecordEditor> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  final Map<String, String> _ids = {};
  bool _useForPayslips = false;
  bool _payInAdvance = false;
  bool _isEmergency = false;
  String _holderType = 'Employee';

  EmployeesController get controller => Get.find<EmployeesController>();
  EmployeeRecord? get record => widget.record;

  @override
  void initState() {
    super.initState();
    for (final key in _allKeys) {
      _fields[key] = TextEditingController(text: _initialText(key));
    }
    _ids.addAll({
      'country': _raw('country'),
      'city': _raw('city'),
      'nationality': _raw('nationality'),
      'type': _raw('type'),
      'bank_name': _raw('bank_name'),
      'health_card_type': _raw('health_card_type'),
      'health_card_holder': _raw('health_card_holder'),
      'insurance_company': _raw('insurance_company'),
      'name': _raw('name'),
      'leave_type': _raw('leave_type'),
      'relationship': _raw('relationship'),
      'gender': _raw('gender'),
    });
    _useForPayslips = record?.boolean('use_for_payslips') ?? false;
    _payInAdvance = record?.boolean('pay_in_advance') ?? false;
    _isEmergency = record?.boolean('is_emergency') ?? false;
    final initialHolderType = _raw('health_card_holder_type');
    if (initialHolderType.isNotEmpty) _holderType = initialHolderType;
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DialogHeader(
          title:
              '${record == null ? 'New' : 'Edit'} ${labelForRecordKind(widget.kind)}',
        ),
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _body(context),
            ),
          ),
        ),
        _DialogFooter(onSave: _save),
      ],
    );
  }

  Widget _body(BuildContext context) => switch (widget.kind) {
    EmployeeRecordKind.address => _grid([
      _text('line', 'Address line', 'Street, building, floor', required: true),
      _dropdown(
        keyName: 'country',
        label: 'Country',
        onOpen: controller.countries,
        required: true,
        onSelected: (_) {
          _ids['city'] = '';
          _fields['city']!.clear();
        },
      ),
      _dropdown(
        keyName: 'city',
        label: 'City',
        onOpen: () => controller.cities(_ids['country'] ?? ''),
        required: true,
      ),
    ]),
    EmployeeRecordKind.nationality => _grid([
      _dropdown(
        keyName: 'nationality',
        label: 'Nationality',
        onOpen: () => controller.listValues('NATIONALITIES'),
        required: true,
      ),
      _date('start_date', 'Start date'),
      _date('end_date', 'End date'),
    ]),
    EmployeeRecordKind.phone => _grid([
      _dropdown(
        keyName: 'type',
        label: 'Phone type',
        onOpen: () => controller.listValues('CONTACT_TYPES'),
        required: true,
      ),
      _text('phone', 'Phone number', '+971 50 000 0000', required: true),
    ]),
    EmployeeRecordKind.socialContact => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _grid([
          _dropdown(
            keyName: 'type',
            label: 'Contact type',
            onOpen: () => controller.listValues('SOCIAL_MEDIA'),
            required: true,
          ),
          _text(
            'email',
            'Email address',
            'employee@example.com',
            required: true,
            keyboardType: TextInputType.emailAddress,
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        _toggle(
          'Use this address for payslips',
          _useForPayslips,
          (value) => setState(() => _useForPayslips = value),
        ),
      ],
    ),
    EmployeeRecordKind.bankAccount => _grid([
      _dropdown(
        keyName: 'bank_name',
        label: 'Bank name',
        onOpen: () => controller.listValues('BANKS'),
        required: true,
      ),
      _text('account_number', 'Account number', 'Account number'),
      _text('iban', 'IBAN', 'International bank account number'),
      _text('swift_code', 'SWIFT code', 'SWIFT / BIC'),
    ]),
    EmployeeRecordKind.healthCard => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _grid([
          _dropdown(
            keyName: 'health_card_type',
            label: 'Health card type',
            onOpen: () => controller.listValues('HEALTH_CARD_TYPES'),
            required: true,
          ),
          _dropdown(
            keyName: 'health_card_holder',
            label: 'Card holder',
            displayKey: 'full_name',
            onOpen: controller.healthCardHolders,
            required: true,
            onSelected: (value) =>
                _holderType = employeeString(value['type']).isEmpty
                ? 'Employee'
                : employeeString(value['type']),
          ),
          _text('card_number', 'Card number', 'Card number', required: true),
          _dropdown(
            keyName: 'insurance_company',
            label: 'Insurance company',
            onOpen: () => controller.listValues('INSURANCE_COMPANIES'),
          ),
          _date('issue_date', 'Issue date'),
          _date('expiry_date', 'Expiry date'),
          _text('cost', 'Cost', '0.00', keyboardType: TextInputType.number),
          _text(
            'employee_contribution',
            'Employee contribution',
            '0.00',
            keyboardType: TextInputType.number,
          ),
        ]),
      ],
    ),
    EmployeeRecordKind.payrollElement => _grid([
      _dropdown(
        keyName: 'name',
        label: 'Payroll element',
        onOpen: controller.payrollElementOptions,
        required: true,
      ),
      _text('value', 'Value', '0.00', keyboardType: TextInputType.number),
      _date('start_date', 'Start date', required: true),
      _date('end_date', 'End date'),
      _text('notes', 'Note', 'Optional note', lines: 3, fullWidth: true),
    ]),
    EmployeeRecordKind.loanAdvance => _grid([
      _dropdown(
        keyName: 'type',
        label: 'Loan / advance type',
        onOpen: controller.loanAdvanceTypes,
        required: true,
      ),
      _text(
        'total_amount',
        'Total amount',
        '0.00',
        required: true,
        keyboardType: TextInputType.number,
      ),
      _text(
        'monthly_installment',
        'Monthly installment',
        '0.00',
        required: true,
        keyboardType: TextInputType.number,
      ),
      _date('deduction_date', 'Deduction date'),
      _text('note', 'Note', 'Optional note', lines: 3, fullWidth: true),
    ]),
    EmployeeRecordKind.leave => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _grid([
          _dropdown(
            keyName: 'leave_type',
            label: 'Leave type',
            onOpen: controller.leaveTypes,
            required: true,
          ),
          _date('start_date', 'Start date', required: true),
          _date('end_date', 'End date', required: true),
          _text(
            'number_of_days',
            'Number of days',
            '0',
            required: true,
            keyboardType: TextInputType.number,
          ),
          _text('note', 'Note', 'Optional note', lines: 3, fullWidth: true),
        ]),
        const SizedBox(height: AppSpacing.md),
        _toggle(
          'Pay in advance',
          _payInAdvance,
          (value) => setState(() => _payInAdvance = value),
        ),
      ],
    ),
    EmployeeRecordKind.contactRelative => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _grid([
          _text('full_name', 'Full name', 'Full name', required: true),
          _dropdown(
            keyName: 'relationship',
            label: 'Relationship',
            onOpen: () => controller.listValues('RELATIONSHIPS'),
            required: true,
          ),
          _text('phone_number', 'Phone number', 'Phone number'),
          _dropdown(
            keyName: 'gender',
            label: 'Gender',
            onOpen: () => controller.listValues('GENDER'),
          ),
          _date('date_of_birth', 'Date of birth'),
          _dropdown(
            keyName: 'nationality',
            label: 'Nationality',
            onOpen: () => controller.listValues('NATIONALITIES'),
          ),
          _text(
            'email_address',
            'Email address',
            'contact@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          _text('note', 'Note', 'Optional note', lines: 3, fullWidth: true),
        ]),
        const SizedBox(height: AppSpacing.md),
        _toggle(
          'Emergency contact',
          _isEmergency,
          (value) => setState(() => _isEmergency = value),
        ),
      ],
    ),
  };

  Widget _grid(List<_GridField> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 740
            ? widget.preferredColumns
            : constraints.maxWidth >= 520
            ? math.min(2, widget.preferredColumns)
            : 1;
        final width =
            (constraints.maxWidth - (AppSpacing.md * (columns - 1))) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: fields
              .map(
                (field) => SizedBox(
                  width: field.fullWidth ? constraints.maxWidth : width,
                  child: field.child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  _GridField _text(
    String key,
    String label,
    String hint, {
    bool required = false,
    int lines = 1,
    bool fullWidth = false,
    TextInputType? keyboardType,
  }) {
    return _GridField(
      fullWidth: fullWidth,
      child: AppTextFormField(
        label: label,
        hintText: hint,
        controller: _fields[key]!,
        validator: required ? controller.requiredText : null,
        maxLines: lines,
        keyboardType: keyboardType,
      ),
    );
  }

  _GridField _date(String key, String label, {bool required = false}) {
    return _GridField(
      child: AppTextFormField(
        label: label,
        hintText: 'YYYY-MM-DD',
        controller: _fields[key]!,
        validator: required ? controller.requiredText : null,
        readOnly: true,
        onTap: () => _pickDate(key),
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
      ),
    );
  }

  _GridField _dropdown({
    required String keyName,
    required String label,
    required Future<Map<String, dynamic>> Function() onOpen,
    String displayKey = 'name',
    String? fallbackDisplayKey,
    bool required = false,
    ValueChanged<Map<String, dynamic>>? onSelected,
  }) {
    return _GridField(
      child: LayoutBuilder(
        builder: (context, constraints) => CustomDropdown(
          width: constraints.maxWidth,
          hintText: label,
          textcontroller: _fields[keyName]!.text,
          showedSelectedName: displayKey,
          validator: required,
          onOpen: onOpen,
          onDelete: () => setState(() {
            _ids[keyName] = '';
            _fields[keyName]!.clear();
          }),
          onChanged: (key, value) {
            final item = Map<String, dynamic>.from(value as Map);
            setState(() {
              _ids[keyName] = key;
              _fields[keyName]!.text =
                  employeeString(item[displayKey]).isNotEmpty
                  ? employeeString(item[displayKey])
                  : employeeString(item[fallbackDisplayKey ?? 'name']);
            });
            onSelected?.call(item);
          },
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.softSurface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: AppTextStyles.checkboxLabel),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _pickDate(String key) async {
    final initial = DateTime.tryParse(_fields[key]!.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime(2200),
    );
    if (picked != null) {
      _fields[key]!.text = EmployeesController.formatDate(picked);
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    if (!_requiredSelectionsComplete) return;
    final saved = await controller.saveRecord(
      widget.kind,
      _bodyPayload,
      recordId: record?.id ?? '',
    );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  bool get _requiredSelectionsComplete {
    final keys = switch (widget.kind) {
      EmployeeRecordKind.address => ['country', 'city'],
      EmployeeRecordKind.nationality => ['nationality'],
      EmployeeRecordKind.phone || EmployeeRecordKind.socialContact => ['type'],
      EmployeeRecordKind.bankAccount => ['bank_name'],
      EmployeeRecordKind.healthCard => [
        'health_card_type',
        'health_card_holder',
      ],
      EmployeeRecordKind.payrollElement => ['name'],
      EmployeeRecordKind.loanAdvance => ['type'],
      EmployeeRecordKind.leave => ['leave_type'],
      EmployeeRecordKind.contactRelative => ['relationship'],
    };
    if (keys.every((key) => (_ids[key] ?? '').isNotEmpty)) return true;
    showAppAlertDialog(
      title: 'Complete required fields',
      message: 'Please select a value for every required list field.',
      kind: AppAlertKind.error,
    );
    return false;
  }

  Map<String, dynamic> get _bodyPayload => switch (widget.kind) {
    EmployeeRecordKind.address => {
      'line': _value('line'),
      'country': _ids['country'],
      'city': _ids['city'],
    },
    EmployeeRecordKind.nationality => {
      'nationality': _ids['nationality'],
      'start_date': _isoOrNull('start_date'),
      'end_date': _isoOrNull('end_date'),
    },
    EmployeeRecordKind.phone => {
      'type': _ids['type'],
      'phone': _value('phone'),
    },
    EmployeeRecordKind.socialContact => {
      'type': _ids['type'],
      'email': _value('email'),
      'use_for_payslips': _useForPayslips,
    },
    EmployeeRecordKind.bankAccount => {
      'bank_name': _ids['bank_name'],
      'account_number': _value('account_number'),
      'iban': _value('iban'),
      'swift_code': _value('swift_code'),
    },
    EmployeeRecordKind.healthCard => {
      'health_card_type': _ids['health_card_type'],
      'health_card_holder': _ids['health_card_holder'],
      'health_card_holder_type': _holderType,
      'card_number': _value('card_number'),
      'insurance_company': _ids['insurance_company'],
      'issue_date': _isoOrNull('issue_date'),
      'expiry_date': _isoOrNull('expiry_date'),
      'cost': _double('cost'),
      'employee_contribution': _double('employee_contribution'),
    },
    EmployeeRecordKind.payrollElement => {
      'name': _ids['name'],
      'value': _double('value'),
      'start_date': _isoOrNull('start_date'),
      'end_date': _isoOrNull('end_date'),
      'notes': _value('notes'),
    },
    EmployeeRecordKind.loanAdvance => {
      'type': _ids['type'],
      'total_amount': _double('total_amount'),
      'monthly_installment': _double('monthly_installment'),
      'deduction_date': _isoOrNull('deduction_date'),
      'note': _value('note'),
    },
    EmployeeRecordKind.leave => {
      'leave_type': _ids['leave_type'],
      'start_date': _isoOrNull('start_date'),
      'end_date': _isoOrNull('end_date'),
      'status': record?.text('status').isEmpty ?? true
          ? 'New'
          : record!.text('status'),
      'number_of_days': int.tryParse(_value('number_of_days')) ?? 0,
      'note': _value('note'),
      'pay_in_advance': _payInAdvance,
    },
    EmployeeRecordKind.contactRelative => {
      'full_name': _value('full_name'),
      'relationship': _ids['relationship'],
      'phone_number': _value('phone_number'),
      'gender': _ids['gender'],
      'date_of_birth': _isoOrNull('date_of_birth'),
      'nationality': _ids['nationality'],
      'email_address': _value('email_address'),
      'note': _value('note'),
      'is_emergency': _isEmergency,
    },
  };

  String _initialText(String key) {
    final aliases = <String, List<String>>{
      'country': ['country_name'],
      'city': ['city_name'],
      'nationality': ['nationality_name'],
      'type': ['type_name'],
      'bank_name': ['bank_name_value'],
      'health_card_type': ['health_card_type_name', 'health_card_type_value'],
      'health_card_holder': ['health_card_holder_name'],
      'insurance_company': [
        'insurance_company_name',
        'insurance_company_value',
      ],
      'name': ['name_value'],
      'leave_type': ['leave_type_name'],
      'relationship': ['relationship_name'],
      'gender': ['gender_name'],
    };
    for (final alias in aliases[key] ?? const <String>[]) {
      final text = record?.text(alias) ?? '';
      if (text.isNotEmpty) return text;
    }
    if (_dateKeys.contains(key)) {
      return EmployeesController.formatDate(record?.date(key));
    }
    return record?.text(key) ?? '';
  }

  String _raw(String key) => record?.text(key) ?? '';
  String _value(String key) => _fields[key]!.text.trim();
  double _double(String key) => double.tryParse(_value(key)) ?? 0;
  String? _isoOrNull(String key) {
    final date = DateTime.tryParse(_value(key));
    return date?.toIso8601String();
  }

  static const _dateKeys = {
    'start_date',
    'end_date',
    'issue_date',
    'expiry_date',
    'deduction_date',
    'date_of_birth',
  };

  static const _allKeys = {
    'line',
    'country',
    'city',
    'nationality',
    'start_date',
    'end_date',
    'type',
    'phone',
    'email',
    'bank_name',
    'account_number',
    'iban',
    'swift_code',
    'health_card_type',
    'health_card_holder',
    'card_number',
    'insurance_company',
    'issue_date',
    'expiry_date',
    'cost',
    'employee_contribution',
    'name',
    'value',
    'notes',
    'total_amount',
    'monthly_installment',
    'deduction_date',
    'note',
    'leave_type',
    'number_of_days',
    'full_name',
    'relationship',
    'phone_number',
    'gender',
    'date_of_birth',
    'email_address',
  };
}

class _GridField {
  const _GridField({required this.child, this.fullWidth = false});

  final Widget child;
  final bool fullWidth;
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: AppTextStyles.heading(fontSize: 20)),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _DialogFooter extends GetView<EmployeesController> {
  const _DialogFooter({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textHint),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: AppSpacing.sm),
          Obx(
            () => TextButton(
              onPressed: controller.isSaving.value ? null : onSave,
              child: controller.isSaving.value
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
