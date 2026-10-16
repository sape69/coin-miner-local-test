import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// 🐱 STELLURIINI - APP UPDATE SERVICE
// ============================================================
//
// Tarkistaa, onko Stelluriinista uudempi versio saatavilla.
//
// Firestore:
//   Collection: app_config
//   Document:   latestVersion
//
// Kentät:
//   version:     "1.0.4"
//   buildNumber: 5
//   updateUrl:   "https://play.google.com/store/apps/details?id=com.stelluriini.app"
//
// Sovellus ei päivitä itseään.
// Google Play hoitaa varsinaisen päivityksen.
//
// ============================================================

class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance =
      AppUpdateService._();

  // ------------------------------------------------------------
  // FIRESTORE
  // ------------------------------------------------------------

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // GOOGLE PLAY
  // ------------------------------------------------------------

  static const String defaultUpdateUrl =
      'https://play.google.com/store/apps/details?id=com.stelluriini.app';

  // ------------------------------------------------------------
  // FIRESTORE PATH
  // ------------------------------------------------------------

  static const String _collectionName = 'app_config';

  static const String _documentName = 'latestVersion';

  // ============================================================
  // CHECK FOR UPDATE
  // ============================================================

  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      // ----------------------------------------------------------
      // Get currently installed app version.
      // ----------------------------------------------------------

      final PackageInfo packageInfo =
          await PackageInfo.fromPlatform();

      final String currentVersion =
          packageInfo.version.trim();

      final int currentBuild =
          int.tryParse(
                packageInfo.buildNumber.trim(),
              ) ??
              0;

      if (currentVersion.isEmpty) {
        return null;
      }

      // ----------------------------------------------------------
      // Read the latest version from Firestore.
      //
      // Source.server is intentional here.
      //
      // We want the update check to use the current server
      // value rather than an old cached value.
      // ----------------------------------------------------------

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection(_collectionName)
              .doc(_documentName)
              .get(
                const GetOptions(
                  source: Source.server,
                ),
              );

      if (!snapshot.exists) {
        // No update configuration exists yet.
        return null;
      }

      final Map<String, dynamic>? data =
          snapshot.data();

      if (data == null) {
        return null;
      }

      // ----------------------------------------------------------
      // Latest version.
      // ----------------------------------------------------------

      final String latestVersion =
          data['version']?.toString().trim() ?? '';

      if (latestVersion.isEmpty) {
        return null;
      }

      // ----------------------------------------------------------
      // Latest build number.
      //
      // Build number is optional.
      // If it does not exist, version number alone is used.
      // ----------------------------------------------------------

      final int latestBuild =
          _parseInt(data['buildNumber']) ?? 0;

      // ----------------------------------------------------------
      // Google Play update URL.
      // ----------------------------------------------------------

      final String firestoreUpdateUrl =
          data['updateUrl']?.toString().trim() ?? '';

      final String updateUrl =
          firestoreUpdateUrl.isNotEmpty
              ? firestoreUpdateUrl
              : defaultUpdateUrl;

      // ----------------------------------------------------------
      // Compare version + build.
      // ----------------------------------------------------------

      final int versionComparison =
          compareVersions(
        currentVersion,
        latestVersion,
      );

      final bool updateAvailable;

      if (versionComparison < 0) {
        // Example:
        // 1.0.3 -> 1.0.4
        updateAvailable = true;
      } else if (versionComparison > 0) {
        // Installed version is newer than the configured
        // version. Do not show an update.
        updateAvailable = false;
      } else {
        // Same version number.
        //
        // Build number can still be newer.
        updateAvailable =
            latestBuild > 0 &&
            latestBuild > currentBuild;
      }

      if (!updateAvailable) {
        return null;
      }

      return AppUpdateInfo(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuild,
        latestVersion: latestVersion,
        latestBuildNumber: latestBuild,
        updateUrl: updateUrl,
      );
    } catch (_) {
      // ----------------------------------------------------------
      // Update checking must NEVER prevent the app from starting.
      //
      // If Firestore is unavailable, the user simply continues
      // using Stelluriini normally.
      // ----------------------------------------------------------

      return null;
    }
  }

  // ============================================================
  // OPEN GOOGLE PLAY
  // ============================================================

  Future<bool> openUpdateUrl(
    String updateUrl,
  ) async {
    final Uri? uri = Uri.tryParse(
      updateUrl.trim(),
    );

    if (uri == null) {
      return false;
    }

    if (!await canLaunchUrl(uri)) {
      return false;
    }

    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  // ============================================================
  // VERSION COMPARISON
  // ============================================================
  //
  // Examples:
  //
  // 1.0.3 < 1.0.4
  // 1.0.9 < 1.0.10
  // 1.1.0 > 1.0.9
  // 2.0.0 > 1.9.9
  //
  // Returns:
  //
  // -1 = first version is older
  //  0 = versions are equal
  //  1 = first version is newer
  //
  // ============================================================

  static int compareVersions(
    String first,
    String second,
  ) {
    final List<int> firstParts =
        _versionParts(first);

    final List<int> secondParts =
        _versionParts(second);

    final int length =
        firstParts.length > secondParts.length
            ? firstParts.length
            : secondParts.length;

    for (int i = 0; i < length; i++) {
      final int firstValue =
          i < firstParts.length
              ? firstParts[i]
              : 0;

      final int secondValue =
          i < secondParts.length
              ? secondParts[i]
              : 0;

      if (firstValue < secondValue) {
        return -1;
      }

      if (firstValue > secondValue) {
        return 1;
      }
    }

    return 0;
  }

  // ============================================================
  // VERSION PARTS
  // ============================================================

  static List<int> _versionParts(
    String version,
  ) {
    final String cleaned =
        version.trim().split('+').first;

    if (cleaned.isEmpty) {
      return const <int>[0];
    }

    return cleaned
        .split('.')
        .map(
          (String part) =>
              int.tryParse(part.trim()) ?? 0,
        )
        .toList();
  }

  // ============================================================
  // INTEGER PARSER
  // ============================================================

  static int? _parseInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(
        value.trim(),
      );
    }

    return null;
  }
}

// ============================================================
// 🐱 UPDATE INFORMATION
// ============================================================

class AppUpdateInfo {
  final String currentVersion;
  final int currentBuildNumber;

  final String latestVersion;
  final int latestBuildNumber;

  final String updateUrl;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.updateUrl,
  });
}