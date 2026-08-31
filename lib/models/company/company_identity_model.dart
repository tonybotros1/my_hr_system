class CompanyIdentityModel {
  const CompanyIdentityModel({
    required this.userId,
    required this.userName,
    required this.email,
    required this.companyName,
    required this.logoUrl,
  });

  final String userId;
  final String userName;
  final String email;
  final String companyName;
  final String logoUrl;

  factory CompanyIdentityModel.fromEnvelope(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Missing company details');
    }

    return CompanyIdentityModel(
      userId: data['_id']?.toString() ?? '',
      userName: data['user_name']?.toString().trim() ?? '',
      email: data['email']?.toString().trim() ?? '',
      companyName: data['company_name']?.toString().trim() ?? '',
      logoUrl: data['company_logo']?.toString().trim() ?? '',
    );
  }

  String get displayCompanyName =>
      companyName.isEmpty ? 'Your organization' : companyName;

  String get displayUserName => userName.isEmpty ? email : userName;

  String get userInitials {
    final source = displayUserName.trim();
    if (source.isEmpty) return 'U';
    final words = source
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}
