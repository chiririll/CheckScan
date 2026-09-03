import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ru')];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'CheckScan'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get tabHome;

  /// No description provided for @tabHistory.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get tabHistory;

  /// No description provided for @scan.
  ///
  /// In ru, this message translates to:
  /// **'Скан'**
  String get scan;

  /// No description provided for @onboard1Title.
  ///
  /// In ru, this message translates to:
  /// **'Чеки всегда под рукой'**
  String get onboard1Title;

  /// No description provided for @onboard1Body.
  ///
  /// In ru, this message translates to:
  /// **'Сканируйте QR на чеке — сохраним покупки и список товаров.'**
  String get onboard1Body;

  /// No description provided for @onboard2Title.
  ///
  /// In ru, this message translates to:
  /// **'Статистика по покупкам'**
  String get onboard2Title;

  /// No description provided for @onboard2Body.
  ///
  /// In ru, this message translates to:
  /// **'По отсканированным чекам видно, на что уходят деньги, что покупаете чаще и где дешевле.'**
  String get onboard2Body;

  /// No description provided for @onboard3Title.
  ///
  /// In ru, this message translates to:
  /// **'Нужен доступ к камере'**
  String get onboard3Title;

  /// No description provided for @onboard3Body.
  ///
  /// In ru, this message translates to:
  /// **'Камера используется только чтобы считать QR на чеке.'**
  String get onboard3Body;

  /// No description provided for @next.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get next;

  /// No description provided for @allowCamera.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить камеру'**
  String get allowCamera;

  /// No description provided for @notNow.
  ///
  /// In ru, this message translates to:
  /// **'Не сейчас'**
  String get notNow;

  /// No description provided for @homeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get homeTitle;

  /// No description provided for @historyTitle.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get historyTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @receiptTitle.
  ///
  /// In ru, this message translates to:
  /// **'Чек'**
  String get receiptTitle;

  /// No description provided for @emptyHomeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет статистики'**
  String get emptyHomeTitle;

  /// No description provided for @emptyHomeBody.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте первый чек — появятся траты, топ покупок и сравнение магазинов.'**
  String get emptyHomeBody;

  /// No description provided for @emptyHistoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет чеков'**
  String get emptyHistoryTitle;

  /// No description provided for @emptyHistoryBody.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите круглую кнопку внизу и наведите камеру на QR.'**
  String get emptyHistoryBody;

  /// No description provided for @spent.
  ///
  /// In ru, this message translates to:
  /// **'Потрачено'**
  String get spent;

  /// No description provided for @receiptCount.
  ///
  /// In ru, this message translates to:
  /// **'Чеков'**
  String get receiptCount;

  /// No description provided for @previousPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущий период'**
  String get previousPeriod;

  /// No description provided for @nextPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Следующий период'**
  String get nextPeriod;

  /// No description provided for @emptyPeriodTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нет чеков за этот месяц'**
  String get emptyPeriodTitle;

  /// No description provided for @emptyPeriodBody.
  ///
  /// In ru, this message translates to:
  /// **'Смените период или отсканируйте чек.'**
  String get emptyPeriodBody;

  /// No description provided for @mostOften.
  ///
  /// In ru, this message translates to:
  /// **'Чаще всего'**
  String get mostOften;

  /// No description provided for @cheaperWhere.
  ///
  /// In ru, this message translates to:
  /// **'Где дешевле {item}'**
  String cheaperWhere(String item);

  /// No description provided for @timesCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} раз'**
  String timesCount(int count);

  /// No description provided for @itemsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} товар} few{{count} товара} many{{count} товаров} other{{count} товара}}'**
  String itemsCount(int count);

  /// No description provided for @providerSecrets.
  ///
  /// In ru, this message translates to:
  /// **'Провайдеры'**
  String get providerSecrets;

  /// No description provided for @providerToken.
  ///
  /// In ru, this message translates to:
  /// **'Токен ({label})'**
  String providerToken(String label);

  /// No description provided for @providerTokenHint.
  ///
  /// In ru, this message translates to:
  /// **'Нужен, чтобы подгружать состав чека. Без него сохранится только сумма из QR.'**
  String get providerTokenHint;

  /// No description provided for @integrations.
  ///
  /// In ru, this message translates to:
  /// **'Интеграции'**
  String get integrations;

  /// No description provided for @soon.
  ///
  /// In ru, this message translates to:
  /// **'Скоро'**
  String get soon;

  /// No description provided for @integration1c.
  ///
  /// In ru, this message translates to:
  /// **'1С'**
  String get integration1c;

  /// No description provided for @integrationExport.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт eQ'**
  String get integrationExport;

  /// No description provided for @exportEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет чеков для экспорта'**
  String get exportEmpty;

  /// No description provided for @exportFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось экспортировать'**
  String get exportFailed;

  /// No description provided for @exportShareSubject.
  ///
  /// In ru, this message translates to:
  /// **'Чеки CheckScan'**
  String get exportShareSubject;

  /// No description provided for @integrationCloud.
  ///
  /// In ru, this message translates to:
  /// **'Облако'**
  String get integrationCloud;

  /// No description provided for @aimQr.
  ///
  /// In ru, this message translates to:
  /// **'Наведите на QR-код чека'**
  String get aimQr;

  /// No description provided for @progressGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Ищем формат чека'**
  String get progressGeneric;

  /// No description provided for @progressLoading.
  ///
  /// In ru, this message translates to:
  /// **'Получаем данные чека'**
  String get progressLoading;

  /// No description provided for @unknownTitle.
  ///
  /// In ru, this message translates to:
  /// **'Формат не поддерживается'**
  String get unknownTitle;

  /// No description provided for @unknownBody.
  ///
  /// In ru, this message translates to:
  /// **'Этот QR не похож на чек.'**
  String get unknownBody;

  /// No description provided for @gotIt.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get gotIt;

  /// No description provided for @parseErrorTitle.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать чек'**
  String get parseErrorTitle;

  /// No description provided for @parseErrorBody.
  ///
  /// In ru, this message translates to:
  /// **'Данные чека сейчас недоступны. Можно повторить.'**
  String get parseErrorBody;

  /// No description provided for @loadErrorBody.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить данные. Перезапустите приложение.'**
  String get loadErrorBody;

  /// No description provided for @unavailableTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сервис недоступен'**
  String get unavailableTitle;

  /// No description provided for @unavailableBody.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось получить чек. Можно повторить позже.'**
  String get unavailableBody;

  /// No description provided for @rateLimitedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много запросов'**
  String get rateLimitedTitle;

  /// No description provided for @rateLimitedBody.
  ///
  /// In ru, this message translates to:
  /// **'Провайдер временно ограничил доступ. Чек сохранён, состав подгрузим позже.'**
  String get rateLimitedBody;

  /// No description provided for @needsSecretTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нужен токен'**
  String get needsSecretTitle;

  /// No description provided for @needsSecretBody.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы подгрузить состав, укажите токен в настройках.'**
  String get needsSecretBody;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @deleteReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get deleteReceipt;

  /// No description provided for @deleteReceiptTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить чек?'**
  String get deleteReceiptTitle;

  /// No description provided for @deleteReceiptBody.
  ///
  /// In ru, this message translates to:
  /// **'Чек исчезнет из истории и статистики.'**
  String get deleteReceiptBody;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @retryItems.
  ///
  /// In ru, this message translates to:
  /// **'Обновить состав'**
  String get retryItems;

  /// No description provided for @refreshReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Обновить данные'**
  String get refreshReceipt;

  /// No description provided for @receiptActions.
  ///
  /// In ru, this message translates to:
  /// **'Ещё'**
  String get receiptActions;

  /// No description provided for @refreshPending.
  ///
  /// In ru, this message translates to:
  /// **'Догрузить состав'**
  String get refreshPending;

  /// No description provided for @refreshPendingDone.
  ///
  /// In ru, this message translates to:
  /// **'Состав обновлён'**
  String get refreshPendingDone;

  /// No description provided for @missingItemsHint.
  ///
  /// In ru, this message translates to:
  /// **'Нет состава с сервера'**
  String get missingItemsHint;

  /// No description provided for @noItemsBanner.
  ///
  /// In ru, this message translates to:
  /// **'В чеке нет товаров'**
  String get noItemsBanner;

  /// No description provided for @galleryNoQr.
  ///
  /// In ru, this message translates to:
  /// **'На фото не удалось найти QR-код чека.'**
  String get galleryNoQr;

  /// No description provided for @openSettings.
  ///
  /// In ru, this message translates to:
  /// **'Открыть настройки'**
  String get openSettings;

  /// No description provided for @cameraDenied.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к камере. Разрешите её в настройках системы.'**
  String get cameraDenied;

  /// No description provided for @itemsSection.
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get itemsSection;

  /// No description provided for @metadataSection.
  ///
  /// In ru, this message translates to:
  /// **'Метаданные'**
  String get metadataSection;

  /// No description provided for @metaTaxId.
  ///
  /// In ru, this message translates to:
  /// **'ИНН'**
  String get metaTaxId;

  /// No description provided for @metaReceiptType.
  ///
  /// In ru, this message translates to:
  /// **'Тип'**
  String get metaReceiptType;

  /// No description provided for @metaReceiptId.
  ///
  /// In ru, this message translates to:
  /// **'ID'**
  String get metaReceiptId;

  /// No description provided for @metaQr.
  ///
  /// In ru, this message translates to:
  /// **'QR'**
  String get metaQr;

  /// No description provided for @metaReceiptTypeSale.
  ///
  /// In ru, this message translates to:
  /// **'Покупка'**
  String get metaReceiptTypeSale;

  /// No description provided for @metaReceiptTypeRefund.
  ///
  /// In ru, this message translates to:
  /// **'Возврат'**
  String get metaReceiptTypeRefund;

  /// No description provided for @metaYes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get metaYes;

  /// No description provided for @metaNo.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get metaNo;

  /// No description provided for @qtyPrice.
  ///
  /// In ru, this message translates to:
  /// **'{qty} × {price}'**
  String qtyPrice(String qty, String price);

  /// No description provided for @amount.
  ///
  /// In ru, this message translates to:
  /// **'{value} ₽'**
  String amount(String value);

  /// No description provided for @catalogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Каталог'**
  String get catalogTitle;

  /// No description provided for @catalogUnassigned.
  ///
  /// In ru, this message translates to:
  /// **'Не разобрано'**
  String get catalogUnassigned;

  /// No description provided for @catalogProducts.
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get catalogProducts;

  /// No description provided for @catalogCategories.
  ///
  /// In ru, this message translates to:
  /// **'Категории'**
  String get catalogCategories;

  /// No description provided for @catalogSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get catalogSearch;

  /// No description provided for @catalogEmptyUnassigned.
  ///
  /// In ru, this message translates to:
  /// **'Все позиции уже в товарах'**
  String get catalogEmptyUnassigned;

  /// No description provided for @catalogEmptyUnassignedBody.
  ///
  /// In ru, this message translates to:
  /// **'Новые названия из чеков появятся здесь.'**
  String get catalogEmptyUnassignedBody;

  /// No description provided for @catalogEmptyProducts.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет товаров'**
  String get catalogEmptyProducts;

  /// No description provided for @catalogEmptyProductsBody.
  ///
  /// In ru, this message translates to:
  /// **'Объедините позиции из «Не разобрано» в товар.'**
  String get catalogEmptyProductsBody;

  /// No description provided for @catalogEmptySearch.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get catalogEmptySearch;

  /// No description provided for @assignToProduct.
  ///
  /// In ru, this message translates to:
  /// **'В товар'**
  String get assignToProduct;

  /// No description provided for @mergeWith.
  ///
  /// In ru, this message translates to:
  /// **'Объединить с {name}'**
  String mergeWith(String name);

  /// No description provided for @newProduct.
  ///
  /// In ru, this message translates to:
  /// **'Новый товар'**
  String get newProduct;

  /// No description provided for @productName.
  ///
  /// In ru, this message translates to:
  /// **'Название товара'**
  String get productName;

  /// No description provided for @productCategory.
  ///
  /// In ru, this message translates to:
  /// **'Категория'**
  String get productCategory;

  /// No description provided for @productTags.
  ///
  /// In ru, this message translates to:
  /// **'Теги'**
  String get productTags;

  /// No description provided for @addTag.
  ///
  /// In ru, this message translates to:
  /// **'Добавить тег'**
  String get addTag;

  /// No description provided for @detachPosition.
  ///
  /// In ru, this message translates to:
  /// **'Отвязать'**
  String get detachPosition;

  /// No description provided for @deleteProduct.
  ///
  /// In ru, this message translates to:
  /// **'Удалить товар'**
  String get deleteProduct;

  /// No description provided for @deleteProductTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить товар?'**
  String get deleteProductTitle;

  /// No description provided for @deleteProductBody.
  ///
  /// In ru, this message translates to:
  /// **'Позиции останутся в «Не разобрано».'**
  String get deleteProductBody;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить категорию?'**
  String get deleteCategoryTitle;

  /// No description provided for @deleteCategoryBody.
  ///
  /// In ru, this message translates to:
  /// **'Товары останутся без категории.'**
  String get deleteCategoryBody;

  /// No description provided for @addCategory.
  ///
  /// In ru, this message translates to:
  /// **'Новая категория'**
  String get addCategory;

  /// No description provided for @categoryName.
  ///
  /// In ru, this message translates to:
  /// **'Название категории'**
  String get categoryName;

  /// No description provided for @uncategorized.
  ///
  /// In ru, this message translates to:
  /// **'Без категории'**
  String get uncategorized;

  /// No description provided for @unitLabel.
  ///
  /// In ru, this message translates to:
  /// **'Единица'**
  String get unitLabel;

  /// No description provided for @unitNone.
  ///
  /// In ru, this message translates to:
  /// **'Не задана'**
  String get unitNone;

  /// No description provided for @unitPiece.
  ///
  /// In ru, this message translates to:
  /// **'шт'**
  String get unitPiece;

  /// No description provided for @unitPack.
  ///
  /// In ru, this message translates to:
  /// **'упак'**
  String get unitPack;

  /// No description provided for @unitKg.
  ///
  /// In ru, this message translates to:
  /// **'кг'**
  String get unitKg;

  /// No description provided for @unitG.
  ///
  /// In ru, this message translates to:
  /// **'г'**
  String get unitG;

  /// No description provided for @unitL.
  ///
  /// In ru, this message translates to:
  /// **'л'**
  String get unitL;

  /// No description provided for @unitMl.
  ///
  /// In ru, this message translates to:
  /// **'мл'**
  String get unitMl;

  /// No description provided for @unitSize.
  ///
  /// In ru, this message translates to:
  /// **'Фасовка'**
  String get unitSize;

  /// No description provided for @byCategory.
  ///
  /// In ru, this message translates to:
  /// **'По категориям'**
  String get byCategory;

  /// No description provided for @splitAlias.
  ///
  /// In ru, this message translates to:
  /// **'Отделить'**
  String get splitAlias;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @createAndAssign.
  ///
  /// In ru, this message translates to:
  /// **'Создать и привязать'**
  String get createAndAssign;

  /// No description provided for @rename.
  ///
  /// In ru, this message translates to:
  /// **'Переименовать'**
  String get rename;

  /// No description provided for @aliasesSection.
  ///
  /// In ru, this message translates to:
  /// **'Названия в чеках'**
  String get aliasesSection;

  /// No description provided for @noCategory.
  ///
  /// In ru, this message translates to:
  /// **'Без категории'**
  String get noCategory;

  /// No description provided for @seedCategoryDairyEggs.
  ///
  /// In ru, this message translates to:
  /// **'Молочные и яйца'**
  String get seedCategoryDairyEggs;

  /// No description provided for @seedCategoryMeat.
  ///
  /// In ru, this message translates to:
  /// **'Мясо и птица'**
  String get seedCategoryMeat;

  /// No description provided for @seedCategoryFish.
  ///
  /// In ru, this message translates to:
  /// **'Рыба и морепродукты'**
  String get seedCategoryFish;

  /// No description provided for @seedCategoryDeli.
  ///
  /// In ru, this message translates to:
  /// **'Колбасы и копчёности'**
  String get seedCategoryDeli;

  /// No description provided for @seedCategoryProduce.
  ///
  /// In ru, this message translates to:
  /// **'Овощи и фрукты'**
  String get seedCategoryProduce;

  /// No description provided for @seedCategoryBakery.
  ///
  /// In ru, this message translates to:
  /// **'Хлеб и выпечка'**
  String get seedCategoryBakery;

  /// No description provided for @seedCategoryGrocery.
  ///
  /// In ru, this message translates to:
  /// **'Бакалея'**
  String get seedCategoryGrocery;

  /// No description provided for @seedCategoryDrinks.
  ///
  /// In ru, this message translates to:
  /// **'Напитки'**
  String get seedCategoryDrinks;

  /// No description provided for @seedCategorySnacks.
  ///
  /// In ru, this message translates to:
  /// **'Сладости и снеки'**
  String get seedCategorySnacks;

  /// No description provided for @seedCategoryReadyMeals.
  ///
  /// In ru, this message translates to:
  /// **'Готовая еда'**
  String get seedCategoryReadyMeals;

  /// No description provided for @seedCategoryAlcohol.
  ///
  /// In ru, this message translates to:
  /// **'Алкоголь'**
  String get seedCategoryAlcohol;

  /// No description provided for @seedCategoryKids.
  ///
  /// In ru, this message translates to:
  /// **'Детские товары'**
  String get seedCategoryKids;

  /// No description provided for @seedCategoryPets.
  ///
  /// In ru, this message translates to:
  /// **'Товары для животных'**
  String get seedCategoryPets;

  /// No description provided for @seedCategoryBeauty.
  ///
  /// In ru, this message translates to:
  /// **'Красота и гигиена'**
  String get seedCategoryBeauty;

  /// No description provided for @seedCategoryPharmacy.
  ///
  /// In ru, this message translates to:
  /// **'Аптека'**
  String get seedCategoryPharmacy;

  /// No description provided for @seedCategoryHome.
  ///
  /// In ru, this message translates to:
  /// **'Дом и быт'**
  String get seedCategoryHome;

  /// No description provided for @seedCategoryOther.
  ///
  /// In ru, this message translates to:
  /// **'Прочее'**
  String get seedCategoryOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
