import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/payment_receipt.dart';
import '../payment/providers/payment_providers.dart';

/// Payment history — the user's receipts from `payment_receipts` with amounts,
/// dates and a link to the PDF receipt when available.
class ReceiptsScreen extends ConsumerWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userReceiptsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment history')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          debugPrint('Receipts load error: $err');
          return const Center(child: Text('Failed to load payment history'));
        },
        data: (receipts) {
          if (receipts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No purchases yet.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userReceiptsProvider),
            child: ListView.separated(
              itemCount: receipts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _ReceiptTile(receipt: receipts[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  final PaymentReceipt receipt;
  const _ReceiptTile({required this.receipt});

  Future<void> _openPdf(BuildContext context) async {
    final url = receipt.receiptPdfUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the receipt')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: const Icon(Icons.receipt_long),
      title: Text(
        '${receipt.currency} ${receipt.amountEur.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_methodLabel(receipt.paymentMethod)} · ${_formatDate(receipt.purchasedAt)}',
          ),
          Row(
            children: [
              if (receipt.receiptNumber != null)
                Text(receipt.receiptNumber!,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: Colors.grey[600])),
              const SizedBox(width: 8),
              _StatusBadge(status: receipt.status),
            ],
          ),
        ],
      ),
      trailing: receipt.receiptPdfUrl != null
          ? IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Open receipt PDF',
              onPressed: () => _openPdf(context),
            )
          : null,
      isThreeLine: true,
    );
  }

  static String _methodLabel(String method) {
    switch (method) {
      case 'google_pay':
        return 'Google Pay';
      case 'apple_pay':
        return 'Apple Pay';
      case 'revolut':
        return 'Revolut';
      case 'stripe':
        return 'Card';
      case 'comgate':
        return 'Comgate';
      case 'admin_grant':
        return 'Granted';
      default:
        return method;
    }
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'refunded':
        color = Colors.orange;
        break;
      case 'disputed':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
