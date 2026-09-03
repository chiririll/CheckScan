// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'CheckScan';

  @override
  String get tabHome => 'Главная';

  @override
  String get tabHistory => 'История';

  @override
  String get scan => 'Скан';

  @override
  String get onboard1Title => 'Чеки всегда под рукой';

  @override
  String get onboard1Body =>
      'Сканируйте QR на чеке — сохраним покупки и список товаров.';

  @override
  String get onboard2Title => 'Статистика по покупкам';

  @override
  String get onboard2Body =>
      'По отсканированным чекам видно, на что уходят деньги, что покупаете чаще и где дешевле.';

  @override
  String get onboard3Title => 'Нужен доступ к камере';

  @override
  String get onboard3Body =>
      'Камера используется только чтобы считать QR на чеке.';

  @override
  String get next => 'Далее';

  @override
  String get allowCamera => 'Разрешить камеру';

  @override
  String get notNow => 'Не сейчас';

  @override
  String get homeTitle => 'Главная';

  @override
  String get historyTitle => 'История';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get receiptTitle => 'Чек';

  @override
  String get emptyHomeTitle => 'Пока нет статистики';

  @override
  String get emptyHomeBody =>
      'Отсканируйте первый чек — появятся траты, топ покупок и сравнение магазинов.';

  @override
  String get emptyHistoryTitle => 'Пока нет чеков';

  @override
  String get emptyHistoryBody =>
      'Нажмите круглую кнопку внизу и наведите камеру на QR.';

  @override
  String get spent => 'Потрачено';

  @override
  String get receiptCount => 'Чеков';

  @override
  String get previousPeriod => 'Предыдущий период';

  @override
  String get nextPeriod => 'Следующий период';

  @override
  String get emptyPeriodTitle => 'Нет чеков за этот месяц';

  @override
  String get emptyPeriodBody => 'Смените период или отсканируйте чек.';

  @override
  String get mostOften => 'Чаще всего';

  @override
  String cheaperWhere(String item) {
    return 'Где дешевле $item';
  }

  @override
  String timesCount(int count) {
    return '$count раз';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count товара',
      many: '$count товаров',
      few: '$count товара',
      one: '$count товар',
    );
    return '$_temp0';
  }

  @override
  String get providerSecrets => 'Провайдеры';

  @override
  String providerToken(String label) {
    return 'Токен ($label)';
  }

  @override
  String get providerTokenHint =>
      'Нужен, чтобы подгружать состав чека. Без него сохранится только сумма из QR.';

  @override
  String get integrations => 'Интеграции';

  @override
  String get soon => 'Скоро';

  @override
  String get integration1c => '1С';

  @override
  String get integrationExport => 'Экспорт eQ';

  @override
  String get exportEmpty => 'Нет чеков для экспорта';

  @override
  String get exportFailed => 'Не удалось экспортировать';

  @override
  String get exportShareSubject => 'Чеки CheckScan';

  @override
  String get integrationCloud => 'Облако';

  @override
  String get aimQr => 'Наведите на QR-код чека';

  @override
  String get progressGeneric => 'Ищем формат чека';

  @override
  String get progressLoading => 'Получаем данные чека';

  @override
  String get unknownTitle => 'Формат не поддерживается';

  @override
  String get unknownBody => 'Этот QR не похож на чек.';

  @override
  String get gotIt => 'Понятно';

  @override
  String get parseErrorTitle => 'Не удалось прочитать чек';

  @override
  String get parseErrorBody =>
      'Данные чека сейчас недоступны. Можно повторить.';

  @override
  String get loadErrorBody =>
      'Не удалось загрузить данные. Перезапустите приложение.';

  @override
  String get unavailableTitle => 'Сервис недоступен';

  @override
  String get unavailableBody =>
      'Не удалось получить чек. Можно повторить позже.';

  @override
  String get rateLimitedTitle => 'Слишком много запросов';

  @override
  String get rateLimitedBody =>
      'Провайдер временно ограничил доступ. Чек сохранён, состав подгрузим позже.';

  @override
  String get needsSecretTitle => 'Нужен токен';

  @override
  String get needsSecretBody =>
      'Чтобы подгрузить состав, укажите токен в настройках.';

  @override
  String get close => 'Закрыть';

  @override
  String get cancel => 'Отмена';

  @override
  String get deleteReceipt => 'Удалить';

  @override
  String get deleteReceiptTitle => 'Удалить чек?';

  @override
  String get deleteReceiptBody => 'Чек исчезнет из истории и статистики.';

  @override
  String get retry => 'Повторить';

  @override
  String get retryItems => 'Обновить состав';

  @override
  String get refreshReceipt => 'Обновить данные';

  @override
  String get receiptActions => 'Ещё';

  @override
  String get refreshPending => 'Догрузить состав';

  @override
  String get refreshPendingDone => 'Состав обновлён';

  @override
  String get missingItemsHint => 'Нет состава с сервера';

  @override
  String get noItemsBanner => 'В чеке нет товаров';

  @override
  String get galleryNoQr => 'На фото не удалось найти QR-код чека.';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get cameraDenied =>
      'Нет доступа к камере. Разрешите её в настройках системы.';

  @override
  String get itemsSection => 'Товары';

  @override
  String get metadataSection => 'Метаданные';

  @override
  String get metaTaxId => 'ИНН';

  @override
  String get metaReceiptType => 'Тип';

  @override
  String get metaReceiptId => 'ID';

  @override
  String get metaQr => 'QR';

  @override
  String get metaReceiptTypeSale => 'Покупка';

  @override
  String get metaReceiptTypeRefund => 'Возврат';

  @override
  String get metaYes => 'Да';

  @override
  String get metaNo => 'Нет';

  @override
  String qtyPrice(String qty, String price) {
    return '$qty × $price';
  }

  @override
  String amount(String value) {
    return '$value ₽';
  }

  @override
  String get catalogTitle => 'Каталог';

  @override
  String get catalogUnassigned => 'Не разобрано';

  @override
  String get catalogProducts => 'Товары';

  @override
  String get catalogCategories => 'Категории';

  @override
  String get catalogSearch => 'Поиск';

  @override
  String get catalogEmptyUnassigned => 'Все позиции уже в товарах';

  @override
  String get catalogEmptyUnassignedBody =>
      'Новые названия из чеков появятся здесь.';

  @override
  String get catalogEmptyProducts => 'Пока нет товаров';

  @override
  String get catalogEmptyProductsBody =>
      'Объедините позиции из «Не разобрано» в товар.';

  @override
  String get catalogEmptySearch => 'Ничего не найдено';

  @override
  String get assignToProduct => 'В товар';

  @override
  String mergeWith(String name) {
    return 'Объединить с $name';
  }

  @override
  String get newProduct => 'Новый товар';

  @override
  String get productName => 'Название товара';

  @override
  String get productCategory => 'Категория';

  @override
  String get productTags => 'Теги';

  @override
  String get addTag => 'Добавить тег';

  @override
  String get detachPosition => 'Отвязать';

  @override
  String get deleteProduct => 'Удалить товар';

  @override
  String get deleteProductTitle => 'Удалить товар?';

  @override
  String get deleteProductBody => 'Позиции останутся в «Не разобрано».';

  @override
  String get deleteCategoryTitle => 'Удалить категорию?';

  @override
  String get deleteCategoryBody => 'Товары останутся без категории.';

  @override
  String get addCategory => 'Новая категория';

  @override
  String get categoryName => 'Название категории';

  @override
  String get uncategorized => 'Без категории';

  @override
  String get unitLabel => 'Единица';

  @override
  String get unitNone => 'Не задана';

  @override
  String get unitPiece => 'шт';

  @override
  String get unitPack => 'упак';

  @override
  String get unitKg => 'кг';

  @override
  String get unitG => 'г';

  @override
  String get unitL => 'л';

  @override
  String get unitMl => 'мл';

  @override
  String get unitSize => 'Фасовка';

  @override
  String get byCategory => 'По категориям';

  @override
  String get splitAlias => 'Отделить';

  @override
  String get save => 'Сохранить';

  @override
  String get createAndAssign => 'Создать и привязать';

  @override
  String get rename => 'Переименовать';

  @override
  String get aliasesSection => 'Названия в чеках';

  @override
  String get noCategory => 'Без категории';

  @override
  String get seedCategoryDairyEggs => 'Молочные и яйца';

  @override
  String get seedCategoryMeat => 'Мясо и птица';

  @override
  String get seedCategoryFish => 'Рыба и морепродукты';

  @override
  String get seedCategoryDeli => 'Колбасы и копчёности';

  @override
  String get seedCategoryProduce => 'Овощи и фрукты';

  @override
  String get seedCategoryBakery => 'Хлеб и выпечка';

  @override
  String get seedCategoryGrocery => 'Бакалея';

  @override
  String get seedCategoryDrinks => 'Напитки';

  @override
  String get seedCategorySnacks => 'Сладости и снеки';

  @override
  String get seedCategoryReadyMeals => 'Готовая еда';

  @override
  String get seedCategoryAlcohol => 'Алкоголь';

  @override
  String get seedCategoryKids => 'Детские товары';

  @override
  String get seedCategoryPets => 'Товары для животных';

  @override
  String get seedCategoryBeauty => 'Красота и гигиена';

  @override
  String get seedCategoryPharmacy => 'Аптека';

  @override
  String get seedCategoryHome => 'Дом и быт';

  @override
  String get seedCategoryOther => 'Прочее';
}
