import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// 🐱 STELLURIINI - ACCOUNT DELETION PAGE
// ============================================================
//
// Account deletion options.
//
// Provides:
// - In-app account deletion
// - External account deletion request page
//
// IMPORTANT:
// The actual Firebase account deletion is handled by HomePage.
// This page only presents the account deletion options.
//
// ============================================================

class AccountDeletionPage extends StatelessWidget {
// ============================================================
// 🎨 STELLA THEME
// ============================================================

static const Color backgroundColor = Color(0xFF120B24);
static const Color surfaceColor = Color(0xFF1A0E31);
static const Color cardColor = Color(0xFF21113B);

static const Color purpleAccentColor = Color(0xFFB58CFF);
static const Color pinkAccentColor = Color(0xFFFFB7E8);
static const Color goldAccentColor = Color(0xFFFFD166);

static const Color primaryTextColor = Color(0xFFF8F4FF);
static const Color secondaryTextColor = Color(0xFFBDB4D1);

static const Color deleteAccountColor = Color(0xFFFF6B7A);

// ============================================================
// 🔗 EXTERNAL DELETION PAGE
// ============================================================

static const String externalDeletionUrl =
'https://stelluriini.web.app/account-deletion.html';

// ============================================================
// 🔧 CALLBACK
// ============================================================

final VoidCallback onDeleteAccountPressed;

const AccountDeletionPage({
super.key,
required this.onDeleteAccountPressed,
});

// ============================================================
// 🌐 OPEN EXTERNAL DELETION PAGE
// ============================================================

Future<void> _openExternalDeletionPage() async {
final Uri uri = Uri.parse(externalDeletionUrl);

try {
  final bool launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!launched) {
    throw Exception(
      'Unable to open account deletion page.',
    );
  }
} catch (error) {
  debugPrint(
    'Account deletion page could not be opened: $error',
  );
}

}

// ============================================================
// 🐱 STELLA ICON
// ============================================================

Widget _buildStellaHeader() {
return Container(
width: 86,
height: 86,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: cardColor,
border: Border.all(
color: purpleAccentColor.withValues(
alpha: 0.55,
),
width: 2,
),
boxShadow: [
BoxShadow(
color: purpleAccentColor.withValues(
alpha: 0.18,
),
blurRadius: 24,
spreadRadius: 2,
),
],
),
child: const Center(
child: Text(
'🐱',
style: TextStyle(
fontSize: 42,
),
),
),
);
}

// ============================================================
// 🗑️ DELETE CARD
// ============================================================

Widget _buildInAppDeleteCard() {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: cardColor,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: deleteAccountColor.withValues(
alpha: 0.35,
),
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
width: 46,
height: 46,
decoration: BoxDecoration(
color: deleteAccountColor.withValues(
alpha: 0.12,
),
borderRadius: BorderRadius.circular(14),
),
child: const Icon(
Icons.delete_forever_rounded,
color: deleteAccountColor,
size: 26,
),
),
const SizedBox(width: 14),
const Expanded(
child: Text(
'Delete your account',
style: TextStyle(
color: primaryTextColor,
fontSize: 19,
fontWeight: FontWeight.w700,
),
),
),
],
),
const SizedBox(height: 16),
const Text(
'You can permanently delete your Stelluriini account '
'and associated account data directly from the app.',
style: TextStyle(
color: secondaryTextColor,
fontSize: 14,
height: 1.5,
),
),
const SizedBox(height: 18),
SizedBox(
width: double.infinity,
child: ElevatedButton.icon(
onPressed: onDeleteAccountPressed,
icon: const Icon(
Icons.delete_forever_rounded,
),
label: const Text(
'Delete Account',
),
style: ElevatedButton.styleFrom(
backgroundColor: deleteAccountColor,
foregroundColor: Colors.white,
minimumSize: const Size(
double.infinity,
52,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(15),
),
textStyle: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w700,
),
),
),
),
],
),
);
}

// ============================================================
// 🌐 EXTERNAL REQUEST CARD
// ============================================================

Widget _buildExternalRequestCard() {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: cardColor,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: purpleAccentColor.withValues(
alpha: 0.28,
),
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
width: 46,
height: 46,
decoration: BoxDecoration(
color: purpleAccentColor.withValues(
alpha: 0.12,
),
borderRadius: BorderRadius.circular(14),
),
child: const Icon(
Icons.language_rounded,
color: purpleAccentColor,
size: 26,
),
),
const SizedBox(width: 14),
const Expanded(
child: Text(
'Cannot access the app?',
style: TextStyle(
color: primaryTextColor,
fontSize: 19,
fontWeight: FontWeight.w700,
),
),
),
],
),
const SizedBox(height: 16),
const Text(
'If you cannot access Stelluriini, you can open our '
'external account deletion page and submit a deletion request.',
style: TextStyle(
color: secondaryTextColor,
fontSize: 14,
height: 1.5,
),
),
const SizedBox(height: 18),
SizedBox(
width: double.infinity,
child: OutlinedButton.icon(
onPressed: _openExternalDeletionPage,
icon: const Icon(
Icons.open_in_new_rounded,
),
label: const Text(
'Open Account Deletion Page',
),
style: OutlinedButton.styleFrom(
foregroundColor: pinkAccentColor,
side: BorderSide(
color: pinkAccentColor.withValues(
alpha: 0.55,
),
),
minimumSize: const Size(
double.infinity,
52,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(15),
),
textStyle: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.w700,
),
),
),
),
],
),
);
}

// ============================================================
// ⚠️ INFORMATION CARD
// ============================================================

Widget _buildInformationCard() {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: surfaceColor,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: goldAccentColor.withValues(
alpha: 0.20,
),
),
),
child: const Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
Icons.info_outline_rounded,
color: goldAccentColor,
size: 22,
),
SizedBox(width: 12),
Expanded(
child: Text(
'Account deletion is permanent. Your Stelluriini '
'account and associated data cannot be restored after deletion.',
style: TextStyle(
color: secondaryTextColor,
fontSize: 13,
height: 1.5,
),
),
),
],
),
);
}

// ============================================================
// 🖥️ BUILD
// ============================================================

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: backgroundColor,
appBar: AppBar(
backgroundColor: backgroundColor,
foregroundColor: primaryTextColor,
elevation: 0,
title: const Text(
'Account Deletion',
style: TextStyle(
color: primaryTextColor,
fontWeight: FontWeight.w700,
),
),
),
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.fromLTRB(
20,
12,
20,
32,
),
child: Column(
children: [
_buildStellaHeader(),
const SizedBox(height: 18),
const Text(
'Stelluriini Account',
textAlign: TextAlign.center,
style: TextStyle(
color: primaryTextColor,
fontSize: 25,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 8),
const Text(
'Manage your account and deletion options',
textAlign: TextAlign.center,
style: TextStyle(
color: secondaryTextColor,
fontSize: 14,
),
),
const SizedBox(height: 28),
_buildInAppDeleteCard(),
const SizedBox(height: 18),
_buildExternalRequestCard(),
const SizedBox(height: 18),
_buildInformationCard(),
],
),
),
),
);
}
}