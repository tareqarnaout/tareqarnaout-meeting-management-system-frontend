import 'package:flutter/material.dart';

class AppColors {
  // Sidebar — white background with teal accents
  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color sidebarActiveItem = Color(0xFFE0F7FA); // light cyan/teal bg
  static const Color sidebarText = Color(0xFF4B5563); // dark gray
  static const Color sidebarActiveText = Color(0xFF2E7D9E); // teal accent
  static const Color sidebarAccent = Color(0xFF2E7D9E);

  // Primary actions — unified teal palette
  static const Color primaryTeal = Color(0xFF2E7D9E);
  static const Color primaryBlue = Color(0xFF2E7D9E); // teal (replacing old blue)

  // Status colors
  static const Color statusDraft = Color(0xFFEF4444);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusApproved = Color(0xFF10B981);
  static const Color statusFinalized = Color(0xFF2E7D9E); // teal (replacing indigo)

  // Backgrounds
  static const Color pageBg = Color(0xFFF8F9FA);
  static const Color cardBg = Colors.white;
  static const Color headerBg = Colors.white;

  // Text — dark slate/navy, not pure black
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Borders
  static const Color border = Color(0xFFD1D5DB); // slightly more visible gray-300
  static const Color divider = Color(0xFFF1F5F9);

  // Login gradient — soft pastel rainbow matching the screenshot
  static const List<Color> loginGradient = [
    Color(0xFFE8A0BF), // soft rose/pink
    Color(0xFFF4B183), // peach/salmon
    Color(0xFFF9D776), // warm yellow
    Color(0xFF7EC8A0), // muted green
    Color(0xFF6BA3D6), // soft blue
    Color(0xFF9B8EC4), // muted purple
  ];
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class AppDecorations {
  static BoxDecoration card = BoxDecoration(
    color: AppColors.cardBg,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration cardWithBorder = BoxDecoration(
    color: AppColors.cardBg,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static InputDecoration inputDecoration(String label, {String? hint, Widget? suffixIcon, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
