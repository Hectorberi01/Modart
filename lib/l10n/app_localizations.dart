import 'package:flutter/material.dart';
import 'translations/fr.dart';
import 'translations/en.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String> get _strings =>
      locale.languageCode == 'fr' ? frStrings : enStrings;

  String _t(String key) => _strings[key] ?? key;

  // Splash
  String get splashSubtitle => _t('splashSubtitle');
  String get splashFooter => _t('splashFooter');

  // Navigation
  String get navDashboard => _t('navDashboard');
  String get navPosition => _t('navPosition');
  String get navHistory => _t('navHistory');
  String get navSettings => _t('navSettings');

  // Dashboard
  String get dashTitle => _t('dashTitle');
  String get dashPostureWarning => _t('dashPostureWarning');
  String get dashConnected => _t('dashConnected');
  String get dashBtActive => _t('dashBtActive');
  String get dashDisconnected => _t('dashDisconnected');
  String get dashStepsLabel => _t('dashStepsLabel');
  String get dashStepUnit => _t('dashStepUnit');
  String get dashCadenceLabel => _t('dashCadenceLabel');
  String get dashStepsPerMin => _t('dashStepsPerMin');
  String get dashDistanceLabel => _t('dashDistanceLabel');
  String get dashPostureScoreLabel => _t('dashPostureScoreLabel');
  String get dashGlobalScoreLabel => _t('dashGlobalScoreLabel');
  String get dashFinishSession => _t('dashFinishSession');
  String get dashSessionSaved => _t('dashSessionSaved');

  // Bluetooth
  String get btTitle => _t('btTitle');
  String get btEnabled => _t('btEnabled');
  String get btDisabled => _t('btDisabled');
  String get btEnable => _t('btEnable');
  String get btSearchHint => _t('btSearchHint');
  String get btDetectedDevices => _t('btDetectedDevices');
  String get btRefresh => _t('btRefresh');
  String get btNoDevice => _t('btNoDevice');
  String get btUnknownDevice => _t('btUnknownDevice');
  String get btShoeInstruction => _t('btShoeInstruction');
  String get btContinue => _t('btContinue');
  String get btPermissionsDenied => _t('btPermissionsDenied');
  String get btEnableInSettings => _t('btEnableInSettings');
  String get btPermissionsNeeded => _t('btPermissionsNeeded');
  String get btOpenSettings => _t('btOpenSettings');
  String get btRetry => _t('btRetry');
  String get btSignal => _t('btSignal');
  String get btConnected => _t('btConnected');
  String get btConnect => _t('btConnect');
  String get btConnecting => _t('btConnecting');
  String get btDisconnect => _t('btDisconnect');
  String get btOutOfRange => _t('btOutOfRange');

  // History
  String get historyTitle => _t('historyTitle');
  String get historySessions => _t('historySessions');
  String get historyKmTotal => _t('historyKmTotal');
  String get historyStepsTotal => _t('historyStepsTotal');
  String get historyNoSession => _t('historyNoSession');
  String get historyNoSessionDesc => _t('historyNoSessionDesc');
  String get historyError => _t('historyError');

  // Settings
  String get settingsTitle => _t('settingsTitle');
  String get settingsBtSection => _t('settingsBtSection');
  String get settingsBtEnabled => _t('settingsBtEnabled');
  String get settingsBtDisabled => _t('settingsBtDisabled');
  String get settingsManageDevices => _t('settingsManageDevices');
  String get settingsManageDevicesSub => _t('settingsManageDevicesSub');
  String get settingsAutoConnect => _t('settingsAutoConnect');
  String get settingsPrefsSection => _t('settingsPrefsSection');
  String get settingsHaptic => _t('settingsHaptic');
  String get settingsLanguage => _t('settingsLanguage');
  String get settingsLangFr => _t('settingsLangFr');
  String get settingsLangEn => _t('settingsLangEn');
  String get settingsTheme => _t('settingsTheme');
  String get settingsThemeLight => _t('settingsThemeLight');
  String get settingsThemeDark => _t('settingsThemeDark');
  String get settingsThemeSystem => _t('settingsThemeSystem');
  String get settingsAboutSection => _t('settingsAboutSection');
  String get settingsVersion => _t('settingsVersion');
  String get settingsLicenses => _t('settingsLicenses');
  String get settingsClearData => _t('settingsClearData');
  String get settingsClearDataSub => _t('settingsClearDataSub');
  String get settingsClearDialogTitle => _t('settingsClearDialogTitle');
  String get settingsClearDialogMsg => _t('settingsClearDialogMsg');
  String get settingsCancel => _t('settingsCancel');
  String get settingsClearConfirm => _t('settingsClearConfirm');
  String get settingsClearedSnack => _t('settingsClearedSnack');

  // Position
  String get positionTitle => _t('positionTitle');
  String get positionNoShoe => _t('positionNoShoe');
  String get positionNoShoeDesc => _t('positionNoShoeDesc');
  String get positionConnectShoe => _t('positionConnectShoe');
  String get positionPressureMap => _t('positionPressureMap');
  String get positionLiveAnalysis => _t('positionLiveAnalysis');
  String get positionLeft => _t('positionLeft');
  String get positionRight => _t('positionRight');
  String get positionLow => _t('positionLow');
  String get positionMedium => _t('positionMedium');
  String get positionHigh => _t('positionHigh');
  String get positionLeftFoot => _t('positionLeftFoot');
  String get positionRightFoot => _t('positionRightFoot');
  String get positionTotalWeight => _t('positionTotalWeight');

  // Balance
  String get balanceTitle => _t('balanceTitle');
  String get balanceWeightTitle => _t('balanceWeightTitle');
  String get balanceLeft => _t('balanceLeft');
  String get balanceRight => _t('balanceRight');
  String get balanceOptimal => _t('balanceOptimal');
  String get balanceAcceptable => _t('balanceAcceptable');
  String get balanceUnbalanced => _t('balanceUnbalanced');

  // Speed gauge
  String get speedCurrent => _t('speedCurrent');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['fr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
