import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../models/employees/employee_model.dart';

class EmployeeRecordsTable extends StatefulWidget {
  const EmployeeRecordsTable({
    required this.kind,
    required this.records,
    required this.onEdit,
    required this.onDelete,
    this.deletingRecordId = '',
    this.utility = false,
    super.key,
  });

  final EmployeeRecordKind kind;
  final List<EmployeeRecord> records;
  final ValueChanged<EmployeeRecord> onEdit;
  final ValueChanged<EmployeeRecord> onDelete;
  final String deletingRecordId;
  final bool utility;

  @override
  State<EmployeeRecordsTable> createState() => _EmployeeRecordsTableState();
}

class _EmployeeRecordsTableState extends State<EmployeeRecordsTable> {
  final _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = recordColumns(widget.kind);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minimum = widget.utility
            ? AppSizes.employeeUtilityTableMinWidth
            : AppSizes.employeeRelatedTableMinWidth;
        final width = constraints.maxWidth < minimum
            ? minimum
            : constraints.maxWidth;
        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  _RecordsHeader(columns: columns),
                  Expanded(
                    child: widget.records.isEmpty
                        ? Center(
                            child: Text(
                              emptyMessageFor(widget.kind),
                              style: AppTextStyles.listCount,
                            ),
                          )
                        : ListView.builder(
                            itemCount: widget.records.length,
                            itemExtent: 52,
                            itemBuilder: (context, index) {
                              final record = widget.records[index];
                              return _RecordRow(
                                record: record,
                                columns: columns,
                                deleting: widget.deletingRecordId == record.id,
                                onEdit: () => widget.onEdit(record),
                                onDelete: () => widget.onDelete(record),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class EmployeeRecordColumn {
  const EmployeeRecordColumn(this.label, this.value, {this.flex = 1});

  final String label;
  final String Function(EmployeeRecord) value;
  final int flex;
}

List<EmployeeRecordColumn> recordColumns(
  EmployeeRecordKind kind,
) => switch (kind) {
  EmployeeRecordKind.address => [
    EmployeeRecordColumn('Line', (r) => r.text('line'), flex: 2),
    EmployeeRecordColumn('Country', (r) => r.text('country_name')),
    EmployeeRecordColumn('City', (r) => r.text('city_name')),
  ],
  EmployeeRecordKind.nationality => [
    EmployeeRecordColumn(
      'Nationality',
      (r) => r.text('nationality_name'),
      flex: 2,
    ),
    EmployeeRecordColumn('Start date', (r) => _date(r, 'start_date')),
    EmployeeRecordColumn('End date', (r) => _date(r, 'end_date')),
  ],
  EmployeeRecordKind.phone => [
    EmployeeRecordColumn('Type', (r) => r.text('type_name')),
    EmployeeRecordColumn('Phone number', (r) => r.text('phone'), flex: 2),
  ],
  EmployeeRecordKind.socialContact => [
    EmployeeRecordColumn('Type', (r) => r.text('type_name')),
    EmployeeRecordColumn('Email address', (r) => r.text('email'), flex: 2),
    EmployeeRecordColumn(
      'Payslips',
      (r) => r.boolean('use_for_payslips') ? 'Yes' : 'No',
    ),
  ],
  EmployeeRecordKind.bankAccount => [
    EmployeeRecordColumn(
      'Bank name',
      (r) => r.text('bank_name_value'),
      flex: 2,
    ),
    EmployeeRecordColumn('Account number', (r) => r.text('account_number')),
    EmployeeRecordColumn('IBAN', (r) => r.text('iban'), flex: 2),
    EmployeeRecordColumn('SWIFT', (r) => r.text('swift_code')),
  ],
  EmployeeRecordKind.healthCard => [
    EmployeeRecordColumn('Type', (r) => r.text('health_card_type_name')),
    EmployeeRecordColumn(
      'Holder',
      (r) => r.text('health_card_holder_name'),
      flex: 2,
    ),
    EmployeeRecordColumn('Card number', (r) => r.text('card_number')),
    EmployeeRecordColumn(
      'Insurance company',
      (r) => r.text('insurance_company_name'),
      flex: 2,
    ),
    EmployeeRecordColumn('Expiry date', (r) => _date(r, 'expiry_date')),
  ],
  EmployeeRecordKind.payrollElement => [
    EmployeeRecordColumn('Name', (r) => r.text('name_value'), flex: 2),
    EmployeeRecordColumn('Value', (r) => _number(r, 'value')),
    EmployeeRecordColumn('Start date', (r) => _date(r, 'start_date')),
    EmployeeRecordColumn('End date', (r) => _date(r, 'end_date')),
    EmployeeRecordColumn('Note', (r) => r.text('notes'), flex: 3),
  ],
  EmployeeRecordKind.loanAdvance => [
    EmployeeRecordColumn('Type', (r) => r.text('type_name'), flex: 2),
    EmployeeRecordColumn('Deduction date', (r) => _date(r, 'deduction_date')),
    EmployeeRecordColumn('Amount', (r) => _number(r, 'total_amount')),
    EmployeeRecordColumn(
      'Monthly installment',
      (r) => _number(r, 'monthly_installment'),
    ),
    EmployeeRecordColumn('Paid to date', (r) => _number(r, 'paid_to_date')),
    EmployeeRecordColumn('Remaining', (r) => _number(r, 'remaining_amount')),
    EmployeeRecordColumn('Note', (r) => r.text('note'), flex: 2),
  ],
  EmployeeRecordKind.leave => [
    EmployeeRecordColumn(
      'Leave type',
      (r) => r.text('leave_type_name'),
      flex: 2,
    ),
    EmployeeRecordColumn('Status', (r) => r.text('status')),
    EmployeeRecordColumn('Start date', (r) => _date(r, 'start_date')),
    EmployeeRecordColumn('End date', (r) => _date(r, 'end_date')),
    EmployeeRecordColumn('Number of days', (r) => r.text('number_of_days')),
    EmployeeRecordColumn('Note', (r) => r.text('note'), flex: 3),
  ],
  EmployeeRecordKind.contactRelative => [
    EmployeeRecordColumn('Full name', (r) => r.text('full_name'), flex: 2),
    EmployeeRecordColumn('Relationship', (r) => r.text('relationship_name')),
    EmployeeRecordColumn('Phone number', (r) => r.text('phone_number')),
    EmployeeRecordColumn('Gender', (r) => r.text('gender_name')),
    EmployeeRecordColumn('Date of birth', (r) => _date(r, 'date_of_birth')),
    EmployeeRecordColumn('Nationality', (r) => r.text('nationality_name')),
    EmployeeRecordColumn(
      'Emergency',
      (r) => r.boolean('is_emergency') ? 'Yes' : 'No',
    ),
    EmployeeRecordColumn(
      'Email address',
      (r) => r.text('email_address'),
      flex: 2,
    ),
  ],
};

String emptyMessageFor(EmployeeRecordKind kind) => switch (kind) {
  EmployeeRecordKind.address => 'No address records',
  EmployeeRecordKind.nationality => 'No nationality records',
  EmployeeRecordKind.phone => 'No phone records',
  EmployeeRecordKind.socialContact => 'No social contact records',
  EmployeeRecordKind.bankAccount => 'No bank account records',
  EmployeeRecordKind.healthCard => 'No health card records',
  EmployeeRecordKind.payrollElement => 'No payroll elements for this period',
  EmployeeRecordKind.loanAdvance => 'No loan or advance records',
  EmployeeRecordKind.leave => 'No leave records',
  EmployeeRecordKind.contactRelative => 'No contacts or relatives records',
};

String labelForRecordKind(EmployeeRecordKind kind) => switch (kind) {
  EmployeeRecordKind.address => 'Address',
  EmployeeRecordKind.nationality => 'Nationality',
  EmployeeRecordKind.phone => 'Phones',
  EmployeeRecordKind.socialContact => 'Social Contacts',
  EmployeeRecordKind.bankAccount => 'Bank Accounts',
  EmployeeRecordKind.healthCard => 'Health Card',
  EmployeeRecordKind.payrollElement => 'Payroll Elements',
  EmployeeRecordKind.loanAdvance => 'Loan and Advances',
  EmployeeRecordKind.leave => 'Leaves',
  EmployeeRecordKind.contactRelative => 'Contacts & Relatives',
};

class _RecordsHeader extends StatelessWidget {
  const _RecordsHeader({required this.columns});

  final List<EmployeeRecordColumn> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43,
      color: AppColors.tableHeader,
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('ACTIONS', style: AppTextStyles.tableHeader),
              ),
            ),
          ),
          for (final column in columns)
            Expanded(
              flex: column.flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  column.label.toUpperCase(),
                  style: AppTextStyles.tableHeader,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.record,
    required this.columns,
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
  });

  final EmployeeRecord record;
  final List<EmployeeRecordColumn> columns;
  final bool deleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Delete record',
                  onPressed: deleting ? null : onDelete,
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.error,
                    hoverColor: AppColors.dangerBackground,
                  ),
                  icon: deleting
                      ? const SizedBox.square(
                          dimension: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded, size: 18),
                ),
                IconButton(
                  tooltip: 'Edit record',
                  onPressed: deleting ? null : onEdit,
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    hoverColor: AppColors.primaryLight,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
              ],
            ),
          ),
          for (final column in columns)
            Expanded(
              flex: column.flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  _display(column.value(record)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.tableBody,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _date(EmployeeRecord record, String key) {
  final date = record.date(key);
  if (date == null) return '';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _number(EmployeeRecord record, String key) {
  final number = record.number(key);
  return number == number.roundToDouble()
      ? number.toStringAsFixed(0)
      : number.toStringAsFixed(2);
}

String _display(String value) => value.trim().isEmpty ? '—' : value;
