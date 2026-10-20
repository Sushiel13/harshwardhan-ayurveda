import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/buy_button.dart';
import '../../widgets/common.dart';

class EbookScreen extends StatefulWidget {
  final Json ebook;
  const EbookScreen({super.key, required this.ebook});
  @override
  State<EbookScreen> createState() => _EbookScreenState();
}

class _EbookScreenState extends State<EbookScreen> {
  Json get e => widget.ebook;
  late Future<bool> _owned = _check();
  Future<bool> _check() async => await Api.owns('ebook', e['id']) || (await Api.hasAccess('ebook', e['id']) && e['is_free'] != true);

  Future<void> _read() async {
    if (e['file_path'] == null) return toast(context, 'File not uploaded yet.');
    try {
      final url = await Api.signedUrl(e['file_path'], seconds: 1800);
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      if (mounted) toast(context, 'Purchase this eBook to read it.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Center(
            child: SizedBox(
              width: 180,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Cover(url: e['cover_url'], title: e['title'], tone: AppColors.clay, icon: Icons.menu_book)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(e['title'], style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          if (e['author'] != null) Text(e['author'], textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkMute)),
          const SizedBox(height: 16),
          Text(e['description'] ?? '', style: const TextStyle(color: AppColors.inkSoft, height: 1.5)),
          const SizedBox(height: 24),
          FutureBuilder<bool>(
            future: _owned,
            builder: (_, s) {
              if (!s.hasData) return const Loading();
              if (s.data!) return FilledButton.icon(onPressed: _read, icon: const Icon(Icons.chrome_reader_mode_outlined), label: const Text('Read eBook'));
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(child: PriceTag(price: e['price'], mrp: e['mrp'], free: e['is_free'] == true)),
                const SizedBox(height: 12),
                BuyButton(itemType: 'ebook', itemId: e['id'], title: e['title'], price: e['price'], free: e['is_free'] == true,
                    onUnlocked: () => setState(() => _owned = _check())),
              ]);
            },
          ),
        ]),
      );
}
