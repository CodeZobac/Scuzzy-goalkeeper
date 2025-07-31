import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// The title of the application
  ///
  /// In pt, this message translates to:
  /// **'Goalkeeper-Finder'**
  String get appTitle;

  /// Login button text
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get login;

  /// Register button text
  ///
  /// In pt, this message translates to:
  /// **'Registar'**
  String get register;

  /// Create account button text
  ///
  /// In pt, this message translates to:
  /// **'Criar Conta'**
  String get createAccount;

  /// Already have account button text
  ///
  /// In pt, this message translates to:
  /// **'Já tenho conta'**
  String get alreadyHaveAccount;

  /// Loading text
  ///
  /// In pt, this message translates to:
  /// **'A carregar...'**
  String get loading;

  /// Profile tab title
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// Map tab title
  ///
  /// In pt, this message translates to:
  /// **'Mapa'**
  String get map;

  /// Announcements tab title
  ///
  /// In pt, this message translates to:
  /// **'Anúncios'**
  String get announcements;

  /// Notifications tab title
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notifications;

  /// Home tab title
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get home;

  /// Text shown when no image is available
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma imagem disponível'**
  String get noImageAvailable;

  /// Text shown in guest profile
  ///
  /// In pt, this message translates to:
  /// **'Você não está logado'**
  String get youAreNotLoggedIn;

  /// Text prompting user to create account
  ///
  /// In pt, this message translates to:
  /// **'Por favor, crie uma conta'**
  String get pleaseCreateAccount;

  /// Back to home button text
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao Início'**
  String get backToHome;

  /// Restricted access title
  ///
  /// In pt, this message translates to:
  /// **'Acesso Restrito'**
  String get restrictedAccess;

  /// Message when feature requires account
  ///
  /// In pt, this message translates to:
  /// **'Esta funcionalidade requer uma conta.\\nCrie sua conta para continuar e aproveitar todos os recursos.'**
  String get thisFeatureRequiresAccount;

  /// Join community text
  ///
  /// In pt, this message translates to:
  /// **'Junte-se à Comunidade'**
  String get joinCommunity;

  /// Unlock all features text
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueie todos os recursos!'**
  String get unlockAllFeatures;

  /// Participate in matches feature title
  ///
  /// In pt, this message translates to:
  /// **'Participe de Partidas'**
  String get participateInMatches;

  /// Hire goalkeepers feature title
  ///
  /// In pt, this message translates to:
  /// **'Contrate Goleiros'**
  String get hireGoalkeepers;

  /// Personalized profile feature title
  ///
  /// In pt, this message translates to:
  /// **'Perfil Personalizado'**
  String get personalizedProfile;

  /// Find and participate in games description
  ///
  /// In pt, this message translates to:
  /// **'Encontre e participe de jogos na sua região'**
  String get findAndParticipateInGames;

  /// Find professional goalkeepers description
  ///
  /// In pt, this message translates to:
  /// **'Encontre goleiros profissionais disponíveis'**
  String get findProfessionalGoalkeepers;

  /// Create profile and show skills description
  ///
  /// In pt, this message translates to:
  /// **'Crie seu perfil e mostre suas habilidades'**
  String get createProfileShowSkills;
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
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
