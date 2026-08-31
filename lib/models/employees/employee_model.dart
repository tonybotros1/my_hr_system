enum EmployeeRecordKind {
  address,
  nationality,
  phone,
  socialContact,
  bankAccount,
  healthCard,
  payrollElement,
  loanAdvance,
  leave,
  contactRelative,
}

String employeeString(dynamic value) => value?.toString() ?? '';

DateTime? employeeDate(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

double employeeNumber(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class EmployeeSummary {
  const EmployeeSummary({
    required this.id,
    required this.fullName,
    required this.personType,
    required this.employerId,
    required this.employerName,
    required this.departmentId,
    required this.departmentName,
    required this.jobTitleId,
    required this.jobTitleName,
    required this.locationId,
    required this.locationName,
    this.hireDate,
    this.endDate,
  });

  final String id;
  final String fullName;
  final String personType;
  final String employerId;
  final String employerName;
  final String departmentId;
  final String departmentName;
  final String jobTitleId;
  final String jobTitleName;
  final String locationId;
  final String locationName;
  final DateTime? hireDate;
  final DateTime? endDate;

  factory EmployeeSummary.fromJson(Map<String, dynamic> json) {
    final hireDate = employeeDate(json['hire_date']);
    final endDate = employeeDate(json['end_date']);
    final suppliedType = employeeString(json['person_type']).trim();
    return EmployeeSummary(
      id: employeeString(json['_id']),
      fullName: employeeString(json['full_name']),
      personType: suppliedType.isEmpty
          ? deriveEmployeeType(hireDate: hireDate, endDate: endDate)
          : suppliedType,
      employerId: employeeString(json['employer']),
      employerName: employeeString(json['employer_name']),
      departmentId: employeeString(json['department']),
      departmentName: employeeString(json['department_name']),
      jobTitleId: employeeString(json['job_title']),
      jobTitleName: employeeString(json['job_title_name']),
      locationId: employeeString(json['location']),
      locationName: employeeString(json['location_name']),
      hireDate: hireDate,
      endDate: endDate,
    );
  }
}

class EmployeeDetails extends EmployeeSummary {
  const EmployeeDetails({
    required super.id,
    required super.fullName,
    required super.personType,
    required super.employerId,
    required super.employerName,
    required super.departmentId,
    required super.departmentName,
    required super.jobTitleId,
    required super.jobTitleName,
    required super.locationId,
    required super.locationName,
    super.hireDate,
    super.endDate,
    required this.countryOfBirthId,
    required this.countryOfBirthName,
    required this.placeOfBirth,
    required this.genderId,
    required this.genderName,
    required this.maritalStatusId,
    required this.maritalStatusName,
    required this.legislationId,
    required this.legislationName,
    required this.reportingManagerId,
    required this.reportingManagerName,
    required this.payrollId,
    required this.payrollName,
    required this.imageUrl,
    this.dateOfBirth,
    this.addresses = const [],
    this.nationalities = const [],
    this.phones = const [],
    this.socialContacts = const [],
    this.bankAccounts = const [],
    this.healthCards = const [],
    this.payrollElements = const [],
    this.loanAdvances = const [],
    this.assignmentBalances = const [],
  });

  final String countryOfBirthId;
  final String countryOfBirthName;
  final String placeOfBirth;
  final DateTime? dateOfBirth;
  final String genderId;
  final String genderName;
  final String maritalStatusId;
  final String maritalStatusName;
  final String legislationId;
  final String legislationName;
  final String reportingManagerId;
  final String reportingManagerName;
  final String payrollId;
  final String payrollName;
  final String imageUrl;
  final List<EmployeeRecord> addresses;
  final List<EmployeeRecord> nationalities;
  final List<EmployeeRecord> phones;
  final List<EmployeeRecord> socialContacts;
  final List<EmployeeRecord> bankAccounts;
  final List<EmployeeRecord> healthCards;
  final List<EmployeeRecord> payrollElements;
  final List<EmployeeRecord> loanAdvances;
  final List<EmployeeRecord> assignmentBalances;

  factory EmployeeDetails.fromJson(Map<String, dynamic> json) {
    final summary = EmployeeSummary.fromJson(json);
    return EmployeeDetails(
      id: summary.id,
      fullName: summary.fullName,
      personType: summary.personType,
      employerId: summary.employerId,
      employerName: summary.employerName,
      departmentId: summary.departmentId,
      departmentName: summary.departmentName,
      jobTitleId: summary.jobTitleId,
      jobTitleName: summary.jobTitleName,
      locationId: summary.locationId,
      locationName: summary.locationName,
      hireDate: summary.hireDate,
      endDate: summary.endDate,
      countryOfBirthId: employeeString(json['country_of_birth']),
      countryOfBirthName: employeeString(json['country_of_birth_name']),
      placeOfBirth: employeeString(json['place_of_birth']),
      dateOfBirth: employeeDate(json['date_of_birth']),
      genderId: employeeString(json['gender']),
      genderName: employeeString(json['gender_name']),
      maritalStatusId: employeeString(json['martial_status']),
      maritalStatusName: employeeString(json['martial_status_name']),
      legislationId: employeeString(json['legislation']),
      legislationName: employeeString(json['legislation_name']),
      reportingManagerId: employeeString(json['reporting_manager']),
      reportingManagerName: employeeString(json['reporting_manager_name']),
      payrollId: employeeString(json['payroll']),
      payrollName: employeeString(json['payroll_name']),
      imageUrl: employeeString(json['person_image_url']),
      addresses: EmployeeRecord.list(json['addresses_list']),
      nationalities: EmployeeRecord.list(json['nationalities_list']),
      phones: EmployeeRecord.list(json['phone_list']),
      socialContacts: EmployeeRecord.list(json['email_list']),
      bankAccounts: EmployeeRecord.list(json['bank_accounts_list']),
      healthCards: EmployeeRecord.list(
        json['health_cards_list'] ?? json['health_card_list'],
      ),
      payrollElements: EmployeeRecord.list(json['payrolls_details']),
      loanAdvances: EmployeeRecord.list(json['loan_and_advances_details']),
      assignmentBalances: EmployeeRecord.list(json['assignment_balances']),
    );
  }

  List<EmployeeRecord> recordsFor(EmployeeRecordKind kind) => switch (kind) {
    EmployeeRecordKind.address => addresses,
    EmployeeRecordKind.nationality => nationalities,
    EmployeeRecordKind.phone => phones,
    EmployeeRecordKind.socialContact => socialContacts,
    EmployeeRecordKind.bankAccount => bankAccounts,
    EmployeeRecordKind.healthCard => healthCards,
    EmployeeRecordKind.payrollElement => payrollElements,
    EmployeeRecordKind.loanAdvance => loanAdvances,
    EmployeeRecordKind.leave || EmployeeRecordKind.contactRelative => const [],
  };
}

class EmployeeRecord {
  const EmployeeRecord(this.data);

  final Map<String, dynamic> data;

  String get id => employeeString(data['_id']);
  String text(String key) => employeeString(data[key]);
  bool boolean(String key) => data[key] == true;
  double number(String key) => employeeNumber(data[key]);
  DateTime? date(String key) => employeeDate(data[key]);

  static List<EmployeeRecord> list(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((entry) => EmployeeRecord(Map<String, dynamic>.from(entry)))
        .toList(growable: false);
  }
}

class EmployeeAttachment {
  const EmployeeAttachment({
    required this.id,
    required this.name,
    required this.typeId,
    required this.typeName,
    required this.number,
    required this.note,
    required this.files,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String name;
  final String typeId;
  final String typeName;
  final String number;
  final String note;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<EmployeeAttachmentFile> files;

  factory EmployeeAttachment.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['attachments'];
    return EmployeeAttachment(
      id: employeeString(json['_id']),
      name: employeeString(json['name']),
      typeId: employeeString(json['attachment_type']),
      typeName: employeeString(json['attachment_type_name']),
      number: employeeString(json['number']),
      note: employeeString(json['note']),
      startDate: employeeDate(json['start_date']),
      endDate: employeeDate(json['end_date']),
      files: rawFiles is List
          ? rawFiles
                .whereType<Map>()
                .map(
                  (file) => EmployeeAttachmentFile.fromJson(
                    Map<String, dynamic>.from(file),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  static List<EmployeeAttachment> list(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (entry) =>
              EmployeeAttachment.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList(growable: false);
  }
}

class EmployeeAttachmentFile {
  const EmployeeAttachmentFile({
    required this.name,
    required this.url,
    required this.resourceType,
    required this.format,
  });

  final String name;
  final String url;
  final String resourceType;
  final String format;

  factory EmployeeAttachmentFile.fromJson(Map<String, dynamic> json) =>
      EmployeeAttachmentFile(
        name: employeeString(json['file_name']),
        url: employeeString(json['attach_url']),
        resourceType: employeeString(json['resource_type']),
        format: employeeString(json['format']),
      );
}

String deriveEmployeeType({DateTime? hireDate, DateTime? endDate}) {
  if (hireDate == null) return endDate == null ? 'Applicant' : 'Ex-Applicant';
  return endDate == null ? 'Employee' : 'Ex-Employee';
}
