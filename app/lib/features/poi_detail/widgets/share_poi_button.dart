import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/models/poi.dart';

class SharePoiButton extends StatelessWidget {
  final Poi poi;

  const SharePoiButton({super.key, required this.poi});

  @override
  Widget build(BuildContext context) {
    final smartUri = poi.smartUri;
    if (smartUri == null) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.share),
      tooltip: 'Share',
      onPressed: () {
        final langCode = Localizations.localeOf(context).languageCode;
        final name = poi.localizedName(langCode);
        final url = 'https://placesecrets.app$smartUri';
        Share.share('$name\n$url');
      },
    );
  }
}
