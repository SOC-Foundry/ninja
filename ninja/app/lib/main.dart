import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'trips.dart';

void main() {
  runApp(const NinjaTripLogApp());
}

class NinjaTripLogApp extends StatelessWidget {
  const NinjaTripLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'Ninja 650 · Trip Log',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C0B10),
        colorScheme: base.colorScheme.copyWith(
          primary: const Color(0xFFFFB23E),
          secondary: const Color(0xFFFFD27A),
          surface: const Color(0xFF15131C),
          onSurface: const Color(0xFFF5EFE3),
        ),
        textTheme: base.textTheme.copyWith(
          displayLarge: GoogleFonts.staatliches(letterSpacing: 0.02, color: const Color(0xFFF5EFE3), fontSize: 42),
          headlineMedium: GoogleFonts.staatliches(letterSpacing: 0.02, color: const Color(0xFFF5EFE3)),
          bodyMedium: const TextStyle(color: Color(0xFFF5EFE3)),
          bodySmall: const TextStyle(color: Color(0xFFB6AE9F)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF15131C),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF2A2733))),
        ),
      ),
      home: const TripLogPage(),
    );
  }
}

class TripLogPage extends StatefulWidget {
  const TripLogPage({super.key});

  @override
  State<TripLogPage> createState() => _TripLogPageState();
}

class _TripLogPageState extends State<TripLogPage> with SingleTickerProviderStateMixin {
  static const _prefTrip = 'selected_trip_id';

  late final TabController _tabController;
  final MapController _mapController = MapController();

  Trip _trip = kBoiseHome;
  int _leg = 0;
  int _timerSec = 10 * 60;
  bool _timerRunning = false;
  List<bool> _checks = List.filled(6, false);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final next = tripById(prefs.getString(_prefTrip));
    if (!mounted) return;
    _selectTrip(next, persist: false);
  }

  Future<void> _selectTrip(Trip next, {bool persist = true}) async {
    _timer?.cancel();
    setState(() {
      _trip = next;
      _leg = 0;
      _timerSec = 10 * 60;
      _timerRunning = false;
      _checks = List.filled(6, false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(next.mapCenter, next.mapZoom);
      } catch (_) {}
    });
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefTrip, next.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timerRunning = true;
      if (_timerSec <= 0) {
        _timerSec = (_leg == _trip.lunchLegIndex ? 60 : 10) * 60;
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSec > 0) {
        setState(() => _timerSec--);
      } else {
        _timer?.cancel();
        setState(() => _timerRunning = false);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
      _timerSec = 0;
    });
  }

  Future<void> _launchGoogleMaps(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps. Check connection or install Maps app.')),
      );
    }
  }

  void _showStopSheet(TripStop stop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D1A26),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: stop.color, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0C0B10), width: 3)),
                child: Center(child: Text(stop.n, style: const TextStyle(color: Color(0xFF160F04), fontWeight: FontWeight.bold, fontSize: 13))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(stop.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFF5EFE3))),
                  Text(stop.town, style: const TextStyle(color: Color(0xFFFFB23E), fontSize: 12, letterSpacing: 0.5)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Text(stop.dish, style: const TextStyle(fontSize: 15, color: Color(0xFFF5EFE3), height: 1.4)),
            if (stop.web != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: () => _launchGoogleMaps(stop.web!), child: const Text('Open website / menu', style: TextStyle(color: Color(0xFFFFB23E)))),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFB23E), foregroundColor: const Color(0xFF160F04)),
                onPressed: () => _launchGoogleMaps(_trip.stopUrl(stop)),
                icon: const Icon(Icons.navigation),
                label: const Text('NAVIGATE IN GOOGLE MAPS (exact next leg)'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Color(0xFFB6AE9F)))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0B10),
        elevation: 0,
        title: Text(
          _trip.appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.w400, letterSpacing: 1.5, fontSize: 18, color: Color(0xFFF5EFE3)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              tooltip: 'Select trip',
              initialValue: _trip.id,
              onSelected: (id) => _selectTrip(tripById(id)),
              color: const Color(0xFF1D1A26),
              offset: const Offset(0, 48),
              itemBuilder: (context) => [
                for (final t in kTrips)
                  PopupMenuItem(
                    value: t.id,
                    child: Text(
                      t.shortName,
                      style: TextStyle(
                        color: t.id == _trip.id ? const Color(0xFFFFB23E) : const Color(0xFFF5EFE3),
                        fontWeight: t.id == _trip.id ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
              ],
              child: Container(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFB23E)),
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF15131C),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('TRIP', style: TextStyle(color: Color(0xFFFFB23E), fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                    SizedBox(width: 4),
                    Icon(Icons.expand_more, color: Color(0xFFFFB23E), size: 22),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFB23E),
          labelColor: const Color(0xFFFFB23E),
          unselectedLabelColor: const Color(0xFFB6AE9F),
          tabs: const [Tab(text: 'COMPANION'), Tab(text: 'MAP'), Tab(text: 'TIMELINE'), Tab(text: 'TIPS')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCompanionTab(),
          _buildMapTab(),
          _buildTimelineTab(),
          _buildTipsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFB23E),
        foregroundColor: const Color(0xFF160F04),
        onPressed: () => _launchGoogleMaps(_trip.fullRouteUrl()),
        icon: const Icon(Icons.navigation),
        label: const Text('FULL ROUTE IN GOOGLE MAPS'),
      ),
    );
  }

  Widget _buildMapTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: FilledButton.icon(onPressed: () => _launchGoogleMaps(_trip.fullRouteUrl()), icon: const Icon(Icons.navigation), label: const Text('FULL ROUTE IN GOOGLE MAPS'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: () => _launchGoogleMaps(_trip.nextLegUrl(0)), icon: const Icon(Icons.navigation), label: const Text('FIRST LEG ONLY'))),
        ]),
      ),
      Expanded(
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _trip.mapCenter, initialZoom: _trip.mapZoom),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.kthompson.ninja_trip_log',
            ),
            MarkerLayer(
              markers: _trip.stops
                  .map(
                    (s) => Marker(
                      point: LatLng(s.lat, s.lng),
                      width: s.small ? 28 : 36,
                      height: s.small ? 28 : 36,
                      child: GestureDetector(
                        onTap: () => _showStopSheet(s),
                        child: Container(
                          decoration: BoxDecoration(
                            color: s.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0C0B10), width: 2),
                            boxShadow: s.ring ? [const BoxShadow(color: Color(0xFFFFD27A), blurRadius: 12, spreadRadius: 2)] : null,
                          ),
                          child: Center(child: Text(s.n, style: const TextStyle(color: Color(0xFF160F04), fontWeight: FontWeight.bold, fontSize: 11))),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xFF15131C),
        child: const Text(
          'Dark overview map. Tap any pin for details. Use the giant amber buttons + FAB to open the real Google Maps app with every waypoint preloaded.',
          style: TextStyle(fontSize: 12, color: Color(0xFFB6AE9F)),
          textAlign: TextAlign.center,
        ),
      ),
      _photoBlock(),
    ]);
  }

  Widget _buildCompanionTab() {
    String fmt(int s) {
      final m = (s ~/ 60).toString().padLeft(2, '0');
      final sec = (s % 60).toString().padLeft(2, '0');
      return '$m:$sec';
    }

    final names = _trip.companionNames;
    final nextLabels = _trip.nextLabels;
    final last = _trip.lastLeg;
    final progressCount = _trip.progressLabels.length;
    final progressAt = _trip.progressIndexForLeg[_leg.clamp(0, _trip.progressIndexForLeg.length - 1)];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_trip.photoFullBleed) ...[
          _photoBlock(),
          const SizedBox(height: 16),
        ],
        Text(_trip.kicker, style: const TextStyle(fontSize: 12, letterSpacing: 2.5, color: Color(0xFFFFD27A))),
        const SizedBox(height: 6),
        Text(_trip.headline, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w400, height: 1.05, color: Color(0xFFF5EFE3))),
        const SizedBox(height: 8),
        Text(_trip.blurb, style: const TextStyle(color: Color(0xFFB6AE9F), fontSize: 15, height: 1.35)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFF15131C), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF2A2733))),
          child: Column(children: [
            const Text('CURRENT / NEXT LEG', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Color(0xFFFFB23E))),
            const SizedBox(height: 6),
            Text(names[_leg], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFFF5EFE3)), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(_leg < last ? 'Tap the giant button below to load exact next destination with voice nav ready.' : _trip.doneBlurb, style: const TextStyle(color: Color(0xFFB6AE9F))),
            const SizedBox(height: 16),
            SizedBox(
              height: 62,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFB23E), foregroundColor: const Color(0xFF160F04), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                onPressed: () => _launchGoogleMaps(_leg < last ? _trip.nextLegUrl(_leg) : _trip.fullRouteUrl()),
                icon: const Icon(Icons.navigation, size: 22),
                label: Text(nextLabels[_leg]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(progressCount, (i) {
            final active = i <= progressAt;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 7,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFFFB23E) : const Color(0xFF2A2733),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final label in _trip.progressLabels)
              Flexible(child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7E7869)), overflow: TextOverflow.ellipsis)),
          ],
        ),
        const SizedBox(height: 18),
        const Text('I AM AT THIS STOP', style: TextStyle(fontSize: 12, letterSpacing: 1.5, color: Color(0xFFFFB23E))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            names.length,
            (i) => ChoiceChip(
              label: Text(names[i], style: const TextStyle(fontSize: 13)),
              selected: _leg == i,
              onSelected: (_) => setState(() => _leg = i),
              selectedColor: const Color(0xFFFFB23E),
              backgroundColor: const Color(0xFF1D1A26),
              labelStyle: TextStyle(color: _leg == i ? const Color(0xFF160F04) : const Color(0xFFF5EFE3)),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFF15131C), border: Border.all(color: const Color(0xFF2A2733)), borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_trip.restTimerHint, style: const TextStyle(fontSize: 12, color: Color(0xFFB6AE9F))),
            const SizedBox(height: 8),
            Text(fmt(_timerSec), style: GoogleFonts.staatliches(fontSize: 54, fontWeight: FontWeight.w400, color: const Color(0xFFF5EFE3), letterSpacing: 2)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFB23E), foregroundColor: const Color(0xFF160F04)),
                  onPressed: _startTimer,
                  child: Text(_timerRunning ? 'RUNNING — RESTART' : 'START / RESTART'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () => setState(() => _timerSec += 5 * 60), child: const Text('+5 MIN')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _stopTimer, child: const Text('CLEAR')),
            ]),
            const SizedBox(height: 16),
            const Text('REST STOP CHECKLIST', style: TextStyle(fontSize: 11, color: Color(0xFF7E7869))),
            const SizedBox(height: 6),
            Wrap(spacing: 12, children: [
              for (int i = 0; i < 6; i++)
                FilterChip(
                  label: Text(['Fuel', 'Water', 'Stretch', 'Smoke', 'Gear', 'Phone'][i]),
                  selected: _checks[i],
                  onSelected: (v) => setState(() => _checks[i] = v),
                ),
            ]),
            const SizedBox(height: 8),
            const Text('Everything here is local only. Perfect for standing at the pump or a booth. Tap the giant nav button the second you’re ready to roll.', style: TextStyle(fontSize: 12, color: Color(0xFF7E7869))),
          ]),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _launchGoogleMaps(_trip.fullRouteUrl()),
          icon: const Icon(Icons.map),
          label: const Text('ALSO OPEN THE FULL ROUTE IN GOOGLE MAPS'),
        ),
        if (!_trip.photoFullBleed) _photoBlock(),
      ]),
    );
  }

  Widget _buildTimelineTab() {
    String? lastDay;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_trip.photoFullBleed) ...[
          _photoBlock(),
          const SizedBox(height: 16),
        ],
        Text(_trip.timelineTitle, style: const TextStyle(fontSize: 26, color: Color(0xFFF5EFE3))),
        const SizedBox(height: 6),
        Text(_trip.timelineBlurb, style: const TextStyle(color: Color(0xFFB6AE9F))),
        const SizedBox(height: 14),
        ..._trip.stops.asMap().entries.expand((e) {
          final i = e.key;
          final s = e.value;
          final widgets = <Widget>[];
          if (s.day != null && s.day != lastDay) {
            lastDay = s.day;
            widgets.add(Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(s.day!, style: const TextStyle(fontSize: 12, letterSpacing: 2, color: Color(0xFFFFB23E))),
            ));
          }
          widgets.add(_StopCard(
            stop: s,
            onNavigate: () => _launchGoogleMaps(i < _trip.lastLeg ? _trip.nextLegUrl(i) : _trip.fullRouteUrl()),
          ));
          return widgets;
        }),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => _launchGoogleMaps(_trip.fullRouteUrl()),
          child: const Text('OPEN ENTIRE ROUTE IN GOOGLE MAPS'),
        ),
        if (!_trip.photoFullBleed) _photoBlock(),
      ],
    );
  }

  Widget _buildTipsTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (_trip.photoFullBleed) ...[
        _photoBlock(),
        const SizedBox(height: 16),
      ],
      Text(_trip.tipsTitle, style: const TextStyle(fontSize: 26, color: Color(0xFFF5EFE3))),
      const SizedBox(height: 12),
      for (final t in _trip.tips) _Tip(icon: t.icon, title: t.title, body: t.body),
      const SizedBox(height: 24),
      Text(_trip.tipsFooter, style: const TextStyle(fontSize: 17, color: Color(0xFFF5EFE3), fontStyle: FontStyle.italic)),
      const SizedBox(height: 8),
      const Text('Ninja 650 trip companion • Love\'s when you can • github.io ready', style: TextStyle(color: Color(0xFF7E7869), fontSize: 12)),
      if (!_trip.photoFullBleed) _photoBlock(),
    ]);
  }

  Widget _photoBlock() {
    final img = Image.asset(
      _trip.photoAsset,
      width: double.infinity,
      fit: _trip.photoFullBleed ? BoxFit.fitWidth : BoxFit.cover,
      alignment: Alignment.center,
      height: _trip.photoFullBleed ? null : 195,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF2A2733), width: 1)),
            boxShadow: [BoxShadow(color: Colors.black, blurRadius: 20, offset: Offset(0, -6))],
          ),
          child: img,
        ),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final TripStop stop;
  final VoidCallback onNavigate;
  const _StopCard({required this.stop, required this.onNavigate});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: stop.color, shape: BoxShape.circle),
                child: Center(child: Text(stop.n, style: const TextStyle(color: Color(0xFF160F04), fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(stop.title, style: const TextStyle(fontSize: 18, color: Color(0xFFF5EFE3))),
                  Text(stop.town, style: const TextStyle(color: Color(0xFFFFB23E), fontSize: 12)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Text(stop.dish, style: const TextStyle(color: Color(0xFFF5EFE3))),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFB23E), foregroundColor: const Color(0xFF160F04)),
                onPressed: onNavigate,
                child: const Text('NAVIGATE (baked waypoint)'),
              ),
            ),
          ]),
        ),
      );
}

class _Tip extends StatelessWidget {
  final String icon;
  final String title;
  final String body;
  const _Tip({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF15131C), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF2A2733))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Color(0xFFFFB23E), fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(color: Color(0xFFB6AE9F), fontSize: 13)),
            ]),
          ),
        ]),
      );
}
