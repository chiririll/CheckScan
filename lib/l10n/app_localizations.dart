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
  /// **'По отсканированным чекам видно, сколько и в каких магазинах уходит денег.'**
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
  /// **'Отсканируйте первый чек — появятся цены, траты зря, темп и магазины.'**
  String get emptyHomeBody;

  /// No description provided for @emptyHistoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет чеков'**
  String get emptyHistoryTitle;

  /// No description provided for @emptyHistoryBody.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите круглую кнопку внизу и наведите камеру на QR или добавьте чек вручную через «+».'**
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
  /// **'Экспорт чеков'**
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

  /// No description provided for @rateLimitedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много запросов'**
  String get rateLimitedTitle;

  /// No description provided for @needsSecretTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нужен токен'**
  String get needsSecretTitle;

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

  /// No description provided for @merchantName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get merchantName;

  /// No description provided for @productTags.
  ///
  /// In ru, this message translates to:
  /// **'Теги'**
  String get productTags;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @merchantsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Магазины'**
  String get merchantsTitle;

  /// No description provided for @merchantNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Сеть'**
  String get merchantNetwork;

  /// No description provided for @merchantNoNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Без сети'**
  String get merchantNoNetwork;

  /// No description provided for @merchantAliases.
  ///
  /// In ru, this message translates to:
  /// **'Как в чеке'**
  String get merchantAliases;

  /// No description provided for @addAlias.
  ///
  /// In ru, this message translates to:
  /// **'Добавить название'**
  String get addAlias;

  /// No description provided for @merchantsBlock.
  ///
  /// In ru, this message translates to:
  /// **'Магазины'**
  String get merchantsBlock;

  /// No description provided for @merchantsWithoutNetwork.
  ///
  /// In ru, this message translates to:
  /// **'{count} без сети'**
  String merchantsWithoutNetwork(int count);

  /// No description provided for @addReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Добавить чек'**
  String get addReceipt;

  /// No description provided for @editReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get editReceipt;

  /// No description provided for @manualTitleNew.
  ///
  /// In ru, this message translates to:
  /// **'Новый чек'**
  String get manualTitleNew;

  /// No description provided for @manualTitleEdit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить чек'**
  String get manualTitleEdit;

  /// No description provided for @manualMerchant.
  ///
  /// In ru, this message translates to:
  /// **'Магазин или продавец'**
  String get manualMerchant;

  /// No description provided for @manualDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата и время'**
  String get manualDate;

  /// No description provided for @manualCurrency.
  ///
  /// In ru, this message translates to:
  /// **'Валюта'**
  String get manualCurrency;

  /// No description provided for @manualItems.
  ///
  /// In ru, this message translates to:
  /// **'Позиции'**
  String get manualItems;

  /// No description provided for @manualAddItem.
  ///
  /// In ru, this message translates to:
  /// **'Добавить позицию'**
  String get manualAddItem;

  /// No description provided for @manualRemoveItem.
  ///
  /// In ru, this message translates to:
  /// **'Удалить позицию'**
  String get manualRemoveItem;

  /// No description provided for @manualItemName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get manualItemName;

  /// No description provided for @manualItemQty.
  ///
  /// In ru, this message translates to:
  /// **'Кол-во'**
  String get manualItemQty;

  /// No description provided for @manualItemPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get manualItemPrice;

  /// No description provided for @manualTotal.
  ///
  /// In ru, this message translates to:
  /// **'Итого'**
  String get manualTotal;

  /// No description provided for @manualInvalidTotal.
  ///
  /// In ru, this message translates to:
  /// **'Укажите сумму больше нуля'**
  String get manualInvalidTotal;

  /// No description provided for @manualInvalidItem.
  ///
  /// In ru, this message translates to:
  /// **'У позиции нужны название и цена'**
  String get manualInvalidItem;

  /// No description provided for @manualProviderLabel.
  ///
  /// In ru, this message translates to:
  /// **'Вручную'**
  String get manualProviderLabel;

  /// No description provided for @currenciesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Валюты'**
  String get currenciesTitle;

  /// No description provided for @currenciesHint.
  ///
  /// In ru, this message translates to:
  /// **'Порядок вкладок на главной и выбор валюты в ручном чеке. Валюты из последних чеков подставляются сами, если их нет в списке.'**
  String get currenciesHint;

  /// No description provided for @currenciesAddTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавить валюту'**
  String get currenciesAddTitle;

  /// No description provided for @currenciesRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать'**
  String get currenciesRemove;

  /// No description provided for @currenciesFromReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Из последних чеков'**
  String get currenciesFromReceipts;

  /// No description provided for @currencyInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Код валюты — три латинские буквы, например EUR'**
  String get currencyInvalid;

  /// No description provided for @merchantsEmptyBody.
  ///
  /// In ru, this message translates to:
  /// **'Магазины появятся из чеков.'**
  String get merchantsEmptyBody;
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
