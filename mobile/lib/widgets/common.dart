import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme.dart';

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
String inr(num? v) => v == null ? '' : _inr.format(v);
num asNum(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;

void toast(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

class Loading extends StatelessWidget {
  const Loading({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.brass, strokeWidth: 2.4));
}

class EmptyView extends StatelessWidget {
  final String title;
  final String? text;
  final IconData icon;
  const EmptyView({super.key, required this.title, this.text, this.icon = Icons.spa_outlined});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AppColors.brass, size: 36),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          if (text != null) ...[
            const SizedBox(height: 6),
            Text(text!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
          ],
        ]),
      );
}

/// Loads a future and renders it, with loading / error / pull-to-refresh handled.
class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext, T, Future<void> Function() reload) builder;
  const AsyncView({super.key, required this.load, required this.builder});
  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _f = widget.load();
  Future<void> reload() async {
    setState(() => _f = widget.load());
    await _f;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: _f,
        builder: (c, s) {
          if (s.connectionState != ConnectionState.done) return const Loading();
          if (s.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${s.error}'.replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: reload, child: const Text('Try again')),
                ]),
              ),
            );
          }
          return RefreshIndicator(color: AppColors.brass, onRefresh: reload, child: widget.builder(c, s.data as T, reload));
        },
      );
}

class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const Eyebrow(this.text, {super.key, this.color = AppColors.brass});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(fontSize: 10.5, letterSpacing: 2.2, fontWeight: FontWeight.w700, color: color));
}

class SectionHeader extends StatelessWidget {
  final String eyebrow, title;
  final VoidCallback? onMore;
  const SectionHeader({super.key, required this.eyebrow, required this.title, this.onMore});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 12, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Eyebrow(eyebrow),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
            ]),
          ),
          if (onMore != null) TextButton(onPressed: onMore, child: const Text('See all')),
        ]),
      );
}

class PriceTag extends StatelessWidget {
  final dynamic price, mrp;
  final bool free;
  const PriceTag({super.key, required this.price, this.mrp, this.free = false});
  @override
  Widget build(BuildContext context) {
    final p = asNum(price), m = mrp == null ? null : asNum(mrp);
    if (free || p == 0) {
      return const Text('Free', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.forest, fontSize: 16));
    }
    final off = (m != null && m > p) ? ((m - p) / m * 100).round() : 0;
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
      Text(inr(p), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.forest, fontSize: 16)),
      if (off > 0) Text(inr(m), style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppColors.inkMute, fontSize: 12.5)),
      if (off > 0) Text('$off% off', style: const TextStyle(color: AppColors.clay, fontWeight: FontWeight.w700, fontSize: 12)),
    ]);
  }
}

/// A cover image, or an original generated cover when none was uploaded.
class Cover extends StatelessWidget {
  final String? url;
  final String title;
  final Color tone;
  final IconData icon;
  const Cover({super.key, this.url, required this.title, this.tone = AppColors.forest, this.icon = Icons.auto_awesome});
  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return Image.network(url!, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
          errorBuilder: (_, __, ___) => _generated());
    }
    return _generated();
  }

  Widget _generated() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [tone, Color.lerp(tone, Colors.black, .45)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        padding: const EdgeInsets.all(14),
        child: Stack(children: [
          Positioned(right: -6, top: -6, child: CustomPaint(size: const Size(70, 70), painter: PetalPainter(opacity: .18))),
          Icon(icon, color: AppColors.brassLight, size: 20),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(title, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.ivory, fontWeight: FontWeight.w600, fontSize: 15, height: 1.25)),
          ),
        ]),
      );
}

/// Original petal-ring motif used across the brand.
class PetalPainter extends CustomPainter {
  final double opacity;
  final Color color;
  PetalPainter({this.opacity = .5, this.color = AppColors.brassLight});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withOpacity(opacity);
    final c = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    for (var i = 0; i < 12; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 12);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: size.width * .24, height: size.height * .95), p);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Brand emblem: deep green disc with a three-leaf sprout and an H monogram.
class Emblem extends StatelessWidget {
  final double size;
  const Emblem({super.key, this.size = 40});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _EmblemPainter());
}

class _EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 48;
    canvas.scale(k);
    canvas.drawCircle(const Offset(24, 24), 23, Paint()..color = AppColors.forest);
    canvas.drawCircle(const Offset(24, 24), 20.5,
        Paint()..style = PaintingStyle.stroke..strokeWidth = .8..color = const Color(0xFFD2AA62));
    final leaf = Path()
      ..moveTo(24, 13)
      ..cubicTo(20.8, 16, 20.8, 20.6, 24, 23.6)
      ..cubicTo(27.2, 20.6, 27.2, 16, 24, 13);
    canvas.drawPath(leaf, Paint()..color = const Color(0xFFD2AA62));
    final l = Path()
      ..moveTo(14.5, 18.5)
      ..cubicTo(15.5, 22.8, 19.1, 25.5, 23.5, 25.1)
      ..cubicTo(22.5, 20.8, 18.9, 18.1, 14.5, 18.5);
    final r = Path()
      ..moveTo(33.5, 18.5)
      ..cubicTo(32.5, 22.8, 28.9, 25.5, 24.5, 25.1)
      ..cubicTo(25.5, 20.8, 29.1, 18.1, 33.5, 18.5);
    canvas.drawPath(l, Paint()..color = AppColors.brass);
    canvas.drawPath(r, Paint()..color = AppColors.brass);
    final h = Paint()
      ..color = AppColors.ivory
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(18, 27), const Offset(18, 37), h);
    canvas.drawLine(const Offset(30, 27), const Offset(30, 37), h);
    canvas.drawLine(const Offset(18, 32), const Offset(30, 32), h);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BrandTitle extends StatelessWidget {
  final bool light;
  const BrandTitle({super.key, this.light = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        const Emblem(size: 34),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Harshwardhan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: light ? AppColors.ivory : AppColors.forest, fontSize: 17)),
          Eyebrow('Institute of Ayurveda', color: light ? AppColors.brassLight : AppColors.brass),
        ]),
      ]);
}

class Pill extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const Pill(this.text, {super.key, this.bg = AppColors.forestSoft, this.fg = AppColors.forest});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
      );
}
