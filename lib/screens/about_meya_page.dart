import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../legal/meya_legal.dart';
import '../theme/meya_theme.dart';
import '../l10n/meya_strings.dart';

/// What MEYA is, with its privacy policy, terms, accessibility statement and
/// open-source licences.
class AboutMeyaPage extends StatefulWidget {
  const AboutMeyaPage({super.key});

  @override
  State<AboutMeyaPage> createState() => _AboutMeyaPageState();
}

class _AboutMeyaPageState extends State<AboutMeyaPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    }).catchError((Object _) {});
  }

  void _open(String title, List<LegalSection> sections) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LegalTextPage(title: title, sections: sections),
      ),
    );
  }

  Future<void> _openWebsite() async {
    final opened = await launchUrl(
      Uri.parse(meyaWebsite),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('No browser could open the website.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('About MEYA'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: colors.navy,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: ExcludeSemantics(
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: colors.onNavy,
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'MEYA',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            if (_version.isNotEmpty)
              Center(
                child: Text(
                  context.tr('Version {0}', [_version]),
                  style: TextStyle(color: colors.muted),
                ),
              ),
            const SizedBox(height: 20),
            Text(meyaDescription, style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 12),
            Text(
              context.tr('Developed by {0}, {1}.', [meyaCompany, meyaCompanyAddress]),
              style: TextStyle(color: colors.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(context.tr('Privacy policy')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context.tr('Privacy policy'), privacyPolicy),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.gavel_outlined),
                    title: Text(context.tr('Terms of use')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context.tr('Terms of use'), termsOfUse),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.accessibility_new_outlined),
                    title: Text(context.tr('Accessibility')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context.tr('Accessibility'), accessibilityStatement),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(context.tr('Open-source licences')),
                    subtitle: Text(context.tr('MEYA is licensed under AGPL-3.0-only')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'MEYA',
                      applicationVersion: _version,
                      applicationLegalese: context.tr('© 2026 {0} · AGPL-3.0-only', [meyaCompany]),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.public),
                    title: Text(context.tr('Website')),
                    subtitle: Text(meyaWebsite.replaceFirst('https://', '').replaceFirst(RegExp(r'/$'), '')),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: _openWebsite,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalTextPage extends StatelessWidget {
  final String title;
  final List<LegalSection> sections;

  const LegalTextPage({super.key, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            if (!Localizations.localeOf(context).languageCode.startsWith('en'))
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  context.tr('This text is available in English only for now.'),
                  style: TextStyle(color: context.meya.muted),
                ),
              ),
            for (final section in sections) ...[
              Semantics(
                header: true,
                child: Text(
                  section.heading,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              Text(section.body, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
