import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HeroDots'**
  String get appTitle;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @mapCenterOnLocation.
  ///
  /// In en, this message translates to:
  /// **'Center on my location'**
  String get mapCenterOnLocation;

  /// No description provided for @mapLoadingPois.
  ///
  /// In en, this message translates to:
  /// **'Loading points of interest...'**
  String get mapLoadingPois;

  /// No description provided for @mapNoPoisNearby.
  ///
  /// In en, this message translates to:
  /// **'No points of interest nearby'**
  String get mapNoPoisNearby;

  /// No description provided for @mapNavigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get mapNavigate;

  /// No description provided for @mapShowDetail.
  ///
  /// In en, this message translates to:
  /// **'Show detail'**
  String get mapShowDetail;

  /// No description provided for @mapDistanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String mapDistanceAway(String distance);

  /// No description provided for @poiDetailAudioGuide.
  ///
  /// In en, this message translates to:
  /// **'Audio Guide'**
  String get poiDetailAudioGuide;

  /// No description provided for @poiDetailPlayAudio.
  ///
  /// In en, this message translates to:
  /// **'Play audio guide'**
  String get poiDetailPlayAudio;

  /// No description provided for @poiDetailStopAudio.
  ///
  /// In en, this message translates to:
  /// **'Stop audio'**
  String get poiDetailStopAudio;

  /// No description provided for @poiDetailTtsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Text-to-speech unavailable'**
  String get poiDetailTtsUnavailable;

  /// No description provided for @poiDetailPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get poiDetailPhotos;

  /// No description provided for @poiDetailNotes.
  ///
  /// In en, this message translates to:
  /// **'My Notes'**
  String get poiDetailNotes;

  /// No description provided for @poiDetailAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note...'**
  String get poiDetailAddNote;

  /// No description provided for @poiDetailSaveNote.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get poiDetailSaveNote;

  /// No description provided for @poiDetailTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get poiDetailTakePhoto;

  /// No description provided for @poiDetailPremiumLocked.
  ///
  /// In en, this message translates to:
  /// **'Premium content'**
  String get poiDetailPremiumLocked;

  /// No description provided for @poiDetailUnlockCity.
  ///
  /// In en, this message translates to:
  /// **'Unlock this city'**
  String get poiDetailUnlockCity;

  /// No description provided for @poiDetailFreeVisitUsed.
  ///
  /// In en, this message translates to:
  /// **'Free visit used'**
  String get poiDetailFreeVisitUsed;

  /// No description provided for @poiDetailVisited.
  ///
  /// In en, this message translates to:
  /// **'Visited'**
  String get poiDetailVisited;

  /// No description provided for @poiDetailNotVisited.
  ///
  /// In en, this message translates to:
  /// **'Not visited yet'**
  String get poiDetailNotVisited;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit History'**
  String get historyTitle;

  /// No description provided for @historyNoVisits.
  ///
  /// In en, this message translates to:
  /// **'No visits yet. Start exploring!'**
  String get historyNoVisits;

  /// No description provided for @historySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search visits...'**
  String get historySearchHint;

  /// No description provided for @historyTabList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get historyTabList;

  /// No description provided for @historyTabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get historyTabCalendar;

  /// No description provided for @historyExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export to PDF'**
  String get historyExportPdf;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsGeofenceRadius.
  ///
  /// In en, this message translates to:
  /// **'Geofence radius'**
  String get settingsGeofenceRadius;

  /// No description provided for @settingsGeofenceRadiusValue.
  ///
  /// In en, this message translates to:
  /// **'{meters} meters'**
  String settingsGeofenceRadiusValue(int meters);

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get settingsSignIn;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will permanently delete all your data.'**
  String get settingsDeleteAccountConfirm;

  /// No description provided for @settingsPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get settingsPaymentHistory;

  /// No description provided for @settingsNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments'**
  String get settingsNoPayments;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authTitle;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authSignInEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get authSignInEmail;

  /// No description provided for @authSignInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get authSignInGoogle;

  /// No description provided for @authSignInApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get authSignInApple;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUp;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Continue without account'**
  String get authAnonymous;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Discover Places'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Find interesting points of interest around you with audio guides.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Listen & Learn'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Audio guides play automatically when you approach a place.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Keep Your Travel Log'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Save notes, photos, and export your travel history.'**
  String get onboardingDesc3;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock City'**
  String get paymentTitle;

  /// No description provided for @paymentCityAccess.
  ///
  /// In en, this message translates to:
  /// **'Full access to {cityName}'**
  String paymentCityAccess(String cityName);

  /// No description provided for @paymentPrice.
  ///
  /// In en, this message translates to:
  /// **'{price} EUR'**
  String paymentPrice(String price);

  /// No description provided for @paymentGooglePay.
  ///
  /// In en, this message translates to:
  /// **'Pay with Google Pay'**
  String get paymentGooglePay;

  /// No description provided for @paymentApplePay.
  ///
  /// In en, this message translates to:
  /// **'Pay with Apple Pay'**
  String get paymentApplePay;

  /// No description provided for @paymentRevolut.
  ///
  /// In en, this message translates to:
  /// **'Pay with Revolut'**
  String get paymentRevolut;

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment successful! City unlocked.'**
  String get paymentSuccess;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Please try again.'**
  String get paymentFailed;

  /// No description provided for @paymentConfirmRevolut.
  ///
  /// In en, this message translates to:
  /// **'Did you complete the payment in Revolut?'**
  String get paymentConfirmRevolut;

  /// No description provided for @paymentYesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, I paid'**
  String get paymentYesConfirm;

  /// No description provided for @paymentCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get paymentCancel;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Travel Log'**
  String get exportTitle;

  /// No description provided for @exportDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get exportDateRange;

  /// No description provided for @exportFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get exportFrom;

  /// No description provided for @exportTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get exportTo;

  /// No description provided for @exportGeneratePdf.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF'**
  String get exportGeneratePdf;

  /// No description provided for @exportShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get exportShare;

  /// No description provided for @exportNoVisitsInRange.
  ///
  /// In en, this message translates to:
  /// **'No visits in selected range.'**
  String get exportNoVisitsInRange;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNoInternet;

  /// No description provided for @errorLocationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get errorLocationDisabled;

  /// No description provided for @errorLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get errorLocationDenied;

  /// No description provided for @errorNotificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled.'**
  String get errorNotificationsDisabled;

  /// No description provided for @errorNavigationRequiresInternet.
  ///
  /// In en, this message translates to:
  /// **'Navigation requires an internet connection.'**
  String get errorNavigationRequiresInternet;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get commonFree;

  /// No description provided for @commonPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get commonPremium;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
