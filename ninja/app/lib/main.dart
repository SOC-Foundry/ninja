import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const NinjaTripLogApp());
}

/// Baked-in waypoints from the route log HTML. These power the map markers,
/// popups, and the fully functional Google Maps deep links (with waypoints
/// pre-set for phone navigation).
class TripStop {
  final String n;
  final String title;
  final String town;
  final double lat;
  final double lng;
  final Color color;
  final bool small;
  final bool ring;
  final String dish;
  final String? web;
  final String q; // for Google Maps query / dir

  const TripStop({
    required this.n,
    required this.title,
    required this.town,
    required this.lat,
    required this.lng,
    required this.color,
    this.small = false,
    this.ring = false,
    required this.dish,
    this.web,
    required this.q,
  });
}

const List<TripStop> kStops = [
  // RIDE HOME v4 — Morgan Hill → Mission Viejo • depart 8:30 AM PST • 381 mi
  TripStop(n: "1", title: "Roll Out — Home", town: "MORGAN HILL, CA • 8:30 AM", lat: 37.1305, lng: -121.6544, color: Color(0xFFCFC9BC), dish: "Full tank. Cool dawn. US-101 S → CA-152 E → I-5 S. First 90 min is the best riding of the day.", q: "Morgan Hill, CA"),
  TripStop(n: "2", title: "⛽ Gas & Stretch", town: "COALINGA • I-5 @ CA-198 • ~10:00 AM", lat: 36.1397, lng: -120.3602, color: Color(0xFFFFB23E), dish: "Shell / Chevron / ARCO. 10 min stop. Stretch, water, smoke if you need, fuel. Still the cool part of the morning.", q: "I-5 at CA-198, Coalinga, CA"),
  TripStop(n: "3", title: "🍳 Lunch & Gas", town: "24TH STREET CAFE • BAKERSFIELD • ~11:25 AM", lat: 35.3805, lng: -119.0200, color: Color(0xFFFF5D5D), dish: "1415 24th St, Bakersfield, CA 93301. Classic diner booths. 60 min. Hydrate aggressively — the hot valley leg is next. Fuel on exit.", web: "https://www.yelp.com/biz/24th-street-cafe-bakersfield", q: "1415 24th St, Bakersfield, CA 93301"),
  TripStop(n: "4", title: "⛽ Gas & Stretch", town: "CASTAIC PILOT • I-5 EXIT 176 • ~1:20 PM", lat: 34.4894, lng: -118.6220, color: Color(0xFF4FB6A0), dish: "Pilot Travel Center, 31642 Castaic Rd. Big truck stop, full amenities. 10 min. Last real services before Grapevine. Watch crosswinds on the descent.", q: "Pilot Travel Center, 31642 Castaic Rd, Castaic, CA 91384"),
  TripStop(n: "5", title: "🏁 Home", town: "MISSION VIEJO, CA • ~2:36 PM", lat: 33.6000, lng: -117.6719, color: Color(0xFFFFD27A), ring: true, dish: "Final 88 mi through Santa Clarita and OC. 381 miles complete. Beer earned. Put the bike away and enjoy the reset.", q: "Mission Viejo, CA"),
];

class NinjaTripLogApp extends StatelessWidget {
  const NinjaTripLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'Ride Home · Ninja 650 • June 13 2026',
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
  late final TabController _tabController;
  final MapController _mapController = MapController();

  // Companion State (persists across tab changes)
  int _leg = 0;
  int _timerSec = 10 * 60;
  bool _timerRunning = false;
  final List<bool> _checks = List.filled(6, false);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        _timerSec = (_leg == 2 ? 60 : 10) * 60;
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSec > 0) {
        setState(() {
          _timerSec--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _timerRunning = false;
        });
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
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps. Check connection or install Maps app.')),
        );
      }
    }
  }

  // Ride Home v4 full route with all stops as waypoints (8:30 AM Morgan Hill -> Mission Viejo)
  String _buildFullRouteUrl() {
    const origin = "Morgan Hill, CA";
    const dest = "Mission Viejo, CA";
    const waypts = "Coalinga, CA|1415 24th St, Bakersfield, CA|Castaic, CA";
    return "https://www.google.com/maps/dir/?api=1&travelmode=driving&origin=$origin&destination=$dest&waypoints=$waypts";
  }

  String _buildStopUrl(TripStop s) {
    return "https://www.google.com/maps/dir/?api=1&travelmode=driving&destination=${Uri.encodeComponent(s.q)}";
  }

  // Next leg after a given stop index (for companion one-tap)
  String _nextLegUrl(int stopIdx) {
    if (stopIdx == 0) return "https://www.google.com/maps/dir/?api=1&travelmode=driving&origin=Morgan+Hill%2C+CA&destination=Coalinga%2C+CA";
    if (stopIdx == 1) return "https://www.google.com/maps/dir/?api=1&travelmode=driving&origin=Coalinga%2C+CA&destination=1415+24th+St%2C+Bakersfield%2C+CA";
    if (stopIdx == 2) return "https://www.google.com/maps/dir/?api=1&travelmode=driving&origin=1415+24th+St%2C+Bakersfield%2C+CA&destination=Castaic%2C+CA";
    return "https://www.google.com/maps/dir/?api=1&travelmode=driving&origin=Castaic%2C+CA&destination=Mission+Viejo%2C+CA";
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
                width: 42, height: 42,
                decoration: BoxDecoration(color: stop.color, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0C0B10), width: 3)),
                child: Center(child: Text(stop.n, style: const TextStyle(color: Color(0xFF160F04), fontWeight: FontWeight.bold, fontSize: 13))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(stop.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFF5EFE3))),
                Text(stop.town, style: const TextStyle(color: Color(0xFFFFB23E), fontSize: 12, letterSpacing: 0.5)),
              ])),
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
                onPressed: () => _launchGoogleMaps(_buildStopUrl(stop)),
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
        title: const Text('RIDE HOME • NINJA 650 • 8:30 AM', style: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 1.5, fontSize: 18, color: Color(0xFFF5EFE3))),
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
          _buildCompanionTab(),   // front and center for rest stops
          _buildMapTab(),
          _buildTimelineTab(),
          _buildTipsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFB23E),
        foregroundColor: const Color(0xFF160F04),
        onPressed: () => _launchGoogleMaps(_buildFullRouteUrl()),
        icon: const Icon(Icons.navigation),
        label: const Text('FULL ROUTE IN GOOGLE MAPS'),
      ),
    );
  }

  Widget _buildRouteOverview() {
    // Kept for reference — companion tab is now the star. Simple hero glance.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        const Text('RIDE HOME • JUNE 13 2026', style: TextStyle(fontSize: 12, letterSpacing: 2.5, color: Color(0xFFFFD27A))),
        const SizedBox(height: 6),
        const Text('Morgan Hill → Mission Viejo', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, height: 0.95, color: Color(0xFFF5EFE3))),
        const SizedBox(height: 8),
        const Text('381 miles. Depart 8:30 AM PST. 3 stops. One clean push over the Grapevine. Built as a driving companion you can actually use when you pull over at a truck stop.', style: TextStyle(color: Color(0xFFB6AE9F), fontSize: 15.5, height: 1.35)),
        const SizedBox(height: 18),
        Wrap(spacing: 8, runSpacing: 8, children: const [_Chip('381 mi'), _Chip('8:30 AM depart'), _Chip('~4h 46m ride'), _Chip('2 gas + 60 min lunch'), _Chip('~2:36 PM home')]),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFB23E), foregroundColor: const Color(0xFF160F04), padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
          onPressed: () => _launchGoogleMaps(_buildFullRouteUrl()),
          icon: const Icon(Icons.navigation),
          label: const Text('OPEN FULL ROUTE IN GOOGLE MAPS (all stops baked)'),
        ),
        const SizedBox(height: 28),
        Container(
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFF2A2733)), borderRadius: BorderRadius.circular(18), color: const Color(0xFF15131C)),
          child: const Row(children: [
            Expanded(child: _Stat(k: '8:30A', l: 'Wheels up')),
            Expanded(child: _Stat(k: '381', l: 'miles total')),
            Expanded(child: _Stat(k: '3', l: 'stops')),
            Expanded(child: _Stat(k: '2:36P', l: 'Est. arrival')),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMapTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: FilledButton.icon(onPressed: () => _launchGoogleMaps(_buildFullRouteUrl()), icon: const Icon(Icons.navigation), label: const Text('FULL ROUTE IN GOOGLE MAPS'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: () => _launchGoogleMaps(_nextLegUrl(0)), icon: const Icon(Icons.navigation), label: const Text('FIRST LEG ONLY'))),
        ]),
      ),
      Expanded(
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: const LatLng(35.7, -120.2), initialZoom: 6.3),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a','b','c','d'],
              userAgentPackageName: 'com.kthompson.ninja_trip_log',
            ),
            MarkerLayer(
              markers: kStops.map((s) => Marker(
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
              )).toList(),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xFF15131C),
        child: const Text('Dark overview map. Tap any pin for details. Use the giant amber buttons + FAB to open the real Google Maps app with every waypoint preloaded. Perfect companion at rest stops.', style: TextStyle(fontSize: 12, color: Color(0xFFB6AE9F)), textAlign: TextAlign.center),
      ),
      _bikeFooter(),
    ]);
  }

  // ===================== REST STOP COMPANION TAB (the money feature) =====================
  Widget _buildCompanionTab() {
    String fmt(int s) {
      final m = (s ~/ 60).toString().padLeft(2, '0');
      final sec = (s % 60).toString().padLeft(2, '0');
      return '$m:$sec';
    }

    final names = [
      'DEPART 8:30 • Morgan Hill',
      'GAS 10:00 • Coalinga (I-5/198)',
      'LUNCH 11:25 • 24th St Cafe, BFL',
      'GAS 1:20 • Castaic Pilot',
      'HOME ~2:36 • Mission Viejo'
    ];
    final nextLabels = [
      'NAVIGATE TO COALINGA GAS',
      'NAVIGATE TO BAKERSFIELD LUNCH',
      'NAVIGATE TO CASTAIC GAS',
      'NAVIGATE FINAL — HOME',
      'REPLAY FULL ROUTE'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFF15131C), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF2A2733))),
          child: Column(children: [
            const Text('CURRENT / NEXT LEG', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Color(0xFFFFB23E))),
            const SizedBox(height: 6),
            Text(names[_leg], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Color(0xFFF5EFE3))),
            const SizedBox(height: 4),
            Text(_leg < 4 ? 'Tap the giant button below to load exact next destination with voice nav ready.' : '381 miles. Done. Beer time.', style: const TextStyle(color: Color(0xFFB6AE9F))),
            const SizedBox(height: 16),
            SizedBox(
              height: 62,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFB23E), foregroundColor: const Color(0xFF160F04), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                onPressed: () => _launchGoogleMaps(_leg < 4 ? _nextLegUrl(_leg) : _buildFullRouteUrl()),
                icon: const Icon(Icons.navigation, size: 22),
                label: Text(nextLabels[_leg]),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // Progress stepper
        Row(children: List.generate(5, (i) {
          final active = i <= _leg;
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
        })),
        const SizedBox(height: 6),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Depart', style: TextStyle(fontSize: 10, color: Color(0xFF7E7869))),
          Text('Coalinga', style: TextStyle(fontSize: 10, color: Color(0xFF7E7869))),
          Text('Lunch', style: TextStyle(fontSize: 10, color: Color(0xFF7E7869))),
          Text('Castaic', style: TextStyle(fontSize: 10, color: Color(0xFF7E7869))),
          Text('Home', style: TextStyle(fontSize: 10, color: Color(0xFF7E7869))),
        ]),

        const SizedBox(height: 18),

        // Leg selector — big friendly buttons for when you actually pull over
        const Text('I AM AT THIS STOP', style: TextStyle(fontSize: 12, letterSpacing: 1.5, color: Color(0xFFFFB23E))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: List.generate(5, (i) => ChoiceChip(
          label: Text(names[i], style: const TextStyle(fontSize: 13)),
          selected: _leg == i,
          onSelected: (_) => setState(() => _leg = i),
          selectedColor: const Color(0xFFFFB23E),
          backgroundColor: const Color(0xFF1D1A26),
          labelStyle: TextStyle(color: _leg == i ? const Color(0xFF160F04) : const Color(0xFFF5EFE3)),
        ))),

        const SizedBox(height: 22),

        // Rest timer + checklist — the real rest stop UX
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFF15131C), border: Border.all(color: const Color(0xFF2A2733)), borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('REST TIMER  •  10 min gas / 60 min lunch', style: TextStyle(fontSize: 12, color: Color(0xFFB6AE9F))),
            const SizedBox(height: 8),
            Text(fmt(_timerSec), style: GoogleFonts.staatliches(fontSize: 54, fontWeight: FontWeight.w400, color: const Color(0xFFF5EFE3), letterSpacing: 2)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFB23E), foregroundColor: const Color(0xFF160F04)),
                onPressed: _startTimer,
                child: const Text('START / RESTART'),
              )),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () => setState(() { _timerSec += 5 * 60; }), child: const Text('+5 MIN')),
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
          onPressed: () => _launchGoogleMaps(_buildFullRouteUrl()),
          icon: const Icon(Icons.map),
          label: const Text('ALSO OPEN THE FULL ROUTE IN GOOGLE MAPS'),
        ),
        _bikeFooter(),
      ]),
    );
  }

  Widget _buildTimelineTab() {
    final homeStops = kStops; // already the right 5
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Ride Home — Full Timeline', style: TextStyle(fontSize: 26, color: Color(0xFFF5EFE3))),
        const SizedBox(height: 6),
        const Text('8:30 AM wheels up. All nav buttons preload the exact next destination for one-tap voice guidance at every pull-over.', style: TextStyle(color: Color(0xFFB6AE9F))),
        const SizedBox(height: 14),
        ...homeStops.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          return _StopCard(
            stop: s,
            onNavigate: () => _launchGoogleMaps(i < 4 ? _nextLegUrl(i) : _buildFullRouteUrl()),
          );
        }),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => _launchGoogleMaps(_buildFullRouteUrl()),
          child: const Text('OPEN ENTIRE ROUTE IN GOOGLE MAPS'),
        ),
        _bikeFooter(),
      ],
    );
  }

  Widget _buildTipsTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Fuel Rhythm & Tips — Ride Home', style: TextStyle(fontSize: 26, color: Color(0xFFF5EFE3))),
      const SizedBox(height: 12),
      const _Tip(icon: '⛽', title: 'The 150 Rule', body: 'Top off at or before 150. Coalinga (123), Bakersfield (98 more), Castaic (73) are all comfortable for the Ninja.'),
      const _Tip(icon: '🔥', title: 'Valley Heat After 10:30', body: '90°F+ on the later legs. Mesh gear, drink at every stop, use the full 60 min lunch to cool down and hydrate hard.'),
      const _Tip(icon: '🌬️', title: 'Grapevine Winds', body: 'After Castaic the descent can gust 20+ mph. Loose grip, stay centered in lane. The bike will track fine if you relax.'),
      const _Tip(icon: '📍', title: 'One-Tap Google Maps', body: 'Every amber button + the FAB + Companion tab opens the real Maps app with voice + exact next stop preloaded. This is your driving companion at the pump.'),
      const _Tip(icon: '⏱️', title: 'Rest Stop Discipline', body: 'Use the Companion tab timer + checklist. 10 min gas. 60 min lunch. No lollygagging when it’s already hot.'),
      const _Tip(icon: '🏍️', title: 'The Point', body: 'Present moment. This ride is the antidote. Pull over if you need to. You have time buffers built in.'),
      const SizedBox(height: 24),
      const Text('Ride safe, Kyle. The valley, the heat, the Grapevine — Coalinga • Bakersfield • Castaic then home. One clean push. Enjoy every mile of the reset.', style: TextStyle(fontSize: 17, color: Color(0xFFF5EFE3), fontStyle: FontStyle.italic)),
      const SizedBox(height: 8),
      const Text('RIDE HOME v4 (synced to final-itinerary-home-v4.md) • 8:30 AM PST • optimized rest-stop companion • github.io ready', style: TextStyle(color: Color(0xFF7E7869), fontSize: 12)),
      _bikeFooter(),
    ]);
  }

  Widget _bikeFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF2A2733), width: 1)),
            boxShadow: [BoxShadow(color: Colors.black, blurRadius: 20, offset: Offset(0, -6))],
          ),
          child: Image.asset(
            'assets/images/ninja-bike.jpg',
            height: 195,
            width: double.infinity,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(border: Border.all(color: const Color(0xFF2A2733)), borderRadius: BorderRadius.circular(999), color: const Color(0xFF15131C)),
    child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFFF5EFE3))),
  );
}

class _Stat extends StatelessWidget {
  final String k; final String l;
  const _Stat({required this.k, required this.l});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(k, style: const TextStyle(fontSize: 32, color: Color(0xFFFFB23E), fontWeight: FontWeight.w400)),
    const SizedBox(height: 4),
    Text(l, style: const TextStyle(fontSize: 11, color: Color(0xFFB6AE9F), letterSpacing: 0.8)),
  ]));
}

class _StopCard extends StatelessWidget {
  final TripStop stop; final VoidCallback onNavigate;
  const _StopCard({required this.stop, required this.onNavigate});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: stop.color, shape: BoxShape.circle), child: Center(child: Text(stop.n, style: const TextStyle(color: Color(0xFF160F04), fontWeight: FontWeight.bold)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(stop.title, style: const TextStyle(fontSize: 18, color: Color(0xFFF5EFE3))),
        Text(stop.town, style: const TextStyle(color: Color(0xFFFFB23E), fontSize: 12)),
      ])),
    ]),
    const SizedBox(height: 10),
    Text(stop.dish, style: const TextStyle(color: Color(0xFFF5EFE3))),
    const SizedBox(height: 12),
    Align(alignment: Alignment.centerRight, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFB23E), foregroundColor: const Color(0xFF160F04)), onPressed: onNavigate, child: const Text('NAVIGATE (baked waypoint)'))),
  ])));
}

class _Tip extends StatelessWidget {
  final String icon; final String title; final String body;
  const _Tip({required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF15131C), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF2A2733))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(icon, style: const TextStyle(fontSize: 22)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Color(0xFFFFB23E), fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(body, style: const TextStyle(color: Color(0xFFB6AE9F), fontSize: 13)),
    ])),
  ]));
}
