part of '../screens/daily_activity_screen.dart';

mixin DailyActivityViewMixin
    on State<DailyActivityScreen>, DailyActivityControllerMixin {
  String _text(String english, String bangla) => _isBangla ? bangla : english;

  String _greetingText() {
    final hour = _now.hour;
    if (hour < 12) return _text('Assalamu Alaikum,', 'Assalamu Alaikum,');
    if (hour < 17) return _text('Good Afternoon,', 'Good Afternoon,');
    return _text('Good Evening,', 'Good Evening,');
  }

  String _profileDisplayName([String? rawName]) {
    final value = (rawName ?? profileNameNotifier.value).trim();
    return value;
  }

  bool _hasProfileName([String? rawName]) => _profileDisplayName(rawName).isNotEmpty;

  String _profileInitial([String? rawName]) {
    final name = _profileDisplayName(rawName);
    return name.isEmpty ? 'N' : name[0].toUpperCase();
  }

  ImageProvider<Object>? _profileAvatarImage({
    String? encodedPhoto,
    String? remotePhotoUrl,
  }) {
    final encoded = (encodedPhoto ?? profilePhotoBase64Notifier.value ?? '').trim();
    if (encoded.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(encoded));
      } catch (_) {
        // Fallback to url/default avatar when local image data is invalid.
      }
    }

    final remoteUrl = (remotePhotoUrl ?? profilePhotoUrlNotifier.value ?? '')
        .trim();
    if (remoteUrl.isNotEmpty) {
      return NetworkImage(remoteUrl);
    }
    return null;
  }

  String _activePrayerShortCountdown() {
    final value = _formattedActiveRemaining();
    return _isBangla ? '$value left' : 'in $value';
  }

  String _localizedCount(int value) {
    final raw = value.toString();
    return _isBangla ? _toBanglaDigits(raw) : raw;
  }

  String _localizedDistance(double km) {
    final raw = km.toStringAsFixed(1);
    return _isBangla ? '${_toBanglaDigits(raw)} km' : '$raw km';
  }

  String _prayerMeridiem(String prayer) {
    return prayer == 'Fajr' ? 'AM' : 'PM';
  }

  Duration _remainingToIftar() {
    final target = _nextIftarAt;
    if (target == null) return Duration.zero;
    final remaining = target.difference(_now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get _isDarkTheme => Theme.of(context).brightness == Brightness.dark;

  Color get _glassStart =>
      _isDarkTheme ? const Color(0xFF121F2E) : const Color(0xF7FFFFFF);
  Color get _glassEnd =>
      _isDarkTheme ? const Color(0xFF0D1824) : const Color(0xDBF2F8FD);
  Color get _glassBorder =>
      _isDarkTheme ? const Color(0x22D2F4FF) : const Color(0xCCFFFFFF);
  Color get _glassShadow =>
      _isDarkTheme ? const Color(0x50000000) : const Color(0x260E3853);

  Color get _textPrimary =>
      _isDarkTheme ? Colors.white : const Color(0xFF143349);
  Color get _textSecondary =>
      _isDarkTheme ? const Color(0xFF9BC1D8) : const Color(0xFF5F7E94);
  Color get _textMuted =>
      _isDarkTheme ? const Color(0xFF88AFC7) : const Color(0xFF4D6B82);
  Color get _textWeak =>
      _isDarkTheme ? const Color(0xFFAFC4D4) : const Color(0xFF5D7C91);

  Color get _accentStrong =>
      _isDarkTheme ? const Color(0xFF1FD5C0) : const Color(0xFF1EA8B8);
  Color get _accentSoft =>
      _isDarkTheme ? const Color(0xFF7ED9EE) : const Color(0xFF2EA2BF);

  Color get _surfaceSubtle =>
      _isDarkTheme ? const Color(0xFF172A3A) : const Color(0xECFFFFFF);
  Color get _surfaceStrong =>
      _isDarkTheme ? const Color(0xFF162433) : const Color(0xFFE8F2F8);
  Color get _surfaceBorder =>
      _isDarkTheme ? const Color(0x334F7590) : const Color(0xFFD1E1EC);

  Color get _navBg =>
      _isDarkTheme ? const Color(0xFF0A111B) : const Color(0xE9FFFFFF);
  Color get _navBorder => _isDarkTheme
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFFD5E5EF);

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
    BorderRadiusGeometry radius = const BorderRadius.all(Radius.circular(18)),
  }) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              colors: [_glassStart, _glassEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _glassBorder),
            boxShadow: [
              BoxShadow(
                color: _glassShadow,
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return _buildGlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              ValueListenableBuilder<String>(
                valueListenable: profileNameNotifier,
                builder: (context, profileName, child) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: profilePhotoBase64Notifier,
                    builder: (context, profilePhotoBase64, child) {
                      return ValueListenableBuilder<String?>(
                        valueListenable: profilePhotoUrlNotifier,
                        builder: (context, profilePhotoUrl, child) {
                          final profileImage = _profileAvatarImage(
                            encodedPhoto: profilePhotoBase64,
                            remotePhotoUrl: profilePhotoUrl,
                          );
                          final hasName = _hasProfileName(profileName);
                          return Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _isDarkTheme
                                      ? const Color(0xFF1A2F45)
                                      : const Color(0xFFDDEBF5),
                                  backgroundImage: profileImage,
                                  child: profileImage == null
                                      ? (hasName
                                            ? Text(
                                                _profileInitial(profileName),
                                                style: TextStyle(
                                                  color: _isDarkTheme
                                                      ? Colors.white
                                                      : const Color(0xFF183247),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              )
                                            : Icon(
                                                Icons.auto_awesome_rounded,
                                                size: 18,
                                                color: _isDarkTheme
                                                    ? const Color(0xFF9EE7F4)
                                                    : const Color(0xFF1EA8B8),
                                              ))
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _greetingText(),
                                        style: TextStyle(
                                          color: _isDarkTheme
                                              ? const Color(0xB3D8E5F7)
                                              : const Color(0xFF4B687F),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (hasName)
                                        Text(
                                          _profileDisplayName(profileName),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: _textPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            height: 1,
                                          ),
                                        )
                                      else
                                        InkWell(
                                          onTap: () => Navigator.of(
                                            context,
                                          ).pushNamed(RouteNames.editProfile),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _isDarkTheme
                                                  ? const Color(0x2D2EB8E6)
                                                  : const Color(0x251EA8B8),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: _isDarkTheme
                                                    ? const Color(0x6659C8E4)
                                                    : const Color(0x66A7D7E2),
                                              ),
                                            ),
                                            child: Text(
                                              _text(
                                                'Set your profile name',
                                                'Set your profile name',
                                              ),
                                              style: TextStyle(
                                                color: _accentSoft,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
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
                      );
                    },
                  );
                },
              ),
              Material(
                color: _isDarkTheme
                    ? const Color(0xFF193048)
                    : const Color(0xE8FFFFFF),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () =>
                      Navigator.of(context).pushNamed(RouteNames.preferences),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: _isDarkTheme
                          ? const Color(0xFFB6CFE5)
                          : const Color(0xFF47677E),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: _isDarkTheme
                    ? const Color(0xFF8FB5CC)
                    : const Color(0xFF5D7B93),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _isDarkTheme
                        ? const Color(0xFFB6CFE5)
                        : const Color(0xFF56758E),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                onTap: _refreshLocationFromHeader,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _isDarkTheme
                        ? const Color(0xFF1B344A)
                        : const Color(0xE8FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _isDarkTheme
                          ? const Color(0x3359C8E4)
                          : const Color(0x66B7D5E6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 13, color: _accentSoft),
                      const SizedBox(width: 4),
                      Text(
                        _text('Refresh', 'Refresh'),
                        style: TextStyle(
                          color: _accentSoft,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formattedTime,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  _activeHeaderDate,
                  maxLines: 2,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _isBangla
                  ? '$_formattedHijriDate | $_formattedBanglaDate'
                  : '$_formattedHijriDate | $_formattedBritishDate',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerStrip() {
    return _buildGlassCard(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _text('Prayer Times', 'Prayer Times'),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _isShowingActivePrayer
                    ? '${_localizedActiveRemainingLabel()}: ${_activePrayerShortCountdown()}'
                    : '${_localizedPrayerTimeLabel()}: ${_localizedPrayerTime(_prayerTimes[_displayPrayer] ?? '--:--')}',
                style: TextStyle(
                  color: _accentStrong,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _localizedCountdownLabel(),
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 98,
            child: PageView.builder(
              controller: _prayerPageController,
              itemCount: _prayerOrder.length,
              onPageChanged: (index) {
                final prayer = _prayerOrder[index];
                if (prayer == _activePrayer) {
                  if (_selectedPrayer != null) {
                    setState(() => _selectedPrayer = null);
                  }
                  return;
                }
                if (_selectedPrayer != prayer) {
                  setState(() => _selectedPrayer = prayer);
                }
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildPrayerTimeChip(_prayerOrder[index]),
                );
              },
            ),
          ),
          if (!_isShowingActivePrayer) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: _accentStrong,
                ),
                onPressed: () {
                  setState(() => _selectedPrayer = null);
                  _syncPrayerPageToActive(animate: true);
                },
                icon: const Icon(Icons.my_location_rounded, size: 15),
                label: Text(_text('Back to current', 'Back to current')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerTimeChip(String prayer) {
    final isActive = prayer == _displayPrayer;
    final time = _localizedPrayerTime(_prayerTimes[prayer] ?? '--:--');

    return InkWell(
      onTap: () {
        setState(() => _selectedPrayer = prayer);
        final targetIndex = _prayerOrder.indexOf(prayer);
        if (targetIndex != -1 && _prayerPageController.hasClients) {
          _prayerPageController.animateToPage(
            targetIndex,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF1FD5C0), Color(0xFF1EA8B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive
              ? null
              : (_isDarkTheme
                    ? const Color(0xFF162433)
                    : const Color(0xFFE8F2F8)),
          border: Border.all(
            color: isActive
                ? const Color(0x88A9FFF4)
                : (_isDarkTheme
                      ? const Color(0x334E728E)
                      : const Color(0xFFCADCE9)),
          ),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x4D1FD5C0),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _localizedPrayerName(prayer),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF032F35)
                    : (_isDarkTheme ? Colors.white : const Color(0xFF214259)),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF032F35)
                    : (_isDarkTheme ? Colors.white : const Color(0xFF214259)),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _prayerMeridiem(prayer),
              style: TextStyle(
                color: isActive
                    ? const Color(0xDD032F35)
                    : (_isDarkTheme
                          ? const Color(0xFF86A8BE)
                          : const Color(0xFF5D7C91)),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double? _miniCompassDelta() {
    final heading = _homeHeading;
    final bearing = _homeQiblaBearing;
    if (heading == null || bearing == null) return null;
    return _signedQiblaDelta(bearing, heading);
  }

  String _miniQiblaValueText() {
    const degree = '\u00B0';
    final delta = _miniCompassDelta();
    if (delta == null) return '--';
    final angle = delta.abs().round();
    if (angle == 0) return '0$degree';
    return '$angle$degree ${delta >= 0 ? 'E' : 'W'}';
  }

  Widget _buildMiniCompassDial() {
    final heading = _homeHeading;
    final qiblaBearing = _homeQiblaBearing;
    final dialTurns = heading == null ? 0.0 : -heading / 360;
    final qiblaTurns = (heading != null && qiblaBearing != null)
        ? _signedQiblaDelta(qiblaBearing, heading) / 360
        : null;
    final hasLiveQibla = qiblaTurns != null;
    final northColor = _isDarkTheme
        ? const Color(0xFFD6E6F3)
        : const Color(0xFF2B4A5F);

    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isDarkTheme
                    ? const Color(0x446EA8C9)
                    : const Color(0x66BCD2E1),
              ),
              gradient: RadialGradient(
                colors: _isDarkTheme
                    ? const [Color(0xFF1B3145), Color(0xFF122537)]
                    : const [Color(0xFFFFFFFF), Color(0xFFE8F2F8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: hasLiveQibla
                      ? const Color(0x5521D6C2)
                      : (_isDarkTheme
                            ? const Color(0x22000000)
                            : const Color(0x220E3853)),
                  blurRadius: hasLiveQibla ? (_isDarkTheme ? 18 : 14) : 8,
                  spreadRadius: hasLiveQibla ? 1 : 0,
                ),
              ],
            ),
          ),
          AnimatedRotation(
            turns: dialTurns,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: SizedBox(
              width: 96,
              height: 96,
              child: CustomPaint(
                painter: _MiniCompassMarksPainter(isDark: _isDarkTheme),
              ),
            ),
          ),
          AnimatedRotation(
            turns: dialTurns,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: SizedBox(
              width: 86,
              height: 86,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      'N',
                      style: TextStyle(
                        color: northColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'E',
                      style: TextStyle(
                        color: _textWeak,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: _textWeak,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'W',
                      style: TextStyle(
                        color: _textWeak,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (qiblaTurns != null)
            AnimatedRotation(
              turns: qiblaTurns,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: SizedBox(
                width: 82,
                height: 82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(82, 82),
                      painter: _MiniQiblaNeedlePainter(isDark: _isDarkTheme),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: _MiniKaabaMarker(isDark: _isDarkTheme),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: _accentSoft,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaAndCountdownRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildGlassCard(
            child: InkWell(
              onTap: () =>
                  Navigator.of(context).pushNamed(RouteNames.prayerCompass),
              borderRadius: BorderRadius.circular(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _text('Qibla', 'Qibla'),
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(child: _buildMiniCompassDial()),
                  const SizedBox(height: 8),
                  Text(
                    _text('Qibla Direction: ', 'Qibla Direction: ') +
                        _miniQiblaValueText(),
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildIftarCountdownCard()),
      ],
    );
  }

  Widget _buildIftarCountdownCard() {
    final remaining = _remainingToIftar();
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text('Iftar Countdown', 'Iftar Countdown'),
            style: TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCountdownChip(
                  value: _localizedCount(days),
                  label: _text('Days', 'Days'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildCountdownChip(
                  value: _localizedCount(hours),
                  label: _text('Hours', 'Hours'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildCountdownChip(
                  value: _localizedCount(minutes),
                  label: _text('Min', 'Min'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${_localizedNextSehriLabel()} (${_localizedDawnPrefix()}): ${_localizedTimeOrPlaceholder(_nextSehriAt)}',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_localizedNextIftarLabel()} (${_localizedSunsetPrefix()}): ${_localizedTimeOrPlaceholder(_nextIftarAt)}',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_localizedRemainingLabel()}: ${_formattedIftarRemaining()}',
            style: TextStyle(
              color: _accentStrong,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownChip({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _surfaceBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: _textWeak,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMosquePreviewCard() {
    final items = _nearbyMosquePreview.take(3).toList(growable: false);
    final hasData = items.isNotEmpty;

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _text('Nearby Mosques', 'Nearby Mosques'),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _openFindMosque,
                style: TextButton.styleFrom(
                  foregroundColor: _accentStrong,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(_text('View all', 'View all')),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _openFindMosque,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(minHeight: 132),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: _isDarkTheme
                      ? const [Color(0xFF1A3045), Color(0xFF142435)]
                      : const [Color(0xFFF6FBFF), Color(0xFFE6F1F8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _isDarkTheme
                      ? const Color(0x334F7590)
                      : const Color(0xFFCFDFEA),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  children: [
                    if (hasData) ...[
                      for (final item in items) ...[
                        _buildMosquePreviewPill(
                          name: item.name,
                          distance: _localizedDistance(item.distanceKm),
                        ),
                        if (item != items.last) const SizedBox(height: 8),
                      ],
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 10, 4, 14),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_searching_rounded,
                              size: 18,
                              color: _textWeak,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _text(
                                  'Tap to sync your nearest mosque list',
                                  'Tap to sync your nearest mosque list',
                                ),
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _accentStrong,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _text(
                            hasData ? 'Updated list' : 'Find Mosque',
                            hasData ? 'Updated list' : 'Find Mosque',
                          ),
                          style: TextStyle(
                            color: _isDarkTheme
                                ? const Color(0xFF042A31)
                                : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_nearbyMosquePreviewUpdatedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              _text('Last synced from Find Mosque', 'Last synced from Find Mosque'),
              style: TextStyle(
                color: _textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMosquePreviewPill({
    required String name,
    required String distance,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkTheme ? const Color(0xB2122231) : const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: _isDarkTheme
              ? const Color(0x334F7590)
              : const Color(0xFFD1E1EC),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_city_rounded, size: 16, color: _textWeak),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            distance,
            style: TextStyle(
              color: _accentStrong,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions =
        <({String titleEn, String titleBn, IconData icon, String route})>[
          (
            titleEn: 'Quran',
            titleBn: 'Quran',
            icon: Icons.menu_book_rounded,
            route: RouteNames.quran,
          ),
          (
            titleEn: 'Hadith',
            titleBn: 'Hadith',
            icon: Icons.format_quote_rounded,
            route: RouteNames.hadith,
          ),
          (
            titleEn: 'Dua',
            titleBn: 'Dua',
            icon: Icons.pan_tool_alt_rounded,
            route: RouteNames.dua,
          ),
          (
            titleEn: 'Asma',
            titleBn: 'Asma',
            icon: Icons.auto_stories_rounded,
            route: RouteNames.asma,
          ),
        ];

    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          Expanded(
            child: _buildQuickActionCard(
              title: _text(actions[i].titleEn, actions[i].titleBn),
              icon: actions[i].icon,
              onTap: () => Navigator.of(context).pushNamed(actions[i].route),
            ),
          ),
          if (i != actions.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: _isDarkTheme
                  ? const [Color(0xFF1C2A39), Color(0xFF121E2B)]
                  : const [Color(0xFFF8FCFF), Color(0xFFECF5FB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: _surfaceBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _surfaceStrong,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _accentSoft, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastReadCard() {
    final secondary = _lastReadSecondaryLine();

    return _buildGlassCard(
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, color: _accentSoft, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedLastReadLabel(),
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _lastReadPrimaryLine(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (secondary != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _openLastRead,
            style: FilledButton.styleFrom(
              backgroundColor: _accentStrong,
              foregroundColor: _isDarkTheme
                  ? const Color(0xFF032F35)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            child: Text(_localizedContinueLabel()),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyActivityCard() {
    final progress = _dailyGoal == 0 ? 0.0 : _completedDaily / _dailyGoal;
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _text('Daily Activity', 'Daily Activity'),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${_localizedCount(_completedDaily)}/${_localizedCount(_dailyGoal)}',
                style: TextStyle(
                  color: _accentStrong,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: _isDarkTheme
                  ? const Color(0xFF1B2D3E)
                  : const Color(0xFFD8E7F1),
              valueColor: AlwaysStoppedAnimation<Color>(_accentStrong),
            ),
          ),
          const SizedBox(height: 11),
          ..._activities.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary.withValues(
                          alpha: _isDarkTheme ? 0.9 : 0.88,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_localizedCount(item.done)}/${_localizedCount(item.total)}',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBottomNav() {
    final items = <({String en, String bn, IconData icon, String route})>[
      (
        en: 'Home',
        bn: 'Home',
        icon: Icons.home_filled,
        route: RouteNames.activity,
      ),
      (
        en: 'Discover',
        bn: 'Discover',
        icon: Icons.explore_outlined,
        route: RouteNames.discover,
      ),
      (
        en: 'Quran',
        bn: 'Quran',
        icon: Icons.menu_book_outlined,
        route: RouteNames.quran,
      ),
      (
        en: 'Prayer',
        bn: 'Prayer',
        icon: Icons.calendar_month_outlined,
        route: RouteNames.prayerTimes,
      ),
      (
        en: 'Profile',
        bn: 'Profile',
        icon: Icons.person_outline,
        route: RouteNames.preferences,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      decoration: BoxDecoration(
        color: _navBg,
        border: Border(top: BorderSide(color: _navBorder)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(
              child: _buildBottomNavItem(
                label: _text(items[i].en, items[i].bn),
                icon: items[i].icon,
                active: i == 0,
                onTap: i == 0
                    ? null
                    : () => Navigator.of(
                        context,
                      ).pushReplacementNamed(items[i].route),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback? onTap,
  }) {
    final activeColor = _accentStrong;
    final idleColor = _isDarkTheme
        ? const Color(0xFF7B95A9)
        : const Color(0xFF6E889A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: active ? activeColor : idleColor),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? activeColor : idleColor,
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkTheme
          ? const Color(0xFF060C17)
          : const Color(0xFFF0F7FC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkTheme
                ? const [
                    Color(0xFF060C17),
                    Color(0xFF0A1521),
                    Color(0xFF08111B),
                  ]
                : const [
                    Color(0xFFF7FBFF),
                    Color(0xFFEAF4FB),
                    Color(0xFFF2F8FD),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _isDarkTheme
                        ? const [Color(0x3323DFCC), Color(0x00060C17)]
                        : const [Color(0x4423DFCC), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              right: -90,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _isDarkTheme
                        ? const [Color(0x2230A4CF), Color(0x0008111B)]
                        : const [Color(0x3330A4CF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      color: _isDarkTheme
                          ? const Color(0xFF1FD5C0)
                          : const Color(0xFF1EA8B8),
                      backgroundColor: _isDarkTheme
                          ? const Color(0xFF102233)
                          : const Color(0xFFFFFFFF),
                      onRefresh: () =>
                          _refreshPrayerScheduleFromSource(forceRefresh: true),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                        children: [
                          _buildTopHeader(),
                          const SizedBox(height: 12),
                          _buildPrayerStrip(),
                          const SizedBox(height: 12),
                          _buildQiblaAndCountdownRow(),
                          const SizedBox(height: 12),
                          _buildMosquePreviewCard(),
                          const SizedBox(height: 12),
                          _buildQuickActions(),
                          const SizedBox(height: 12),
                          _buildLastReadCard(),
                          const SizedBox(height: 12),
                          _buildDailyActivityCard(),
                        ],
                      ),
                    ),
                  ),
                  _buildPremiumBottomNav(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCompassMarksPainter extends CustomPainter {
  const _MiniCompassMarksPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final majorTickPaint = Paint()
      ..color = isDark ? const Color(0xFF8AA4B8) : const Color(0xFF6A8EA4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final minorTickPaint = Paint()
      ..color = isDark ? const Color(0xFF9CB3C3) : const Color(0xFF86A5B9)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 36; i++) {
      final angle = (i * 10) * math.pi / 180;
      final major = i % 3 == 0;
      final inner = radius - (major ? 9 : 5);
      final p1 = Offset(
        center.dx + inner * math.sin(angle),
        center.dy - inner * math.cos(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 2) * math.sin(angle),
        center.dy - (radius - 2) * math.cos(angle),
      );
      canvas.drawLine(p1, p2, major ? majorTickPaint : minorTickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniCompassMarksPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _MiniQiblaNeedlePainter extends CustomPainter {
  const _MiniQiblaNeedlePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const tipY = 13.0;
    final needleColor = isDark
        ? const Color(0xFF21D6C2)
        : const Color(0xFF1EA8B8);

    final glowPaint = Paint()
      ..color = isDark ? const Color(0x6621D6C2) : const Color(0x551EA8B8)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final linePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(center.dx, tipY + 10), glowPaint);
    canvas.drawLine(center, Offset(center.dx, tipY + 10), linePaint);

    final arrow = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx - 4.8, tipY + 8)
      ..lineTo(center.dx + 4.8, tipY + 8)
      ..close();
    canvas.drawPath(arrow, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(covariant _MiniQiblaNeedlePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _MiniKaabaMarker extends StatelessWidget {
  const _MiniKaabaMarker({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF0F1E2A) : const Color(0xFFEAF3F9),
        border: Border.all(
          color: isDark ? const Color(0x66FFFFFF) : const Color(0xFFBDD2E2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x5521D6C2) : const Color(0x331EA8B8),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: ClipOval(
        child: Image.asset(
          'assets/kakbah.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.location_on_rounded,
              size: 14,
              color: isDark ? const Color(0xFF21D6C2) : const Color(0xFF1EA8B8),
            );
          },
        ),
      ),
    );
  }
}
