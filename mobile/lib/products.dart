import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'branding.dart';

class ProductCatalog extends StatefulWidget {
  const ProductCatalog({super.key});
  @override
  State<ProductCatalog> createState() => _ProductCatalogState();
}

class _ProductCatalogState extends State<ProductCatalog> {
  List<dynamic>? products;
  String? error;
  String query = '';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      await refreshBrand();
      final data = await api.request('/products');
      if (mounted) {
        setState(() {
          products = data;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: load,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Products', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Discover products from ${appBrand.value.name}.'),
        const SizedBox(height: 20),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search products',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => query = v.toLowerCase()),
        ),
        const SizedBox(height: 20),
        if (error != null) ...[
          Text(error!),
          TextButton(onPressed: load, child: const Text('Try again')),
        ] else if (products == null)
          const Center(child: CircularProgressIndicator())
        else if (products!.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No products available yet.'),
          )
        else
          ...products!
              .where(
                (p) => '${p['name']} ${p['category']}'.toLowerCase().contains(
                  query,
                ),
              )
              .map(
                (p) => Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p['imageUrl'] != null)
                          Image.network(
                            '${Api.base}${p['imageUrl']}',
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.inventory_2_outlined,
                              size: 50,
                            ),
                          ),
                        Text(
                          p['category'] ?? '',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          p['name'],
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(p['description'] ?? ''),
                        const SizedBox(height: 14),
                        Text(
                          '${appBrand.value.currency} ${(p['price'] as num).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          (p['stock'] as num) > 0
                              ? '${p['stock']} available'
                              : 'Currently out of stock',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    ),
  );
}

class AdminLinkPage extends StatelessWidget {
  const AdminLinkPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Administration')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage your brand, products, services and users on the administration website. Sign in with your administrator email.',
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              final ok = await launchUrl(
                Uri.parse('${Api.base}/Manage/Settings'),
                mode: LaunchMode.externalApplication,
              );
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unable to open the website.')),
                );
              }
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    ),
  );
}
