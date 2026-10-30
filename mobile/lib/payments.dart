import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';

class ServiceInvoiceScreen extends StatefulWidget {
  final int requestId;
  const ServiceInvoiceScreen({super.key, required this.requestId});
  @override
  State<ServiceInvoiceScreen> createState() => _ServiceInvoiceScreenState();
}

class _ServiceInvoiceScreenState extends State<ServiceInvoiceScreen> {
  Map<String, dynamic>? invoice;
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await api.request(
        '/service-requests/${widget.requestId}/invoice',
      );
      if (mounted) {
        setState(() {
          invoice = data == null ? null : Map<String, dynamic>.from(data);
          loading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '$e';
          loading = false;
        });
      }
    }
  }

  String money(dynamic value) =>
      '${invoice!['currency']} ${(value as num).toStringAsFixed(2)}';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Invoice & payments')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                if (error != null) ...[
                  Text(error!, style: const TextStyle(color: Colors.red)),
                  TextButton(onPressed: load, child: const Text('Try again')),
                ] else if (invoice == null) ...[
                  Icon(Icons.receipt_long_outlined, size: 64, color: brandNavy),
                  const SizedBox(height: 24),
                  const Text(
                    'Your invoice will appear here.',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The service team will confirm the work and agreed total before issuing an invoice.',
                  ),
                ] else ...[
                  Text(
                    'INV-${invoice!['id'].toString().padLeft(6, '0')} · REQUEST #${widget.requestId}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: muted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: brandNavy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${invoice!['status']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          money(invoice!['balance']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Outstanding balance',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total\n${money(invoice!['total'])}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Paid\n${money(invoice!['paid'])}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if ((invoice!['notes'] as String).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(invoice!['notes']),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Payment receipts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if ((invoice!['payments'] as List).isEmpty)
                    const Text(
                      'No payments have been recorded.',
                      style: TextStyle(color: muted),
                    ),
                  ...(invoice!['payments'] as List).map(
                    (payment) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${payment['method']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  money(payment['amount']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'PAY-${payment['id'].toString().padLeft(6, '0')} · ${localTime(payment['receivedUtc'])}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: muted,
                              ),
                            ),
                            if ((payment['reference'] as String).isNotEmpty)
                              Text(
                                payment['reference'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Payments are confirmed by the service team after receipt. Contact CTC DALBO to arrange payment or ask about a transaction. No money is charged from this screen.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
  );
}
