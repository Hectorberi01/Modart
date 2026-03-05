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
  String t(String key) => _t(key);

  // Splash
  String get splashSubtitle => _t('splashSubtitle');
  String get splashFooter => _t('splashFooter');

  // Navigation
  String get navDashboard => _t('navDashboard');
  String get navPosition => _t('navPosition');
  String get navHistory => _t('navHistory');
  String get navSettings => _t('navSettings');
  String get navLive => _t('navLive');
  String get navTrends => _t('navTrends');
  String get navPro => _t('navPro');
  String get navChildTracking => _t('navChildTracking');

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
  String get dashPressureMap => _t('dashPressureMap');
  String get dashRealTimeAnalysis => _t('dashRealTimeAnalysis');
  String get dashStartSession => _t('dashStartSession');
  String get dashSegment => _t('dashSegment');
  String get dashGlobalScore => _t('dashGlobalScore');
  String get dashSpeed => _t('dashSpeed');
  String get dashBadPosture => _t('dashBadPosture');
  String get dashBtOn => _t('dashBtOn');
  String get dashBtOff => _t('dashBtOff');
  String get dashStart => _t('dashStart');
  String get dashStop => _t('dashStop');

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
  String get historySteps => _t('historySteps');

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

  // Profile
  String get profileEditTooltip => _t('profileEditTooltip');
  String get profilePersonalInfo => _t('profilePersonalInfo');
  String get profileFirstName => _t('profileFirstName');
  String get profileEmail => _t('profileEmail');
  String get profileGender => _t('profileGender');
  String get profileGenderMale => _t('profileGenderMale');
  String get profileGenderFemale => _t('profileGenderFemale');
  String get profileShoeSize => _t('profileShoeSize');
  String get profileShoeSizeEdit => _t('profileShoeSizeEdit');
  String get profileWeight => _t('profileWeight');
  String get profileWeightEdit => _t('profileWeightEdit');
  String get profileHeight => _t('profileHeight');
  String get profileHeightEdit => _t('profileHeightEdit');
  String get profileSave => _t('profileSave');
  String get profileCancel => _t('profileCancel');
  String get profileSaveError => _t('profileSaveError');
  String get profileDefaultName => _t('profileDefaultName');
  String get profileTypeUrban => _t('profileTypeUrban');
  String get profileTypeKids => _t('profileTypeKids');
  String get profileTypePro => _t('profileTypePro');

  // GDPR
  String get gdprTitle => _t('gdprTitle');
  String get gdprCloud => _t('gdprCloud');
  String get gdprAnalytics => _t('gdprAnalytics');
  String get gdprPush => _t('gdprPush');

  // Data & Account
  String get dataSection => _t('dataSection');
  String get dataExport => _t('dataExport');
  String get dataExportWip => _t('dataExportWip');
  String get dataSignOut => _t('dataSignOut');
  String get dataDeleteAccount => _t('dataDeleteAccount');
  String get dataDeleteTitle => _t('dataDeleteTitle');
  String get dataDeleteMsg => _t('dataDeleteMsg');
  String get dataDeleteCancel => _t('dataDeleteCancel');
  String get dataDeleteConfirm => _t('dataDeleteConfirm');

  // Auth
  String get authWelcomeBack => _t('authWelcomeBack');
  String get authWelcomeBackSub => _t('authWelcomeBackSub');
  String get authParentSpace => _t('authParentSpace');
  String get authParentSpaceSub => _t('authParentSpaceSub');
  String get authClinicianSpace => _t('authClinicianSpace');
  String get authClinicianSpaceSub => _t('authClinicianSpaceSub');
  String get authEmail => _t('authEmail');
  String get authEmailHint => _t('authEmailHint');
  String get authEmailRequired => _t('authEmailRequired');
  String get authEmailInvalid => _t('authEmailInvalid');
  String get authPassword => _t('authPassword');
  String get authPasswordRequired => _t('authPasswordRequired');
  String get authProEmail => _t('authProEmail');
  String get authProEmailHint => _t('authProEmailHint');
  String get authCabinetCode => _t('authCabinetCode');
  String get authCabinetCodeHint => _t('authCabinetCodeHint');
  String get authCabinetCodeRequired => _t('authCabinetCodeRequired');
  String get authCabinetCodeEmpty => _t('authCabinetCodeEmpty');
  String get authCabinetCodeInvalid => _t('authCabinetCodeInvalid');
  String get authForgotPassword => _t('authForgotPassword');
  String get authResetSent => _t('authResetSent');
  String get authEnterEmailReset => _t('authEnterEmailReset');
  String get authResetEmailSent => _t('authResetEmailSent');
  String get authLoginSuccess => _t('authLoginSuccess');
  String get authWelcome => _t('authWelcome');
  String get authSignIn => _t('authSignIn');
  String get authNoAccount => _t('authNoAccount');
  String get authRegister => _t('authRegister');
  String get authGdprFooter => _t('authGdprFooter');
  String get authVersionFooter => _t('authVersionFooter');

  // Onboarding
  String get onboardingBiomechanics => _t('onboardingBiomechanics');
  String get onboardingBiomechanicsDesc => _t('onboardingBiomechanicsDesc');
  String get onboardingWalkConscious => _t('onboardingWalkConscious');
  String get onboardingWalkConsciousSub => _t('onboardingWalkConsciousSub');
  String get onboardingWalkConsciousDesc => _t('onboardingWalkConsciousDesc');
  String get onboardingSelectProfile => _t('onboardingSelectProfile');
  String get onboardingSelectProfileSub => _t('onboardingSelectProfileSub');
  String get onboardingUrbanTitle => _t('onboardingUrbanTitle');
  String get onboardingUrbanSub => _t('onboardingUrbanSub');
  String get onboardingKidsTitle => _t('onboardingKidsTitle');
  String get onboardingKidsSub => _t('onboardingKidsSub');
  String get onboardingProTitle => _t('onboardingProTitle');
  String get onboardingProSub => _t('onboardingProSub');
  String get onboardingCreateAccount => _t('onboardingCreateAccount');
  String get onboardingNext => _t('onboardingNext');
  String get onboardingAlreadyAccount => _t('onboardingAlreadyAccount');
  String get onboardingSignIn => _t('onboardingSignIn');

  // Session Summary
  String get summaryTitle => _t('summaryTitle');
  String get summaryGlobalScore => _t('summaryGlobalScore');
  String get summaryHotspot => _t('summaryHotspot');
  String get summaryRoll => _t('summaryRoll');
  String get summaryAsymmetry => _t('summaryAsymmetry');
  String get summaryExcellent => _t('summaryExcellent');
  String get summaryCorrect => _t('summaryCorrect');
  String get summaryVigilance => _t('summaryVigilance');
  String get summaryAlert => _t('summaryAlert');
  String get summaryPainTitle => _t('summaryPainTitle');
  String get summaryPainSubtitle => _t('summaryPainSubtitle');
  String get summaryExportPdf => _t('summaryExportPdf');
  String get summaryShare => _t('summaryShare');
  String get summaryNarrativeForefoot => _t('summaryNarrativeForefoot');
  String get summaryNarrativeRoll => _t('summaryNarrativeRoll');
  String get summaryNarrativeAsymmetryFmt => _t('summaryNarrativeAsymmetryFmt');
  String get summaryNarrativeGood => _t('summaryNarrativeGood');

  // History Trends
  String get trendsTitle => _t('trendsTitle');
  String get trendsGlobalScore => _t('trendsGlobalScore');
  String get trendsPostureScore => _t('trendsPostureScore');
  String get trendsSteps => _t('trendsSteps');
  String get trendsError => _t('trendsError');
  String get trendsEmpty => _t('trendsEmpty');
  String get trendsEmptyDesc => _t('trendsEmptyDesc');
  String get trendsLastSessions => _t('trendsLastSessions');
  String get trendsMean => _t('trendsMean');
  String get trendsTrend => _t('trendsTrend');
  String get trendsSessions => _t('trendsSessions');
  String get trendsStable => _t('trendsStable');
  String get trendsScoreVsPosture => _t('trendsScoreVsPosture');
  String get trendsSessionsFmt => _t('trendsSessionsFmt');
  String get trendsGlobalScoreLegend => _t('trendsGlobalScoreLegend');
  String get trendsPostureLegend => _t('trendsPostureLegend');

  // IMM Report
  String get immTitle => _t('immTitle');
  String get immEvolution => _t('immEvolution');
  String get immSessions => _t('immSessions');
  String get immMaturityScore => _t('immMaturityScore');
  String get immPercentileFmt => _t('immPercentileFmt');
  String get immAboveAvg => _t('immAboveAvg');
  String get immAverage => _t('immAverage');
  String get immBelowAvg => _t('immBelowAvg');
  String get immFarBelowAvg => _t('immFarBelowAvg');
  String get immCadence => _t('immCadence');
  String get immAsymmetry => _t('immAsymmetry');
  String get immDoubleSupport => _t('immDoubleSupport');
  String get immVariability => _t('immVariability');
  String get immNormCadenceFmt => _t('immNormCadenceFmt');
  String get immNormAsymmetry => _t('immNormAsymmetry');
  String get immNormDoubleSupport => _t('immNormDoubleSupport');
  String get immNormVariability => _t('immNormVariability');
  String get immFatigue => _t('immFatigue');
  String get immNoSession => _t('immNoSession');
  String get immNoSessionDesc => _t('immNoSessionDesc');
  String get immNarrativeLow => _t('immNarrativeLow');
  String get immNarrativeFatigue => _t('immNarrativeFatigue');
  String get immNarrativeAsymmetry => _t('immNarrativeAsymmetry');
  String get immNarrativeGood => _t('immNarrativeGood');

  // Pro Dashboard
  String get proTitle => _t('proTitle');
  String get proToolsTitle => _t('proToolsTitle');
  String get proToolsDesc => _t('proToolsDesc');
  String get proAvgScore => _t('proAvgScore');
  String get proAvgPosture => _t('proAvgPosture');
  String get proTotalSteps => _t('proTotalSteps');
  String get proRecentSessions => _t('proRecentSessions');
  String get proNoSession => _t('proNoSession');
  String get proNoSessionDesc => _t('proNoSessionDesc');
  String get proPostureLabel => _t('proPostureLabel');

  // Metric Info
  String get metricWhyImportant => _t('metricWhyImportant');
  String get metricNormalRange => _t('metricNormalRange');
  String get metricAlertAdvice => _t('metricAlertAdvice');
  String get metricTapMore => _t('metricTapMore');

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

  // Zones
  String get zoneForefoot => _t('zoneForefoot');
  String get zoneMidfoot => _t('zoneMidfoot');
  String get zoneHeel => _t('zoneHeel');
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
