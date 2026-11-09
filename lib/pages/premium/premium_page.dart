
import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/premium_subscription_service.dart';

class PremiumPage extends StatefulWidget {
  final String languageCode;

  const PremiumPage({
    super.key,
    this.languageCode = 'fi',
  });

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  static const Color backgroundColor = Color(0xFF120B24);
  static const Color surfaceColor = Color(0xFF1A0E31);
  static const Color cardColor = Color(0xFF21113B);
  static const Color purpleColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color goldColor = Color(0xFFFFD166);
  static const Color primaryTextColor = Color(0xFFF8F4FF);
  static const Color secondaryTextColor = Color(0xFFBDB4D1);
  static const Color errorColor = Color(0xFFFF6B7A);

  late final PremiumSubscriptionService _subscriptionService;

  bool get _isFinnish =>
      widget.languageCode.toLowerCase().startsWith('fi');

  String _text(String fi, String en) => _isFinnish ? fi : en;

  @override
  void initState() {
    super.initState();

    _subscriptionService = PremiumSubscriptionService();
    _subscriptionService.addListener(_onSubscriptionChanged);

    unawaited(_subscriptionService.initialize());
  }

  void _onSubscriptionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _subscriptionService.removeListener(_onSubscriptionChanged);
    _subscriptionService.dispose();
    super.dispose();
  }

  Future<void> _buyPremium() async {
    await _subscriptionService.buyPremium();
  }

  Future<void> _buyPremiumPlus() async {
    await _subscriptionService.buyPremiumPlus();
  }

  Future<void> _restorePurchases() async {
    await _subscriptionService.restorePurchases();
  }

  Future<void> _reloadProducts() async {
    await _subscriptionService.loadProducts();
  }

  String _formatExpiry(DateTime date) {
    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    return '$day.$month.$year';
  }

  String _activeTierName() {
    switch (_subscriptionService.activeTier) {
      case 'premium_plus':
        return 'Premium Plus';
      case 'premium':
        return 'Premium';
      default:
        return _text('Ei aktiivista tilausta', 'No active subscription');
    }
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: purpleColor.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(
              color: purpleColor.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: goldColor,
            size: 43,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'STELLURIINI PREMIUM',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: primaryTextColor,
            fontSize: 23,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _text(
            'Valitse itsellesi sopiva tilaustaso.',
            'Choose the subscription that suits you.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentSubscription() {
    final service = _subscriptionService;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: service.isPremium ? goldColor : purpleColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: goldColor,
                size: 22,
              ),
              const SizedBox(width: 9),
              Text(
                _text('Tilauksesi', 'Your subscription'),
                style: const TextStyle(
                  color: primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _activeTierName(),
            style: const TextStyle(
              color: pinkColor,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (service.premiumExpiresAt != null) ...[
            const SizedBox(height: 6),
            Text(
              _text(
                'Voimassa ${_formatExpiry(service.premiumExpiresAt!)} asti',
                'Valid until ${_formatExpiry(service.premiumExpiresAt!)}',
              ),
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: purpleColor,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: primaryTextColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String subtitle,
    required String price,
    required List<String> features,
    required bool isPlus,
    required VoidCallback? onPressed,
  }) {
    final accentColor = isPlus ? goldColor : purpleColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.65),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isPlus)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PLUS',
                    style: TextStyle(
                      color: goldColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: primaryTextColor,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _text('/ kk', '/ month'),
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          ...features.map(_buildFeature),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: backgroundColor,
                disabledBackgroundColor: accentColor.withValues(alpha: 0.3),
                disabledForegroundColor: primaryTextColor.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Text(
                _text('Tilaa nyt', 'Subscribe now'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreStatus() {
    final service = _subscriptionService;

    if (service.isLoading || service.isVerifying) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: CircularProgressIndicator(
            color: purpleColor,
          ),
        ),
      );
    }

    if (!service.isStoreAvailable) {
      return _buildStatusMessage(
        _text(
          'Google Play -kauppa ei ole tällä hetkellä käytettävissä.',
          'Google Play is currently unavailable.',
        ),
        isError: true,
      );
    }

    if (service.error != null) {
      return _buildStatusMessage(
        service.error!,
        isError: true,
      );
    }

    if (service.message != null) {
      return _buildStatusMessage(
        service.message!,
        isError: false,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatusMessage(
    String message, {
    required bool isError,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isError ? errorColor : purpleColor).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError ? errorColor : purpleColor,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? errorColor : primaryTextColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreButton() {
    return TextButton.icon(
      onPressed: _subscriptionService.isLoading ||
              _subscriptionService.isPurchasePending ||
              _subscriptionService.isVerifying
          ? null
          : _restorePurchases,
      icon: const Icon(
        Icons.restore_rounded,
        color: purpleColor,
      ),
      label: Text(
        _text('Palauta ostot', 'Restore purchases'),
        style: const TextStyle(
          color: purpleColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return Text(
      _text(
        'Tilaukset uusiutuvat automaattisesti kuukausittain, kunnes peruutat ne Google Playn tilausasetuksissa. Hinta ja maksuehdot näytetään Google Playn ostonäkymässä. Tilauksen voi peruuttaa Google Play -kaupan tilausasetuksista.',
        'Subscriptions renew automatically each month until canceled in Google Play subscription settings. The price and payment terms are shown in the Google Play purchase screen. You can cancel your subscription in Google Play settings.',
      ),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: secondaryTextColor,
        fontSize: 11,
        height: 1.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = _subscriptionService;
    final busy = service.isPurchasePending ||
        service.isVerifying ||
        service.isLoading;

    final premiumAvailable = service.premiumProduct != null;
    final premiumPlusAvailable = service.premiumPlusProduct != null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        title: const Text(
          'Premium',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: purpleColor,
          backgroundColor: cardColor,
          onRefresh: _reloadProducts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              _buildHeader(),
              const SizedBox(height: 25),
              _buildCurrentSubscription(),
              const SizedBox(height: 22),
              _buildPlanCard(
                title: 'Premium',
                subtitle: _text(
                  'Stelluriinin Premium-jäsenyys',
                  'Stelluriini Premium membership',
                ),
                price: service.premiumPrice,
                features: [
                  _text('Mainokseton louhintakokemus', 'Ad-free mining experience'),
                  _text('Tehostettu louhintateho', 'Enhanced mining power'),
                ],
                isPlus: false,
                onPressed: premiumAvailable && !busy ? _buyPremium : null,
              ),
              const SizedBox(height: 16),
              _buildPlanCard(
                title: 'Premium Plus',
                subtitle: _text(
                  'Enemmän Premium-etuja',
                  'More Premium benefits',
                ),
                price: service.premiumPlusPrice,
                features: [
                  _text('Mainokseton louhintakokemus', 'Ad-free mining experience'),
                  _text('Automaattinen Power Boost', 'Automatic Power Boost'),
                  _text('Tehostetut louhintapalkkiot', 'Enhanced mining rewards'),
                ],
                isPlus: true,
                onPressed:
                    premiumPlusAvailable && !busy ? _buyPremiumPlus : null,
              ),
              _buildStoreStatus(),
              if (!premiumAvailable || !premiumPlusAvailable) ...[
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: service.isLoading ? null : _reloadProducts,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      _text('Lataa tuotteet uudelleen', 'Reload products'),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: purpleColor,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Center(child: _buildRestoreButton()),
              const SizedBox(height: 20),
              _buildTerms(),
            ],
          ),
        ),
      ),
    );
  }
}
