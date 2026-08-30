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
  String get integrations => 'Интеграции';

  @override
  String get soon => 'Скоро';

  @override
  String get integration1c => '1С';

  @override
  String get integrationExport => 'Экспорт eQ';

  @override
  String get integrationCloud => 'Облако';

  @override
  String get aimQr => 'Наведите на QR-код чека';

  @override
  String get progressRu => 'Получаем данные российского чека';

  @override
  String get progressEq => 'Читаем электронный чек';

  @override
  String get progressGeneric => 'Ищем формат чека';

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
  String get close => 'Закрыть';

  @override
  String get retry => 'Повторить';

  @override
  String get retryItems => 'Обновить состав';

  @override
  String get noItemsBanner => 'Список покупок пока не пришёл';

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
  String qtyPrice(String qty, String price) {
    return '$qty × $price';
  }

  @override
  String get providerRu => 'RU';

  @override
  String get providerEq => 'eQ';

  @override
  String amount(String value) {
    return '$value ₽';
  }
}
