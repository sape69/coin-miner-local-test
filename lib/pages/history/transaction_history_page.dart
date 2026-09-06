import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../widgets/cat_avatar.dart';
import '../../widgets/stelluriini_logo.dart';

// ============================================================
// STELLA THEME
// ============================================================

const Color backgroundColor = Color(0xFF120B24);
const Color cardColor = Color(0xFF21113B);
const Color accentColor = Color(0xFFB58CFF);
const Color pinkAccentColor = Color(0xFFFFB7E8);
const Color goldAccentColor = Color(0xFFFFD166);

// ============================================================
// TRANSACTION HISTORY PAGE
// ============================================================

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({
    super.key,
  });

  @override
  State<TransactionHistoryPage> createState() =>
      _TransactionHistoryPageState();
}

// ============================================================
// STATE
// ============================================================

class _TransactionHistoryPageState
    extends State<TransactionHistoryPage> {
  bool loading = true;

  String? errorMessage;

  List<Map<String, dynamic>> transactions = [];

  // ==========================================================
  // FIREBASE FUNCTIONS
  // ==========================================================

  FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(
        region: 'us-central1',
      );

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadTransactions();
  }

  // ==========================================================
  // LOAD TRANSACTIONS
  // ==========================================================

  Future<void> _loadTransactions() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      final callable = functions.httpsCallable(
        'getTransactionHistory',
      );

      final result = await callable.call();

      final data = Map<String, dynamic>.from(
        result.data as Map,
      );

      final rawTransactions = data['transactions'];

      final List<Map<String, dynamic>> loadedTransactions = [];

      if (rawTransactions is List) {
        for (final item in rawTransactions) {
          if (item is Map) {
            loadedTransactions.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        transactions = loadedTransactions;
        loading = false;
      });
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            error.message ??
            'Transaction history could not be loaded.';
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Transaction history could not be loaded.';
        loading = false;
      });
    }
  }

  // ==========================================================
  // FORMAT DATE
  // ==========================================================

  String _formatDate(
    Map<String, dynamic> transaction,
  ) {
    final createdAt = transaction['createdAt'];

    if (createdAt is String && createdAt.isNotEmpty) {
      final date = DateTime.tryParse(createdAt);

      if (date != null) {
        final local = date.toLocal();

        final day = local.day.toString().padLeft(2, '0');

        final month = local.month.toString().padLeft(2, '0');

        final year = local.year;

        final hour = local.hour.toString().padLeft(2, '0');

        final minute =
            local.minute.toString().padLeft(2, '0');

        return '$day.$month.$year • $hour:$minute';
      }
    }

    final date = transaction['date'];

    if (date is String && date.isNotEmpty) {
      return date;
    }

    return '';
  }

  // ==========================================================
  // FORMAT STL AMOUNT
  // ==========================================================

  String _formatAmount(
    dynamic value,
  ) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0.0;

    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toStringAsFixed(4);
  }

  // ==========================================================
  // TRANSACTION ICON
  // ==========================================================

  IconData _transactionIcon(
    String type,
  ) {
    switch (type) {
      case 'daily_reward':
        return Icons.card_giftcard_rounded;

      case 'ad_reward':
        return Icons.play_circle_fill_rounded;

      case 'mining':
      case 'mining_reward':
      case 'claim_mining':
        return Icons.bolt_rounded;

      default:
        return Icons.pets_rounded;
    }
  }

  // ==========================================================
  // TRANSACTION COLOR
  // ==========================================================

  Color _transactionColor(
    String type,
  ) {
    switch (type) {
      case 'daily_reward':
        return goldAccentColor;

      case 'ad_reward':
        return pinkAccentColor;

      case 'mining':
      case 'mining_reward':
      case 'claim_mining':
        return accentColor;

      default:
        return accentColor;
    }
  }

  // ==========================================================
  // TRANSACTION TITLE
  // ==========================================================

  String _transactionTitle(
    Map<String, dynamic> transaction,
  ) {
    final title = transaction['title'];

    if (title is String && title.isNotEmpty) {
      return title;
    }

    final type = transaction['type'];

    if (type == 'daily_reward') {
      return 'Daily Stella Bonus';
    }

    if (type == 'ad_reward') {
      return 'Stella Ad Reward';
    }

    if (type == 'mining' ||
        type == 'mining_reward' ||
        type == 'claim_mining') {
      return 'Stella Mining';
    }

    return 'STL Transaction';
  }

  // ==========================================================
  // TRANSACTION DESCRIPTION
  // ==========================================================

  String _transactionDescription(
    String type,
  ) {
    switch (type) {
      case 'daily_reward':
        return 'Daily bonus from Stella';

      case 'ad_reward':
        return 'Rewarded ad bonus';

      case 'mining':
      case 'mining_reward':
      case 'claim_mining':
        return 'Mining reward claimed';

      default:
        return 'Stelluriini activity';
    }
  }

  // ==========================================================
  // BUILD TRANSACTION CARD
  // ==========================================================

  Widget _buildTransactionCard(
    Map<String, dynamic> transaction,
  ) {
    final type =
        transaction['type']?.toString() ?? '';

    final amount = transaction['amount'];

    final balanceAfter = transaction['balanceAfter'];

    final title = _transactionTitle(transaction);

    final description = _transactionDescription(type);

    final color = _transactionColor(type);

    final date = _formatDate(transaction);

    final amountText = _formatAmount(amount);

    final balanceText = _formatAmount(balanceAfter);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withValues(
            alpha: 0.22,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.20,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // TRANSACTION ICON
          // ==================================================

          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: color.withValues(
                  alpha: 0.18,
                ),
              ),
            ),
            child: Icon(
              _transactionIcon(type),
              color: color,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          // ==================================================
          // DETAILS
          // ==================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: TextStyle(
                    color: pinkAccentColor.withValues(
                      alpha: 0.72,
                    ),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (date.isNotEmpty) ...[
                  const SizedBox(height: 6),

                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.42,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ],

                const SizedBox(height: 5),

                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 12,
                      color: Colors.white.withValues(
                        alpha: 0.38,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Balance: $balanceText STL',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: 0.50,
                          ),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ==================================================
          // AMOUNT
          // ==================================================

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                '+$amountText',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 2),

              const Text(
                'STL',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 8),

              Icon(
                Icons.pets_rounded,
                size: 14,
                color: pinkAccentColor.withValues(
                  alpha: 0.55,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(
        bottom: 18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor,
            const Color(0xFF281544),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.25,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(
              alpha: 0.07,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // ==================================================
          // STELLA
          // ==================================================

          const CatAvatar(
            size: 58,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'STELLA ACTIVITY',
                  style: TextStyle(
                    color: pinkAccentColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${transactions.length} latest transactions',
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.55,
                    ),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: goldAccentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'STELLURIINI • SOLANA',
                      style: TextStyle(
                        color: goldAccentColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          const StelluriiniLogo(
            size: 42,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR VIEW
  // ==========================================================

  Widget _buildErrorView() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),

        const CatAvatar(
          size: 86,
        ),

        const SizedBox(height: 20),

        const Text(
          'Stella could not load your history',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          errorMessage ??
              'Transaction history could not be loaded.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: 0.55,
            ),
            fontSize: 14,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 24),

        Center(
          child: ElevatedButton.icon(
            onPressed: _loadTransactions,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: backgroundColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Try Again',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // EMPTY VIEW
  // ==========================================================

  Widget _buildEmptyView() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 70),

        const CatAvatar(
          size: 90,
        ),

        const SizedBox(height: 20),

        const Text(
          'No transactions yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 9),

        Text(
          'Your STL rewards will appear here. 🐱',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: 0.52,
            ),
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 22),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: pinkAccentColor.withValues(
                alpha: 0.16,
              ),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.pets_rounded,
                color: pinkAccentColor,
                size: 28,
              ),

              const SizedBox(height: 10),

              const Text(
                'Start mining with Stella',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Your mining, daily bonus and ad rewards '
                'will be recorded here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.48,
                  ),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // TRANSACTION LIST
  // ==========================================================

  Widget _buildTransactionList() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        30,
      ),
      children: [
        _buildHeader(),

        // ======================================================
        // TRANSACTIONS
        // ======================================================

        ...transactions.map(
          _buildTransactionCard,
        ),

        const SizedBox(height: 8),

        // ======================================================
        // FOOTER
        // ======================================================

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor.withValues(
              alpha: 0.70,
            ),
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withValues(
                alpha: 0.12,
              ),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.pets_rounded,
                color: pinkAccentColor,
                size: 22,
              ),

              const SizedBox(height: 8),

              const Text(
                'STELLA • STL',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Every reward is part of your Stelluriini journey. 🐾',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.42,
                  ),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StelluriiniLogo(
              size: 58,
            ),
            SizedBox(height: 18),
            CircularProgressIndicator(
              color: accentColor,
            ),
            SizedBox(height: 14),
            Text(
              'Stella is checking your history...',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return _buildErrorView();
    }

    if (transactions.isEmpty) {
      return _buildEmptyView();
    }

    return _buildTransactionList();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        titleSpacing: 0,

        title: Row(
          children: [
            const Text(
              'TRANSACTION HISTORY',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.3,
                fontSize: 15,
              ),
            ),

            const SizedBox(width: 8),

            const Text(
              '🐾',
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: loading
                ? null
                : _loadTransactions,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),

          const SizedBox(width: 4),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          backgroundColor: cardColor,
          onRefresh: _loadTransactions,
          child: _buildBody(),
        ),
      ),
    );
  }
}