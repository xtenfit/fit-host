import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class ExternalLinks {
  static final terms = Uri.parse('https://fithost.amitrana.tech/terms');
  static final privacy = Uri.parse('https://fithost.amitrana.tech/privacy');
  static final support = Uri.parse('https://fithost.amitrana.tech/support');
}

Future<void> openExternalLink(BuildContext context, Uri uri) async {
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open the Fit Host website.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
