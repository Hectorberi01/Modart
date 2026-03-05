import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

const kDashPrimary = SmartSoleColors.biNormal;
const kDashAccent  = SmartSoleColors.biNavy;
const kDashSuccess = SmartSoleColors.biSuccess;
const kDashTextSec = SmartSoleColors.textSecondaryDark;
const kDashBg      = SmartSoleColors.darkBg;

List<BoxShadow> cardShadow() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 4),
      )
    ];
