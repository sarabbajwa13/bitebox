import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';
import 'common.dart';

/// Footer with links to the legal/policy pages (static HTML hosted alongside
/// the app). Payment gateways require these to be reachable from the site.
class PolicyFooter extends StatelessWidget {
  const PolicyFooter({super.key});

  static const _links = <_PolicyLink>[
    _PolicyLink('Terms & Conditions', 'terms.html'),
    _PolicyLink('Privacy Policy', 'privacy.html'),
    _PolicyLink('Cancellation & Refund', 'refund.html'),
    _PolicyLink('Contact Us', 'contact.html'),
  ];

  Future<void> _open(String file) async {
    // App root ke relative — biteboxa.web.app/<file>.
    final uri = Uri.base.resolve(file);
    await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return MaxWidth(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          children: [
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: 6,
              children: [
                for (final link in _links)
                  InkWell(
                    onTap: () => _open(link.file),
                    child: Text(
                      link.label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '© ${DateTime.now().year} BiteBox',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyLink {
  final String label;
  final String file;
  const _PolicyLink(this.label, this.file);
}
