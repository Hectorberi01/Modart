import 'package:flutter/material.dart';

const kDashPrimary = Color(0xFF1C1F2E);
const kDashAccent  = Color(0xFF2F80ED);
const kDashSuccess = Color(0xFF27AE60);
const kDashTextSec = Color(0xFF6B7280);
const kDashBg      = Color(0xFFF7F8FA);

List<BoxShadow> cardShadow() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 4),
      )
    ];
