import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../config.dart';
import '../services/api.dart';
import '../theme.dart';
import 'common.dart';

/// Handles "Enrol free" and "Buy now" (Razorpay) for courses, eBooks and test series.
class BuyButton extends StatefulWidget {
  final String itemType, itemId, title;
  final dynamic price;
  final bool free;
  final VoidCallback onUnlocked;
  const BuyButton({super.key, required this.itemType, required this.itemId, required this.title, required this.price, required this.free, required this.onUnlocked});
  @override
  State<BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends State<BuyButton> {
  final _rzp = Razorpay();
  final _coupon = TextEditingController();
  bool _busy = false;
  bool _showCoupon = false;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _rzp.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _rzp.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      setState(() => _busy = false);
      toast(context, r.message ?? 'Payment cancelled');
    });
    _rzp.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  @override
  void dispose() {
    _rzp.clear();
    _coupon.dispose();
    super.dispose();
  }

  bool get _isFree => widget.free || asNum(widget.price) == 0;

  Future<void> _go() async {
    setState(() => _busy = true);
    try {
      if (_isFree) {
        await Api.enrollFree(widget.itemType, widget.itemId);
        widget.onUnlocked();
        return;
      }
      final order = await Api.createOrder(widget.itemType, widget.itemId, coupon: _coupon.text.trim());
      if (order['enrolled'] == true) {
        widget.onUnlocked();
        return;
      }
      _orderId = order['orderId'] as String;
      final p = await Api.myProfile();
      _rzp.open({
        'key': order['keyId'],
        'amount': order['amount'],
        'currency': 'INR',
        'order_id': _orderId,
        'name': AppConfig.appName,
        'description': widget.title,
        'prefill': {'name': p?['full_name'] ?? '', 'email': p?['email'] ?? '', 'contact': p?['phone'] ?? ''},
        'theme': {'color': '#11302A'},
      });
    } catch (e) {
      if (mounted) toast(context, '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && _isFree) setState(() => _busy = false);
    }
  }

  Future<void> _onSuccess(PaymentSuccessResponse r) async {
    try {
      await Api.verifyPayment(orderId: r.orderId ?? _orderId!, paymentId: r.paymentId!, signature: r.signature!);
      if (mounted) toast(context, 'Payment successful — unlocked!');
      widget.onUnlocked();
    } catch (e) {
      if (mounted) toast(context, '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      if (_showCoupon && !_isFree)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(controller: _coupon, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(hintText: 'Coupon code')),
        ),
      FilledButton.icon(
        onPressed: _busy ? null : _go,
        icon: _busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ivory))
            : Icon(_isFree ? Icons.school_outlined : Icons.lock_open_rounded, size: 18),
        label: Text(_isFree ? 'Enrol for free' : 'Buy now · ${inr(asNum(widget.price))}'),
      ),
      if (!_isFree && !_showCoupon)
        TextButton(onPressed: () => setState(() => _showCoupon = true), child: const Text('Have a coupon?')),
    ]);
  }
}
