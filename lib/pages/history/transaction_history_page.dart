import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

// ============================================================
// COLORS
// ============================================================

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

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

class _TransactionHistoryPageState
    extends State<TransactionHistoryPage> {
  // ==========================================================
  // STATE
  // ==========================================================

  bool loading = true;

  String? errorMessage;

  List<Map<String, dynamic>> transactions = [];

  // ==========================================================
  // FIREBASE FUNCTIONS
  // ==========================================================

  FirebaseFunctions get functions =>
      FirebaseFunctions.instance;

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
      final callable =
          functions.httpsCallable(
        'getTransactionHistory',
      );

      final result =
          await callable.call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      final rawTransactions =
          data['transactions'];

      final List<Map<String, dynamic>>
          loadedTransactions = [];

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
        transactions =
            loadedTransactions;

        loading = false;
      });
    } on FirebaseFunctionsException catch (
      error,
    ) {
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
    final createdAt =
        transaction['createdAt'];

    if (createdAt is String &&
        createdAt.isNotEmpty) {
      final date =
          DateTime.tryParse(createdAt);

      if (date != null) {
        final local =
            date.toLocal();

        final day =
            local.day.toString().padLeft(2, '0');

        final month =
            local.month.toString().padLeft(2, '0');

        final year =
            local.year;

        final hour =
            local.hour.toString().padLeft(2, '0');

        final minute =
            local.minute
                .toString()
                .padLeft(2, '0');

        return '$day.$month.$year • '
            '$hour:$minute';
      }
    }

    final date =
        transaction['date'];

    if (date is String &&
        date.isNotEmpty) {
      return date;
    }

    return '';
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
        return Icons.play_circle_outline_rounded;

      default:
        return Icons.swap_horiz_rounded;
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
        return Colors.orangeAccent;

      case 'ad_reward':
        return accentColor;

      default:
        return Colors.blueAccent;
    }
  }

  // ==========================================================
  // TRANSACTION TITLE
  // ==========================================================

  String _transactionTitle(
    Map<String, dynamic> transaction,
  ) {
    final title =
        transaction['title'];

    if (title is String &&
        title.isNotEmpty) {
      return title;
    }

    final type =
        transaction['type'];

    if (type == 'daily_reward') {
      return 'Daily Reward';
    }

    if (type == 'ad_reward') {
      return 'Ad Reward';
    }

    return 'Transaction';
  }

  // ==========================================================
  // BUILD TRANSACTION CARD
  // ==========================================================

  Widget _buildTransactionCard(
    Map<String, dynamic> transaction,
  ) {
    final type =
        transaction['type']?.toString() ??
            '';

    final amount =
        (transaction['amount'] as num?)
                ?.toInt() ??
            0;

    final balanceAfter =
        (transaction['balanceAfter'] as num?)
                ?.toInt() ??
            0;

    final title =
        _transactionTitle(transaction);

    final color =
        _transactionColor(type);

    final date =
        _formatDate(transaction);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        children: [
          // ==================================================
          // ICON
          // ==================================================

          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(16),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                if (date.isNotEmpty)
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.white
                          .withValues(
                        alpha: 0.45,
                      ),
                      fontSize: 12,
                    ),
                  ),

                const SizedBox(height: 4),

                Text(
                  'Balance: $balanceAfter STL',
                  style: TextStyle(
                    color: Colors.white
                        .withValues(
                      alpha: 0.60,
                    ),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // ==================================================
          // AMOUNT
          // ==================================================

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                '+$amount STL',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                '🐾 STL',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
        backgroundColor:
            backgroundColor,

        title: const Text(
          'TRANSACTION HISTORY',
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          onRefresh: _loadTransactions,
          child: _buildBody(),
        ),
      ),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: accentColor,
        ),
      );
    }

    if (errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),

          Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: Colors.white.withValues(
              alpha: 0.35,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: ElevatedButton.icon(
              onPressed:
                  _loadTransactions,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Try Again',
              ),
            ),
          ),
        ],
      );
    }

    if (transactions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),

          Icon(
            Icons.history_rounded,
            size: 70,
            color: accentColor.withValues(
              alpha: 0.35,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'No transactions yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Your STL rewards will appear here. 🐱',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.50,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // ======================================================
        // HEADER
        // ======================================================

        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(
            bottom: 18,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color: accentColor.withValues(
                alpha: 0.20,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: accentColor,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STL Activity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${transactions.length} latest transactions',
                      style: TextStyle(
                        color: Colors.white
                            .withValues(
                          alpha: 0.50,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ======================================================
        // TRANSACTIONS
        // ======================================================

        ...transactions.map(
          _buildTransactionCard,
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}