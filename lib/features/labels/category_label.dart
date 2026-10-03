import '../../core/catalog/model/catalog_category.dart';
import '../../l10n/app_localizations.dart';

/// Seeded categories are stored as `#key`; user categories keep their own name.
String categoryLabel(String stored, AppLocalizations l10n) {
  if (!stored.startsWith('#')) return stored;
  return seedCategoryLabels(l10n)[stored] ?? stored.substring(1);
}

String categoryTitle(CatalogCategory category, AppLocalizations l10n) => categoryLabel(category.name, l10n);

Map<String, String> seedCategoryLabels(AppLocalizations l10n) {
  return {
    '#dairyEggs': l10n.seedCategoryDairyEggs,
    '#meat': l10n.seedCategoryMeat,
    '#fish': l10n.seedCategoryFish,
    '#deli': l10n.seedCategoryDeli,
    '#produce': l10n.seedCategoryProduce,
    '#bakery': l10n.seedCategoryBakery,
    '#grocery': l10n.seedCategoryGrocery,
    '#drinks': l10n.seedCategoryDrinks,
    '#snacks': l10n.seedCategorySnacks,
    '#readyMeals': l10n.seedCategoryReadyMeals,
    '#alcohol': l10n.seedCategoryAlcohol,
    '#kids': l10n.seedCategoryKids,
    '#pets': l10n.seedCategoryPets,
    '#beauty': l10n.seedCategoryBeauty,
    '#pharmacy': l10n.seedCategoryPharmacy,
    '#home': l10n.seedCategoryHome,
    '#other': l10n.seedCategoryOther,
    '#products': l10n.seedCategoryProducts,
    '#household': l10n.seedCategoryHousehold,
    '#cafe': l10n.seedCategoryCafe,
    '#transport': l10n.seedCategoryTransport,
  };
}
