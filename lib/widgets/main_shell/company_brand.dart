import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../models/company/company_identity_model.dart';

class CompanyBrand extends StatelessWidget {
  const CompanyBrand({required this.company, super.key});

  final CompanyIdentityModel? company;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CompanyLogo(logoUrl: company?.logoUrl ?? ''),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            company?.displayCompanyName ?? 'Your organization',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.companyName,
          ),
        ),
      ],
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo({required this.logoUrl});

  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.companyLogoSize,
      height: AppSizes.companyLogoSize,
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.companyLogo),
      ),
      child: logoUrl.isEmpty
          ? const _LogoFallback()
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.companyLogo - 2),
              child: Image.network(
                logoUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const _LogoFallback(),
              ),
            ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.primaryButton,
        borderRadius: const BorderRadius.all(Radius.circular(7)),
      ),
      child: const Icon(
        Icons.business_rounded,
        color: AppColors.surface,
        size: 21,
      ),
    );
  }
}
