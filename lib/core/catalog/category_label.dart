import '../../l10n/app_localizations.dart';
import 'catalog_category.dart';

String categoryLabel(String stored, AppLocalizations l10n) {
  if (!stored.startsWith('#')) return stored;
  return switch (stored) {
    '#dairyEggs' => l10n.seedCategoryDairyEggs,
    '#meat' => l10n.seedCategoryMeat,
    '#fish' => l10n.seedCategoryFish,
    '#deli' => l10n.seedCategoryDeli,
    '#produce' => l10n.seedCategoryProduce,
    '#bakery' => l10n.seedCategoryBakery,
    '#grocery' => l10n.seedCategoryGrocery,
    '#drinks' => l10n.seedCategoryDrinks,
    '#snacks' => l10n.seedCategorySnacks,
    '#readyMeals' => l10n.seedCategoryReadyMeals,
    '#alcohol' => l10n.seedCategoryAlcohol,
    '#kids' => l10n.seedCategoryKids,
    '#pets' => l10n.seedCategoryPets,
    '#beauty' => l10n.seedCategoryBeauty,
    '#pharmacy' => l10n.seedCategoryPharmacy,
    '#home' => l10n.seedCategoryHome,
    '#other' => l10n.seedCategoryOther,
    _ => stored.substring(1),
  };
}

String categoryTitle(CatalogCategory category, AppLocalizations l10n) => categoryLabel(category.name, l10n);
