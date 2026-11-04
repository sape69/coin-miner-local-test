
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../localization.dart';

class StellaFooter extends StatelessWidget {
  final AppLocalizations localization;
  final String languageCode;
  final String appVersion;
  final String buildNumber;
  final bool privacyOptionsRequired;
  final VoidCallback onPrivacyOptions;

  const StellaFooter({
    super.key,
    required this.localization,
    required this.languageCode,
    required this.appVersion,
    required this.buildNumber,
    required this.privacyOptionsRequired,
    required this.onPrivacyOptions,
  });

  static const Color accentColor =
      Color(0xFFB58CFF);

  static const Color secondaryTextColor =
      Color(0xFFBDB4D1);

  static const String contactEmail =
      'stelluriini.app@gmail.com';

  static final Uri facebookUrl = Uri.parse(
    'https://www.facebook.com/share/1CSyTzCLb4/',
  );

  String _privacyOptionsLabel() {
    switch (languageCode) {
      case 'fi':
        return 'Tietosuoja-asetukset';

      case 'de':
        return 'Datenschutzeinstellungen';

      case 'es':
        return 'Opciones de privacidad';

      case 'fr':
        return 'Options de confidentialité';

      case 'zh':
        return '隐私选项';

      case 'vi':
        return 'Tùy chọn quyền riêng tư';

      case 'ja':
        return 'プライバシー設定';

      case 'en':
      default:
        return 'Privacy options';
    }
  }

  String _facebookLabel() {
    switch (languageCode) {
      case 'fi':
        return 'Seuraa meitä Facebookissa';

      case 'de':
        return 'Folge uns auf Facebook';

      case 'es':
        return 'Síguenos en Facebook';

      case 'fr':
        return 'Suivez-nous sur Facebook';

      case 'zh':
        return '在 Facebook 上关注我们';

      case 'vi':
        return 'Theo dõi chúng tôi trên Facebook';

      case 'ja':
        return 'Facebookでフォロー';

      case 'en':
      default:
        return 'Follow us on Facebook';
    }
  }

  Future<void> _openFacebook() async {
    try {
      await launchUrl(
        facebookUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Facebook-linkin avaaminen epäonnistui.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 18,
      ),
      child: Column(
        children: [
          const Text(
            '🐱💜⛏️',
            style: TextStyle(
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localization.get(
              'footerMiningFuture',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'STELLURIINI • STL',
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          if (appVersion.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              buildNumber.isNotEmpty
                  ? '${localization.get('appVersion')} '
                    '$appVersion '
                    '(build $buildNumber)'
                  : '${localization.get('appVersion')} '
                    '$appVersion',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const SelectableText(
            contactEmail,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),

          // ==================================================
          // FACEBOOK
          // ==================================================

          const SizedBox(height: 14),
          InkWell(
            onTap: _openFacebook,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.facebook,
                    size: 34,
                    color: accentColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _facebookLabel(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==================================================
          // PRIVACY OPTIONS
          // ==================================================

          if (privacyOptionsRequired) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onPrivacyOptions,
              icon: const Icon(
                Icons.privacy_tip_outlined,
                size: 18,
              ),
              label: Text(
                _privacyOptionsLabel(),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(
                  color: accentColor.withValues(
                    alpha: 0.45,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
