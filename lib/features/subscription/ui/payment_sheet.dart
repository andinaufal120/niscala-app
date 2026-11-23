import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/features/subscription/subscription_labels.dart';
import 'package:niscala/features/subscription/subscription_payment_controller.dart';

/// The sheet that shows a payment: the verification in progress, then the
/// outcome and the next step. Its content follows [subscriptionPaymentProvider].
class PaymentSheet extends ConsumerWidget {
  const PaymentSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionPaymentProvider);
    final controller = ref.read(subscriptionPaymentProvider.notifier);
    final theme = Theme.of(context);
    final order = state.order;

    void closeThen(VoidCallback next) {
      Navigator.of(context).pop();
      next();
    }

    void close() => closeThen(controller.dismiss);

    // A verification keeps this sheet open, as its busy state is shown here.
    // The other steps start a new purchase, so the sheet closes first.
    void retry() {
      if (state.retry == PaymentStep.verify) {
        controller.retry();
      } else {
        closeThen(controller.retry);
      }
    }

    final closeButton = OutlinedButton(
      onPressed: close,
      child: const Text('Tutup'),
    );
    final (title, body, actions) = switch (state.phase) {
      PaymentPhase.idle || PaymentPhase.paying => ('', null, const <Widget>[]),
      PaymentPhase.verifying => (
        'Memverifikasi pembayaran',
        null,
        const <Widget>[],
      ),
      PaymentPhase.pending => (
        'Menunggu pembayaran',
        'Selesaikan pembayaran Anda. Paket aktif setelah pembayaran diterima.',
        [
          FilledButton(
            onPressed: controller.verify,
            child: const Text('Cek lagi'),
          ),
          closeButton,
        ],
      ),
      PaymentPhase.succeeded => (
        'Pembayaran berhasil',
        'Paket ${planName(order!.planCode.value)} sekarang aktif.',
        [FilledButton(onPressed: close, child: const Text('Selesai'))],
      ),
      PaymentPhase.failed => (
        'Pembayaran gagal',
        'Paket tidak berubah. Anda bisa mencoba membayar lagi.',
        [
          FilledButton(
            onPressed: () => closeThen(controller.payAgain),
            child: const Text('Bayar lagi'),
          ),
          closeButton,
        ],
      ),
      PaymentPhase.expired => (
        'Pesanan kedaluwarsa',
        'Buat pesanan baru untuk membayar.',
        [
          FilledButton(
            onPressed: () => closeThen(controller.payAgain),
            child: const Text('Bayar lagi'),
          ),
          closeButton,
        ],
      ),
      PaymentPhase.canceled => (
        'Pembelian dibatalkan',
        'Paket tidak berubah.',
        [closeButton],
      ),
      PaymentPhase.error => (
        'Pembayaran belum bisa diselesaikan',
        state.message,
        [
          FilledButton(onPressed: retry, child: const Text('Coba lagi')),
          closeButton,
        ],
      ),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && state.phase != PaymentPhase.verifying) close();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          NiscalaSpacing.gutter,
          NiscalaSpacing.l,
          NiscalaSpacing.gutter,
          NiscalaSpacing.l,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
              if (state.phase == PaymentPhase.verifying) ...[
                formGap,
                const Center(
                  child: CircularProgressIndicator(semanticsLabel: 'Memproses'),
                ),
              ],
              if (body != null) ...[formGap, Text(body)],
              for (final action in actions) ...[formGap, action],
            ],
          ),
        ),
      ),
    );
  }
}
