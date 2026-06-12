import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/services/payment_service.dart';
import '../../domain/models/city.dart';
import '../../domain/models/payment_config.dart';
import '../map/providers/map_providers.dart';
import 'providers/payment_providers.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  final String cityId;

  const PaywallScreen({super.key, required this.cityId});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(paymentConfigProvider);
    final citiesAsync = ref.watch(activeCitiesProvider);
    final paymentState = ref.watch(paymentFlowStateProvider);
    final theme = Theme.of(context);

    final city = citiesAsync.valueOrNull
        ?.where((c) => c.id == widget.cityId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Unlock City')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            Icon(
              Icons.lock_open,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),

            Text(
              city != null ? 'Unlock ${city.name}' : 'Unlock City',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            if (city != null)
              Text(
                '${city.priceEur.toStringAsFixed(2)} EUR',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            const SizedBox(height: 8),

            Text(
              'Get full access to all audio guides and detailed information for every point of interest in the city.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            if (paymentState.status == PaymentStatus.error)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  paymentState.error ?? 'Payment failed',
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),

            if (paymentState.status == PaymentStatus.success) ...[
              Icon(Icons.check_circle, size: 48, color: Colors.green.shade700),
              const SizedBox(height: 8),
              const Text('Payment successful!'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Return to Map'),
              ),
            ] else
              configAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Could not load payment config: $e'),
                data: (config) =>
                    _buildPaymentButtons(city, config, theme),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButtons(
      City? city, PaymentConfig? config, ThemeData theme) {
    if (config == null || city == null) {
      return const Text('Payment not available');
    }

    final service = ref.read(paymentServiceProvider);
    final methods = service.availableMethods;

    return Column(
      children: [
        if (methods.contains(PaymentMethod.googlePay))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _processing ? null : () => _pay(city, config, PaymentMethod.googlePay),
                icon: const Icon(Icons.payment),
                label: const Text('Pay with Google Pay'),
              ),
            ),
          ),

        if (methods.contains(PaymentMethod.applePay))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _processing ? null : () => _pay(city, config, PaymentMethod.applePay),
                icon: const Icon(Icons.apple),
                label: const Text('Pay with Apple Pay'),
              ),
            ),
          ),

        if (methods.contains(PaymentMethod.revolut) &&
            config.revolutUsername != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  _processing ? null : () => _pay(city, config, PaymentMethod.revolut),
              icon: const Icon(Icons.account_balance),
              label: const Text('Pay with Revolut'),
            ),
          ),

        if (_processing)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Future<void> _pay(
      City city, PaymentConfig config, PaymentMethod method) async {
    setState(() => _processing = true);
    ref
        .read(paymentFlowStateProvider.notifier)
        .startPayment(city.id, method);

    final service = ref.read(paymentServiceProvider);
    final result = await service.pay(
      cityId: city.id,
      amountEur: city.priceEur,
      cityName: city.name,
      method: method,
      config: config,
    );

    if (result.success) {
      ref
          .read(paymentFlowStateProvider.notifier)
          .setSuccess(result.transactionId);
      ref.invalidate(hasCityAccessProvider(city.id));
      ref.invalidate(userPurchasesProvider);
    } else {
      ref
          .read(paymentFlowStateProvider.notifier)
          .setError(result.error ?? 'Payment failed');
    }

    setState(() => _processing = false);
  }
}
