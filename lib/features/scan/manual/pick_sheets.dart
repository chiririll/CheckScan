import 'package:flutter/material.dart';

import '../../../core/catalog/model/catalog_product.dart';
import '../../../core/merchant/merchant.dart';
import '../../../core/util/collections.dart';

/// Searchable product list; resolves to the picked product.
Future<CatalogProduct?> pickProduct(BuildContext context, List<CatalogProduct> products, {required String hint}) {
  return showModalBottomSheet<CatalogProduct>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ProductPicker(products: products, hint: hint),
  );
}

/// Known merchants; resolves to the picked merchant's name.
Future<String?> pickMerchantName(BuildContext context, List<Merchant> merchants) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final merchant in merchants)
            ListTile(title: Text(merchant.name), onTap: () => Navigator.pop(context, merchant.name)),
        ],
      ),
    ),
  );
}

class _ProductPicker extends StatefulWidget {
  const _ProductPicker({required this.products, required this.hint});

  final List<CatalogProduct> products;
  final String hint;

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final shown = filterByQuery(widget.products, _query, (product) => [product.name]);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(hintText: widget.hint, border: const OutlineInputBorder()),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final product in shown)
                    ListTile(title: Text(product.name), onTap: () => Navigator.pop(context, product)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
