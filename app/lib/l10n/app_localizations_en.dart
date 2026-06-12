// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HeroDots';

  @override
  String get navMap => 'Map';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get mapCenterOnLocation => 'Center on my location';

  @override
  String get mapLoadingPois => 'Loading points of interest...';

  @override
  String get mapNoPoisNearby => 'No points of interest nearby';

  @override
  String get mapNavigate => 'Navigate';

  @override
  String get mapShowDetail => 'Show detail';

  @override
  String mapDistanceAway(String distance) {
    return '$distance away';
  }

  @override
  String get poiDetailAudioGuide => 'Audio Guide';

  @override
  String get poiDetailPlayAudio => 'Play audio guide';

  @override
  String get poiDetailStopAudio => 'Stop audio';

  @override
  String get poiDetailTtsUnavailable => 'Text-to-speech unavailable';

  @override
  String get poiDetailPhotos => 'Photos';

  @override
  String get poiDetailNotes => 'My Notes';

  @override
  String get poiDetailAddNote => 'Add a note...';

  @override
  String get poiDetailSaveNote => 'Save note';

  @override
  String get poiDetailTakePhoto => 'Take photo';

  @override
  String get poiDetailPremiumLocked => 'Premium content';

  @override
  String get poiDetailUnlockCity => 'Unlock this city';

  @override
  String get poiDetailFreeVisitUsed => 'Free visit used';

  @override
  String get poiDetailVisited => 'Visited';

  @override
  String get poiDetailNotVisited => 'Not visited yet';

  @override
  String get historyTitle => 'Visit History';

  @override
  String get historyNoVisits => 'No visits yet. Start exploring!';

  @override
  String get historySearchHint => 'Search visits...';

  @override
  String get historyTabList => 'List';

  @override
  String get historyTabCalendar => 'Calendar';

  @override
  String get historyExportPdf => 'Export to PDF';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsGeofenceRadius => 'Geofence radius';

  @override
  String settingsGeofenceRadiusValue(int meters) {
    return '$meters meters';
  }

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsSignIn => 'Sign in';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountConfirm =>
      'Are you sure? This will permanently delete all your data.';

  @override
  String get settingsPaymentHistory => 'Payment history';

  @override
  String get settingsNoPayments => 'No payments';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get authTitle => 'Sign In';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authSignInEmail => 'Sign in with email';

  @override
  String get authSignInGoogle => 'Sign in with Google';

  @override
  String get authSignInApple => 'Sign in with Apple';

  @override
  String get authSignUp => 'Create account';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authAnonymous => 'Continue without account';

  @override
  String get onboardingTitle1 => 'Discover Places';

  @override
  String get onboardingDesc1 =>
      'Find interesting points of interest around you with audio guides.';

  @override
  String get onboardingTitle2 => 'Listen & Learn';

  @override
  String get onboardingDesc2 =>
      'Audio guides play automatically when you approach a place.';

  @override
  String get onboardingTitle3 => 'Keep Your Travel Log';

  @override
  String get onboardingDesc3 =>
      'Save notes, photos, and export your travel history.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get paymentTitle => 'Unlock City';

  @override
  String paymentCityAccess(String cityName) {
    return 'Full access to $cityName';
  }

  @override
  String paymentPrice(String price) {
    return '$price EUR';
  }

  @override
  String get paymentGooglePay => 'Pay with Google Pay';

  @override
  String get paymentApplePay => 'Pay with Apple Pay';

  @override
  String get paymentRevolut => 'Pay with Revolut';

  @override
  String get paymentSuccess => 'Payment successful! City unlocked.';

  @override
  String get paymentFailed => 'Payment failed. Please try again.';

  @override
  String get paymentConfirmRevolut =>
      'Did you complete the payment in Revolut?';

  @override
  String get paymentYesConfirm => 'Yes, I paid';

  @override
  String get paymentCancel => 'Cancel';

  @override
  String get exportTitle => 'Export Travel Log';

  @override
  String get exportDateRange => 'Date range';

  @override
  String get exportFrom => 'From';

  @override
  String get exportTo => 'To';

  @override
  String get exportGeneratePdf => 'Generate PDF';

  @override
  String get exportShare => 'Share';

  @override
  String get exportNoVisitsInRange => 'No visits in selected range.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNoInternet => 'No internet connection.';

  @override
  String get errorLocationDisabled => 'Location services are disabled.';

  @override
  String get errorLocationDenied => 'Location permission denied.';

  @override
  String get errorNotificationsDisabled => 'Notifications are disabled.';

  @override
  String get errorNavigationRequiresInternet =>
      'Navigation requires an internet connection.';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonClose => 'Close';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonFree => 'Free';

  @override
  String get commonPremium => 'Premium';
}
