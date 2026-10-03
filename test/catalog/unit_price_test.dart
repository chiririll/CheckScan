import 'package:checkscan/core/catalog/model/catalog_position.dart';
import 'package:checkscan/core/catalog/model/item_unit.dart';
import 'package:checkscan/core/catalog/pricing/reference_pack.dart';
import 'package:checkscan/core/catalog/pricing/unit_price.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts grams and millilitres into ₽/кг and ₽/л', () {
    expect(
      pricePerUnit(packPrice: 50, productUnit: ItemUnit.g, unitSize: 300, itemUnit: ItemUnit.g),
      closeTo(50 / 0.3, 0.0001),
    );
    expect(
      pricePerUnit(packPrice: 150, productUnit: ItemUnit.l, unitSize: 1.75, itemUnit: ItemUnit.l),
      closeTo(150 / 1.75, 0.0001),
    );
    expect(
      pricePerUnit(packPrice: 80, productUnit: ItemUnit.l, unitSize: 1750, itemUnit: ItemUnit.ml),
      closeTo(80 / 1.75, 0.0001),
    );
  });

  test('does not invent ₽/кг when the pack size is missing', () {
    expect(pricePerUnit(packPrice: 80, productUnit: ItemUnit.l, unitSize: null), isNull);
    expect(pricePerUnit(packPrice: 80, productUnit: null, unitSize: 1), isNull);
  });

  test('piece and pack treat a missing size as one unit', () {
    expect(pricePerUnit(packPrice: 40, productUnit: ItemUnit.piece), 40);
    expect(pricePerUnit(packPrice: 90, productUnit: ItemUnit.pack, unitSize: 2), 45);
  });

  test('reads pack size from the cashier title when unit_size is empty', () {
    expect(
      pricePerUnitForName(
        packPrice: 150,
        productUnit: ItemUnit.l,
        unitSize: null,
        displayName: 'Молоко Лебедянь 2.5% 1.75 л',
      ),
      closeTo(150 / 1.75, 0.0001),
    );
  });

  test('reference pack is the largest, then the latest on a tie', () {
    const small = CatalogPosition(id: 's', displayName: 'Молоко 1 л', unitSize: 1);
    const large = CatalogPosition(id: 'l', displayName: 'Молоко 1.75 л', unitSize: 1.75);
    const alsoLarge = CatalogPosition(id: 'l2', displayName: 'Молоко 1.75 л ферма', unitSize: 1.75);

    expect(referencePack(items: [small, large], productUnit: ItemUnit.l)?.id, 'l');
    expect(
      referencePack(
        items: [small, large, alsoLarge],
        productUnit: ItemUnit.l,
        lastSeen: (item) => switch (item.id) {
          'l' => DateTime(2026, 8, 1),
          'l2' => DateTime(2026, 8, 10),
          _ => DateTime(2026, 7, 1),
        },
      )?.id,
      'l2',
    );
  });

  test('reference pack falls back to the last seen item when sizes are unknown', () {
    const a = CatalogPosition(id: 'a', displayName: 'Билет');
    const b = CatalogPosition(id: 'b', displayName: 'Проезд');
    expect(
      referencePack(
        items: [a, b],
        productUnit: ItemUnit.piece,
        lastSeen: (item) => item.id == 'b' ? DateTime(2026, 8, 2) : DateTime(2026, 8, 1),
      )?.id,
      'b',
    );
  });
}
