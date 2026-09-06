import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hamro Kosh'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFund.
  ///
  /// In en, this message translates to:
  /// **'Fund'**
  String get navFund;

  /// No description provided for @navLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get navLoans;

  /// No description provided for @navMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get navMembers;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @navAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get navAudit;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get actionSubmit;

  /// No description provided for @actionSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get actionSignIn;

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get actionSignOut;

  /// No description provided for @actionSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get actionSignUp;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get actionSeeAll;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to your community fund'**
  String get authLoginSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullNameLabel;

  /// No description provided for @authPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get authPhoneLabel;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Join your community fund'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to start contributing'**
  String get authRegisterSubtitle;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password.'**
  String get authResetPasswordInstruction;

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authSendResetLink;

  /// No description provided for @onboardingTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get onboardingTermsTitle;

  /// No description provided for @onboardingAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the Terms & Conditions'**
  String get onboardingAcceptTerms;

  /// No description provided for @onboardingDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get onboardingDecline;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get dashboardTitle;

  /// No description provided for @dashboardFundBalance.
  ///
  /// In en, this message translates to:
  /// **'Available fund balance'**
  String get dashboardFundBalance;

  /// No description provided for @dashboardTotalContributed.
  ///
  /// In en, this message translates to:
  /// **'Your total contributed'**
  String get dashboardTotalContributed;

  /// No description provided for @dashboardTotalLoaned.
  ///
  /// In en, this message translates to:
  /// **'Total loaned out'**
  String get dashboardTotalLoaned;

  /// No description provided for @dashboardOutstandingLoans.
  ///
  /// In en, this message translates to:
  /// **'Outstanding loans'**
  String get dashboardOutstandingLoans;

  /// No description provided for @dashboardInterestEarned.
  ///
  /// In en, this message translates to:
  /// **'Interest earned'**
  String get dashboardInterestEarned;

  /// No description provided for @dashboardRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get dashboardRecentTransactions;

  /// No description provided for @dashboardUpcomingPayment.
  ///
  /// In en, this message translates to:
  /// **'Upcoming payment'**
  String get dashboardUpcomingPayment;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get dashboardAnnouncements;

  /// No description provided for @fundTitle.
  ///
  /// In en, this message translates to:
  /// **'Community Fund'**
  String get fundTitle;

  /// No description provided for @fundMoneyIn.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get fundMoneyIn;

  /// No description provided for @fundMoneyOut.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get fundMoneyOut;

  /// No description provided for @fundUsage.
  ///
  /// In en, this message translates to:
  /// **'Fund usage'**
  String get fundUsage;

  /// No description provided for @fundLedger.
  ///
  /// In en, this message translates to:
  /// **'Financial ledger'**
  String get fundLedger;

  /// No description provided for @fundOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get fundOverview;

  /// No description provided for @contributionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contributions'**
  String get contributionsTitle;

  /// No description provided for @contributionsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly contribution'**
  String get contributionsMonthly;

  /// No description provided for @contributionsSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special contributions'**
  String get contributionsSpecial;

  /// No description provided for @contributionsHistory.
  ///
  /// In en, this message translates to:
  /// **'Contribution history'**
  String get contributionsHistory;

  /// No description provided for @contributionsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add contribution'**
  String get contributionsAdd;

  /// No description provided for @loansTitle.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get loansTitle;

  /// No description provided for @loansRequest.
  ///
  /// In en, this message translates to:
  /// **'Request a loan'**
  String get loansRequest;

  /// No description provided for @loansMyLoans.
  ///
  /// In en, this message translates to:
  /// **'My loans'**
  String get loansMyLoans;

  /// No description provided for @loansRepaymentSchedule.
  ///
  /// In en, this message translates to:
  /// **'Repayment schedule'**
  String get loansRepaymentSchedule;

  /// No description provided for @loansRepaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Repayment history'**
  String get loansRepaymentHistory;

  /// No description provided for @loansTerms.
  ///
  /// In en, this message translates to:
  /// **'Loan terms'**
  String get loansTerms;

  /// No description provided for @membersTitle.
  ///
  /// In en, this message translates to:
  /// **'Community Members'**
  String get membersTitle;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// No description provided for @memberProfile.
  ///
  /// In en, this message translates to:
  /// **'Member profile'**
  String get memberProfile;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @transactionsFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get transactionsFilter;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly report'**
  String get reportsMonthly;

  /// No description provided for @reportsYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly report'**
  String get reportsYearly;

  /// No description provided for @reportsFund.
  ///
  /// In en, this message translates to:
  /// **'Fund report'**
  String get reportsFund;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsEmpty;

  /// No description provided for @announcementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcementsTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// No description provided for @profileMyProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get profileMyProfile;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profileThemeMode;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get profileAppLock;

  /// No description provided for @profileNotificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get profileNotificationPreferences;

  /// No description provided for @profileTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get profileTermsAndConditions;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditProfile;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsThemeSystem;

  /// No description provided for @emptyStateDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyStateDefaultTitle;

  /// No description provided for @emptyStateDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Once there\'s activity, it will show up here.'**
  String get emptyStateDefaultMessage;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboardTitle;

  /// No description provided for @adminMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Members'**
  String get adminMembersTitle;

  /// No description provided for @adminLoansTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Loans'**
  String get adminLoansTitle;

  /// No description provided for @adminFundTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Fund'**
  String get adminFundTitle;

  /// No description provided for @adminReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminReportsTitle;

  /// No description provided for @adminNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get adminNotificationsTitle;

  /// No description provided for @adminSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get adminSettingsTitle;

  /// No description provided for @adminAuditTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit Trail'**
  String get adminAuditTitle;

  /// No description provided for @adminContributionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Contributions'**
  String get adminContributionsTitle;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App locked'**
  String get appLockTitle;

  /// No description provided for @appLockPrompt.
  ///
  /// In en, this message translates to:
  /// **'Unlock Hamro Kosh to continue'**
  String get appLockPrompt;

  /// No description provided for @appLockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get appLockUnlock;
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
      <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
