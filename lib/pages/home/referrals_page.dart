import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ============================================================
// 🐱 STELLURIINI - REFERRALS PAGE
// ============================================================
//
// Stella Community.
//
// Näyttää käyttäjän kutsumat Stelluriini-käyttäjät.
//
// AKTIIVINEN:
//
// Kutsuttu käyttäjä on aktiivinen vain silloin,
// kun hän louhii parhaillaan.
//
// Louhinnan aktiivisuus määritellään:
//
// miningStartedAt
// +
// miningEndsAt
//
// Jos nykyinen aika on miningStartedAt:n ja
// miningEndsAt:n välissä:
//
// 🟢 Aktiivinen
//
// Muussa tapauksessa:
//
// ⚪ Ei aktiivinen
//
// Referral-bonuksen laskenta EI tapahdu tässä tiedostossa.
//
// Backend vastaa referral-bonuksen laskennasta.
//
// ============================================================

class ReferralsPage extends StatelessWidget {
  // ==========================================================
  // 🎨 COLORS
  // ==========================================================

  static const Color backgroundColor =
      Color(0xFF120B24);

  static const Color surfaceColor =
      Color(0xFF1A0E31);

  static const Color cardColor =
      Color(0xFF21113B);

  static const Color purpleColor =
      Color(0xFFB58CFF);

  static const Color pinkColor =
      Color(0xFFFFB7E8);

  static const Color goldColor =
      Color(0xFFFFD166);

  static const Color activeColor =
      Color(0xFF72F6B0);

  static const Color inactiveColor =
      Color(0xFFBDB4D1);

  // ==========================================================
  // 🔐 FIREBASE
  // ==========================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  ReferralsPage({
    super.key,
  });

  // ==========================================================
  // 👤 CURRENT USER
  // ==========================================================

  String? get _currentUserUid {
    return _auth.currentUser?.uid;
  }

  // ==========================================================
  // 📡 REFERRAL STREAM
  // ==========================================================
  //
  // Haetaan käyttäjät, joiden:
  //
  // referral.referrerUid
  //
  // vastaa nykyisen käyttäjän UID:tä.
  //
  // ==========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _referralStream() {
    final String? uid =
        _currentUserUid;

    if (uid == null) {
      return const Stream<
          QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _firestore
        .collection('users')
        .where(
          'referral.referrerUid',
          isEqualTo: uid,
        )
        .snapshots();
  }

  // ==========================================================
  // 🟢 CHECK MINING STATUS
  // ==========================================================
  //
  // Aktiivinen = louhinta käynnissä juuri nyt.
  //
  // ==========================================================

  bool _isMiningActive(
    Map<String, dynamic> data,
  ) {
    final dynamic startedValue =
        data['miningStartedAt'];

    final dynamic endsValue =
        data['miningEndsAt'];

    final Timestamp? startedTimestamp =
        startedValue is Timestamp
            ? startedValue
            : null;

    final Timestamp? endsTimestamp =
        endsValue is Timestamp
            ? endsValue
            : null;

    if (startedTimestamp == null ||
        endsTimestamp == null) {
      return false;
    }

    final DateTime started =
        startedTimestamp.toDate();

    final DateTime ends =
        endsTimestamp.toDate();

    final DateTime now =
        DateTime.now();

    return now.isAfter(started) &&
        now.isBefore(ends);
  }

  // ==========================================================
  // 👤 DISPLAY NAME
  // ==========================================================

  String _getDisplayName(
    Map<String, dynamic> data,
    String uid,
  ) {
    final dynamic displayName =
        data['displayName'];

    if (displayName is String &&
        displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    final dynamic username =
        data['username'];

    if (username is String &&
        username.trim().isNotEmpty) {
      return username.trim();
    }

    final dynamic name =
        data['name'];

    if (name is String &&
        name.trim().isNotEmpty) {
      return name.trim();
    }

    return 'Stelluriini User';
  }

  // ==========================================================
  // 🔤 SHORT UID
  // ==========================================================

  String _shortUid(
    String uid,
  ) {
    if (uid.length <= 10) {
      return uid;
    }

    return '${uid.substring(0, 6)}...'
        '${uid.substring(uid.length - 4)}';
  }

  // ==========================================================
  // 🕐 FORMAT DATE
  // ==========================================================

  String _formatDate(
    dynamic value,
  ) {
    if (value is! Timestamp) {
      return '';
    }

    final DateTime date =
        value.toDate();

    final String day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final String month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final String year =
        date.year.toString();

    return '$day.$month.$year';
  }

  // ==========================================================
  // 🟢 STATUS BADGE
  // ==========================================================

  Widget _statusBadge({
    required bool active,
  }) {
    final Color color =
        active
            ? activeColor
            : inactiveColor;

    final String title =
        active
            ? 'ACTIVE'
            : 'INACTIVE';

    final IconData icon =
        active
            ? Icons
                .bolt_rounded
            : Icons
                .pause_circle_outline_rounded;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color: color.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            title,
            style:
                TextStyle(
              color: color,
              fontSize: 10,
              fontWeight:
                  FontWeight.bold,
              letterSpacing:
                  0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 👤 USER AVATAR
  // ==========================================================

  Widget _userAvatar({
    required bool active,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration:
          BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            purpleColor.withValues(
              alpha: 0.35,
            ),
            pinkColor.withValues(
              alpha: 0.16,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color:
              (active
                      ? activeColor
                      : purpleColor)
                  .withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Icon(
        active
            ? Icons
                .person_rounded
            : Icons
                .person_outline_rounded,
        color:
            active
                ? activeColor
                : purpleColor,
        size: 28,
      ),
    );
  }

  // ==========================================================
  // 👥 REFERRAL USER CARD
  // ==========================================================

  Widget _referralUserCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final String uid =
        document.id;

    final bool active =
        _isMiningActive(
      data,
    );

    final String displayName =
        _getDisplayName(
      data,
      uid,
    );

    final String joinedDate =
        _formatDate(
      data['referral'] is Map
          ? data['referral']
              ['joinedAt']
          : null,
    );

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            cardColor,
            surfaceColor,
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border:
            Border.all(
          color:
              active
                  ? activeColor.withValues(
                      alpha: 0.18,
                    )
                  : purpleColor.withValues(
                      alpha: 0.14,
                    ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.12,
            ),
            blurRadius: 14,
            offset:
                const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          // ==================================================
          // AVATAR
          // ==================================================

          _userAvatar(
            active: active,
          ),

          const SizedBox(
            width: 14,
          ),

          // ==================================================
          // USER INFO
          // ==================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  _shortUid(uid),
                  style:
                      TextStyle(
                    color:
                        Colors.white
                            .withValues(
                      alpha: 0.38,
                    ),
                    fontSize: 10,
                    letterSpacing:
                        0.4,
                  ),
                ),

                if (joinedDate
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    'Joined $joinedDate',
                    style:
                        TextStyle(
                      color:
                          Colors.white
                              .withValues(
                        alpha: 0.40,
                      ),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ==================================================
          // STATUS
          // ==================================================

          _statusBadge(
            active: active,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 📊 STAT CARD
  // ==========================================================

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 16,
        ),
        decoration:
            BoxDecoration(
          color:
              cardColor,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          border:
              Border.all(
            color:
                color.withValues(
              alpha: 0.18,
            ),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration:
                  BoxDecoration(
                color:
                    color.withValues(
                  alpha: 0.10,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),

            const SizedBox(
              height: 9,
            ),

            Text(
              value,
              style:
                  TextStyle(
                color: color,
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              label,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.white
                        .withValues(
                  alpha: 0.48,
                ),
                fontSize: 10,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // 🌟 HEADER
  // ==========================================================

  Widget _header() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        22,
      ),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(0xFF2D174D),
            Color(0xFF1B1033),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          26,
        ),
        border:
            Border.all(
          color:
              purpleColor.withValues(
            alpha: 0.38,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                purpleColor.withValues(
              alpha: 0.10,
            ),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Text(
                '🐾',
                style:
                    TextStyle(
                  fontSize: 24,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                'STELLA COMMUNITY',
                style:
                    TextStyle(
                  color:
                      pinkColor,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                  letterSpacing:
                      1.8,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              const Text(
                '🐾',
                style:
                    TextStyle(
                  fontSize: 24,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'Your invited miners',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.white,
              fontSize: 25,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            'See who is mining right now.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.white.withValues(
                alpha: 0.58,
              ),
              fontSize: 13,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ❌ EMPTY STATE
  // ==========================================================

  Widget _emptyState() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 42,
      ),
      decoration:
          BoxDecoration(
        color:
            cardColor,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        border:
            Border.all(
          color:
              purpleColor.withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration:
                BoxDecoration(
              color:
                  purpleColor.withValues(
                alpha: 0.10,
              ),
              shape:
                  BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_rounded,
              color:
                  purpleColor,
              size: 38,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'No invited miners yet',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.white,
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'Invite friends to build your Stella community.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.white.withValues(
                alpha: 0.50,
              ),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ⚠️ ERROR STATE
  // ==========================================================

  Widget _errorState(
    Object error,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        24,
      ),
      decoration:
          BoxDecoration(
        color:
            cardColor,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border:
            Border.all(
          color:
              Colors.redAccent.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons
                .cloud_off_rounded,
            color:
                Colors.redAccent,
            size: 38,
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'Unable to load referrals',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.white,
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            error.toString(),
            maxLines: 3,
            overflow:
                TextOverflow.ellipsis,
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.white.withValues(
                alpha: 0.45,
              ),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ⏳ LOADING
  // ==========================================================

  Widget _loadingState() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        36,
      ),
      decoration:
          BoxDecoration(
        color:
            cardColor,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border:
            Border.all(
          color:
              purpleColor.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child:
                CircularProgressIndicator(
              strokeWidth: 2.5,
              color:
                  purpleColor,
            ),
          ),
          SizedBox(
            height: 16,
          ),
          Text(
            'Loading Stella community...',
            style:
                TextStyle(
              color:
                  Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🏠 BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'REFERRALS',
          style:
              TextStyle(
            color:
                Colors.white,
            fontSize: 17,
            fontWeight:
                FontWeight.bold,
            letterSpacing:
                2,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream:
            _referralStream(),
        builder:
            (
          BuildContext context,
          AsyncSnapshot<
                  QuerySnapshot<
                      Map<String, dynamic>>>
              snapshot,
        ) {
          if (snapshot.hasError) {
            return ListView(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              children: [
                _header(),
                const SizedBox(
                  height: 16,
                ),
                _errorState(
                  snapshot.error!,
                ),
              ],
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return ListView(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              children: [
                _header(),
                const SizedBox(
                  height: 16,
                ),
                _loadingState(),
              ],
            );
          }

          final List<
                  QueryDocumentSnapshot<
                      Map<String, dynamic>>>
              documents =
              snapshot.data?.docs ??
                  [];

          // ======================================================
          // CALCULATE COUNTS
          // ======================================================

          int activeCount = 0;

          for (final document
              in documents) {
            if (_isMiningActive(
              document.data(),
            )) {
              activeCount++;
            }
          }

          final int totalCount =
              documents.length;

          final int inactiveCount =
              totalCount -
                  activeCount;

          // ======================================================
          // SORT
          // ======================================================
          //
          // Aktiiviset ensin.
          //
          // Tämä tekee näkymästä helpommin seurattavan.
          //
          // ======================================================

          final List<
                  QueryDocumentSnapshot<
                      Map<String, dynamic>>>
              sortedDocuments =
              List.from(
            documents,
          );

          sortedDocuments.sort(
            (
              a,
              b,
            ) {
              final bool activeA =
                  _isMiningActive(
                a.data(),
              );

              final bool activeB =
                  _isMiningActive(
                b.data(),
              );

              if (activeA == activeB) {
                return 0;
              }

              return activeA
                  ? -1
                  : 1;
            },
          );

          // ======================================================
          // CONTENT
          // ======================================================

          return RefreshIndicator(
            color:
                purpleColor,
            backgroundColor:
                cardColor,
            onRefresh: () async {
              await _firestore
                  .collection(
                    'users',
                  )
                  .get(
                    const GetOptions(
                      source:
                          Source.server,
                    ),
                  );
            },
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                28,
              ),
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                _header(),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // STATISTICS
                // ==================================================

                Row(
                  children: [
                    _statCard(
                      icon:
                          Icons.groups_rounded,
                      value:
                          totalCount.toString(),
                      label:
                          'INVITED',
                      color:
                          purpleColor,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    _statCard(
                      icon:
                          Icons
                              .bolt_rounded,
                      value:
                          activeCount.toString(),
                      label:
                          'MINING NOW',
                      color:
                          activeColor,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    _statCard(
                      icon:
                          Icons
                              .pause_circle_outline_rounded,
                      value:
                          inactiveCount
                              .toString(),
                      label:
                          'INACTIVE',
                      color:
                          inactiveColor,
                    ),
                  ],
                ),

                const SizedBox(
                  height: 22,
                ),

                // ==================================================
                // SECTION TITLE
                // ==================================================

                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 22,
                      decoration:
                          BoxDecoration(
                        color:
                            pinkColor,
                        borderRadius:
                            BorderRadius.circular(
                          5,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    const Text(
                      'YOUR COMMUNITY',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing:
                            1.2,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '$totalCount members',
                      style:
                          TextStyle(
                        color:
                            Colors.white
                                .withValues(
                          alpha: 0.40,
                        ),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==================================================
                // EMPTY / LIST
                // ==================================================

                if (sortedDocuments
                    .isEmpty)
                  _emptyState()
                else
                  ...sortedDocuments
                      .map(
                    (
                      document,
                    ) =>
                        _referralUserCard(
                      document,
                    ),
                  ),

                const SizedBox(
                  height: 10,
                ),

                // ==================================================
                // FOOTER INFO
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        cardColor
                            .withValues(
                      alpha: 0.70,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    border:
                        Border.all(
                      color:
                          purpleColor
                              .withValues(
                        alpha: 0.10,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Icon(
                        Icons
                            .info_outline_rounded,
                        color:
                            purpleColor,
                        size: 19,
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: Text(
                          'Active means that the invited user is currently mining. Referral bonuses are calculated securely by the Stelluriini backend.',
                          style:
                              TextStyle(
                            color:
                                Colors.white
                                    .withValues(
                              alpha: 0.48,
                            ),
                            fontSize: 10,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}