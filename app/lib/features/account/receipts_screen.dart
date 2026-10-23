import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/payment_receipt.dart';
import '../payment/providers/payment_providers.dart';

/// Payment history — the user's receipts from `payment_receipts`. Each receipt
/// can be opened as PDF (signed URL) or shared as an image (rendered locally).
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

String receiptMethodLabel(String method) {
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

String receiptDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class _ReceiptTile extends StatelessWidget {
  final PaymentReceipt receipt;
  const _ReceiptTile({required this.receipt});

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
          if (receipt.itemLabel != null && receipt.itemLabel!.isNotEmpty)
            Text(receipt.itemLabel!,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            '${receiptMethodLabel(receipt.paymentMethod)} · ${receiptDate(receipt.purchasedAt)}',
            style: theme.textTheme.bodySmall,
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
      trailing: const Icon(Icons.chevron_right),
      isThreeLine: true,
      onTap: () => _showReceiptSheet(context, receipt),
    );
  }
}

void _showReceiptSheet(BuildContext context, PaymentReceipt receipt) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReceiptSheet(receipt: receipt),
  );
}

class _ReceiptSheet extends StatefulWidget {
  final PaymentReceipt receipt;
  const _ReceiptSheet({required this.receipt});

  @override
  State<_ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends State<_ReceiptSheet> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  Future<void> _openPdf() async {
    final url = widget.receipt.receiptPdfUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the receipt')),
        );
      }
    }
  }

  Future<void> _shareAsImage() async {
    setState(() => _sharing = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/${widget.receipt.receiptNumber ?? 'receipt'}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)],
          subject: 'PlaceSecrets receipt');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create the image')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.receipt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _boundaryKey,
            child: _ReceiptCard(receipt: r),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (r.receiptPdfUrl != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Open PDF'),
                  ),
                ),
              if (r.receiptPdfUrl != null) const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _sharing ? null : _shareAsImage,
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.image_outlined),
                  label: const Text('Share image'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Styled receipt used for the on-device image export (full diacritics).
class _ReceiptCard extends StatelessWidget {
  final PaymentReceipt receipt;
  const _ReceiptCard({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF2D6A4F),
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PlaceSecrets',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text('Payment receipt',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Receipt no.', r.receiptNumber ?? '—'),
                _row('Date', receiptDate(r.purchasedAt)),
                _row('Item', r.itemLabel ?? '—'),
                _row('Payment method', receiptMethodLabel(r.paymentMethod)),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            color: Color(0xFF2D6A4F),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text('${r.amountEur.toStringAsFixed(2)} ${r.currency}',
                        style: const TextStyle(
                            color: Color(0xFF2D6A4F),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('PlaceSecrets — cz.tuma.placesecrets',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.w600)),
            ),
            Expanded(
                child: Text(value, style: const TextStyle(color: Colors.black87))),
          ],
        ),
      );
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
