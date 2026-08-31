double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(dynamic value) => value?.toString() ?? '';

class PayrollRunSummary {
  const PayrollRunSummary({
    required this.id,
    required this.runNumber,
    required this.payrollName,
    required this.periodName,
    required this.description,
    required this.paymentNumber,
  });

  final String id;
  final String runNumber;
  final String payrollName;
  final String periodName;
  final String description;
  final String paymentNumber;

  factory PayrollRunSummary.fromJson(Map<String, dynamic> json) {
    return PayrollRunSummary(
      id: _asString(json['_id']),
      runNumber: _asString(json['run_number']),
      payrollName: _asString(json['payroll_name']),
      periodName: _asString(json['period_name']),
      description: _asString(json['description']),
      paymentNumber: _asString(json['payment_number']),
    );
  }

  factory PayrollRunSummary.fromDetails(PayrollRunDetails details) {
    return PayrollRunSummary(
      id: details.id,
      runNumber: details.runNumber,
      payrollName: details.payrollName,
      periodName: details.periodName,
      description: details.description,
      paymentNumber: details.paymentNumber,
    );
  }
}

class PayrollRunDetails {
  const PayrollRunDetails({
    required this.id,
    required this.runNumber,
    required this.payrollName,
    required this.periodName,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.description,
    required this.paymentNumber,
    required this.employees,
  });

  final String id;
  final String runNumber;
  final String payrollName;
  final String periodName;
  final String periodStartDate;
  final String periodEndDate;
  final String description;
  final String paymentNumber;
  final List<PayrollRunEmployee> employees;

  factory PayrollRunDetails.fromJson(Map<String, dynamic> json) {
    final rawEmployees = json['employees_details'];
    return PayrollRunDetails(
      id: _asString(json['_id']),
      runNumber: _asString(json['run_number']),
      payrollName: _asString(json['payroll_name']),
      periodName: _asString(json['period_name']),
      periodStartDate: _asString(json['period_start_date']),
      periodEndDate: _asString(json['period_end_date']),
      description: _asString(json['description']),
      paymentNumber: _asString(json['payment_number']),
      employees: rawEmployees is List
          ? rawEmployees
                .whereType<Map>()
                .map(
                  (item) => PayrollRunEmployee.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }
}

class PayrollRunEmployee {
  const PayrollRunEmployee({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.employeeNumber,
    required this.bankName,
    required this.accountNumber,
    required this.iban,
    required this.swiftCode,
    required this.totalPayments,
    required this.totalDeductions,
    required this.netSalary,
    required this.payrollElements,
    required this.informationElements,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeEmail;
  final String employeeNumber;
  final String bankName;
  final String accountNumber;
  final String iban;
  final String swiftCode;
  final double totalPayments;
  final double totalDeductions;
  final double netSalary;
  final List<PayrollRunElement> payrollElements;
  final List<PayrollRunElement> informationElements;

  factory PayrollRunEmployee.fromJson(Map<String, dynamic> json) {
    List<PayrollRunElement> parseElements(dynamic source) {
      return source is List
          ? source
                .whereType<Map>()
                .map(
                  (item) => PayrollRunElement.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [];
    }

    return PayrollRunEmployee(
      id: _asString(json['_id']),
      employeeId: _asString(json['employee_id']),
      employeeName: _asString(json['employee_name']),
      employeeEmail: _asString(json['employee_email']),
      employeeNumber: _asString(json['employee_number']),
      bankName: _asString(json['bank_name']),
      accountNumber: _asString(json['account_number']),
      iban: _asString(json['iban']),
      swiftCode: _asString(json['swift_code']),
      totalPayments: _asDouble(json['total_payments']),
      totalDeductions: _asDouble(json['total_deductions']),
      netSalary: _asDouble(json['net_salary']),
      payrollElements: parseElements(json['run_employee_details']),
      informationElements: parseElements(json['run_employee_information']),
    );
  }
}

class PayrollRunElement {
  const PayrollRunElement({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.payment,
    required this.deduction,
    required this.number,
    required this.information,
  });

  final String id;
  final String name;
  final String type;
  final double value;
  final double payment;
  final double deduction;
  final double number;
  final double information;

  factory PayrollRunElement.fromJson(Map<String, dynamic> json) {
    return PayrollRunElement(
      id: _asString(json['_id']),
      name: _asString(json['element_name']),
      type: _asString(json['element_type']),
      value: _asDouble(json['value']),
      payment: _asDouble(json['payment']),
      deduction: _asDouble(json['deduction']),
      number: _asDouble(json['number']),
      information: _asDouble(json['information']),
    );
  }
}

class PayrollRunLovOption {
  const PayrollRunLovOption({required this.id, required this.label});

  final String id;
  final String label;

  factory PayrollRunLovOption.fromJson(
    Map<String, dynamic> json, {
    required String labelKey,
  }) {
    return PayrollRunLovOption(
      id: _asString(json['_id']),
      label: _asString(json[labelKey]),
    );
  }
}
