import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

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
  final String q;
  final String? day;

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
    this.day,
  });
}

class TripTip {
  final String icon;
  final String title;
  final String body;
  const TripTip({required this.icon, required this.title, required this.body});
}

class Trip {
  final String id;
  final String shortName;
  final String appBarTitle;
  final String headline;
  final String kicker;
  final String blurb;
  final String photoAsset;
  final bool photoFullBleed;
  final LatLng mapCenter;
  final double mapZoom;
  final List<TripStop> stops;
  final List<String> companionNames;
  final List<String> nextLabels;
  final List<String> progressLabels;
  final List<int> progressIndexForLeg;
  final List<TripTip> tips;
  final String tipsTitle;
  final String tipsFooter;
  final String doneBlurb;
  final String timelineTitle;
  final String timelineBlurb;
  final String restTimerHint;
  final int lunchLegIndex;

  const Trip({
    required this.id,
    required this.shortName,
    required this.appBarTitle,
    required this.headline,
    required this.kicker,
    required this.blurb,
    required this.photoAsset,
    this.photoFullBleed = false,
    required this.mapCenter,
    required this.mapZoom,
    required this.stops,
    required this.companionNames,
    required this.nextLabels,
    required this.progressLabels,
    required this.progressIndexForLeg,
    required this.tips,
    required this.tipsTitle,
    required this.tipsFooter,
    required this.doneBlurb,
    required this.timelineTitle,
    required this.timelineBlurb,
    required this.restTimerHint,
    this.lunchLegIndex = -1,
  });

  int get lastLeg => stops.length - 1;

  String get origin => stops.first.q;
  String get destination => stops.last.q;
  List<String> get waypoints =>
      stops.length <= 2 ? const [] : stops.sublist(1, stops.length - 1).map((s) => s.q).toList();

  String fullRouteUrl() {
    final o = Uri.encodeComponent(origin);
    final d = Uri.encodeComponent(destination);
    if (waypoints.isEmpty) {
      return 'https://www.google.com/maps/dir/?api=1&travelmode=driving&origin=$o&destination=$d';
    }
    final w = waypoints.map(Uri.encodeComponent).join('%7C');
    return 'https://www.google.com/maps/dir/?api=1&travelmode=driving&origin=$o&destination=$d&waypoints=$w';
  }

  String stopUrl(TripStop s) =>
      'https://www.google.com/maps/dir/?api=1&travelmode=driving&destination=${Uri.encodeComponent(s.q)}';

  String nextLegUrl(int stopIdx) {
    if (stopIdx >= lastLeg) return fullRouteUrl();
    final o = Uri.encodeComponent(stops[stopIdx].q);
    final d = Uri.encodeComponent(stops[stopIdx + 1].q);
    return 'https://www.google.com/maps/dir/?api=1&travelmode=driving&origin=$o&destination=$d';
  }
}

const kRideHome = Trip(
  id: 'ride-home',
  shortName: 'Ride Home',
  appBarTitle: 'RIDE HOME',
  headline: 'Morgan Hill → Mission Viejo',
  kicker: 'RIDE HOME • JUNE 13 2026',
  blurb:
      '381 miles. Depart 8:30 AM PST. 3 stops. One clean push over the Grapevine. Built as a driving companion you can actually use when you pull over at a truck stop.',
  photoAsset: 'assets/images/ninja-bike.jpg',
  mapCenter: LatLng(35.7, -120.2),
  mapZoom: 6.3,
  stops: [
    TripStop(n: '1', title: 'Roll Out — Home', town: 'MORGAN HILL, CA • 8:30 AM', lat: 37.1305, lng: -121.6544, color: Color(0xFFCFC9BC), dish: 'Full tank. Cool dawn. US-101 S → CA-152 E → I-5 S. First 90 min is the best riding of the day.', q: 'Morgan Hill, CA'),
    TripStop(n: '2', title: '⛽ Love\'s & Stretch', town: 'COALINGA • I-5 @ CA-198 • ~10:00 AM', lat: 36.1397, lng: -120.3602, color: Color(0xFFFFB23E), dish: 'Love\'s when you see one on I-5; otherwise Shell / ARCO. 10 min. Stretch, water, smoke if you need, fuel. Still the cool part of the morning.', q: 'I-5 at CA-198, Coalinga, CA'),
    TripStop(n: '3', title: '🍳 Lunch & Gas', town: '24TH STREET CAFE • BAKERSFIELD • ~11:25 AM', lat: 35.3805, lng: -119.0200, color: Color(0xFFFF5D5D), dish: '1415 24th St, Bakersfield, CA 93301. Classic diner booths. 60 min. Hydrate aggressively — the hot valley leg is next. Fuel on exit.', web: 'https://www.yelp.com/biz/24th-street-cafe-bakersfield', q: '1415 24th St, Bakersfield, CA 93301'),
    TripStop(n: '4', title: '⛽ Gas & Stretch', town: 'CASTAIC PILOT • I-5 EXIT 176 • ~1:20 PM', lat: 34.4894, lng: -118.6220, color: Color(0xFF4FB6A0), dish: 'Pilot Travel Center, 31642 Castaic Rd. Big truck stop, full amenities. 10 min. Last real services before Grapevine. Watch crosswinds on the descent.', q: 'Pilot Travel Center, 31642 Castaic Rd, Castaic, CA 91384'),
    TripStop(n: '5', title: '🏁 Home', town: 'MISSION VIEJO, CA • ~2:36 PM', lat: 33.6000, lng: -117.6719, color: Color(0xFFFFD27A), ring: true, dish: 'Final 88 mi through Santa Clarita and OC. 381 miles complete. Beer earned. Put the bike away and enjoy the reset.', q: 'Mission Viejo, CA'),
  ],
  companionNames: [
    'DEPART 8:30 • Morgan Hill',
    'GAS 10:00 • Coalinga (I-5/198)',
    'LUNCH 11:25 • 24th St Cafe, BFL',
    'GAS 1:20 • Castaic Pilot',
    'HOME ~2:36 • Mission Viejo',
  ],
  nextLabels: [
    'NAVIGATE TO COALINGA GAS',
    'NAVIGATE TO BAKERSFIELD LUNCH',
    'NAVIGATE TO CASTAIC GAS',
    'NAVIGATE FINAL — HOME',
    'REPLAY FULL ROUTE',
  ],
  progressLabels: ['Depart', 'Coalinga', 'Lunch', 'Castaic', 'Home'],
  progressIndexForLeg: [0, 1, 2, 3, 4],
  lunchLegIndex: 2,
  restTimerHint: 'REST TIMER  •  10 min gas / 60 min lunch',
  timelineTitle: 'Ride Home — Full Timeline',
  timelineBlurb: '8:30 AM wheels up. All nav buttons preload the exact next destination for one-tap voice guidance at every pull-over.',
  doneBlurb: '381 miles. Done. Beer time.',
  tipsTitle: 'Fuel Rhythm & Tips — Ride Home',
  tipsFooter: 'Ride safe, Kyle. The valley, the heat, the Grapevine — Coalinga • Bakersfield • Castaic then home. One clean push. Enjoy every mile of the reset.',
  tips: [
    TripTip(icon: '⛽', title: 'The 150 Rule', body: 'Top off at or before 150. Prefer Love\'s. Coalinga (123), Bakersfield (98 more), Castaic (73) are all comfortable for the Ninja.'),
    TripTip(icon: '🔥', title: 'Valley Heat After 10:30', body: '90°F+ on the later legs. Mesh gear, drink at every stop, use the full 60 min lunch to cool down and hydrate hard.'),
    TripTip(icon: '🌬️', title: 'Grapevine Winds', body: 'After Castaic the descent can gust 20+ mph. Loose grip, stay centered in lane. The bike will track fine if you relax.'),
    TripTip(icon: '📍', title: 'One-Tap Google Maps', body: 'Every amber button + the FAB + Companion tab opens the real Maps app with voice + exact next stop preloaded.'),
    TripTip(icon: '⏱️', title: 'Rest Stop Discipline', body: 'Use the Companion tab timer + checklist. 10 min gas. 60 min lunch. No lollygagging when it’s already hot.'),
    TripTip(icon: '🏍️', title: 'The Point', body: 'Present moment. This ride is the antidote. Pull over if you need to. You have time buffers built in.'),
  ],
);

const kBoiseHome = Trip(
  id: 'boise-home',
  shortName: 'Boise → Home',
  appBarTitle: 'BOISE → HOME',
  headline: 'Boise → Wells → Primm → Mission Viejo',
  kicker: 'THREE DAYS • AUG 19–21 2026',
  blurb:
      'Wednesday afternoon to Wells. Thursday all day down US-93 to Primm. Friday I-15 home. Love\'s for fuel whenever it exists. Ninja 650, 150-mile rule.',
  photoAsset: 'assets/images/boise-sunset.jpg',
  photoFullBleed: true,
  mapCenter: LatLng(38.6, -115.6),
  mapZoom: 5.2,
  stops: [
    TripStop(
      n: '1',
      title: 'Roll Out — Boise',
      town: 'BOISE, ID • WED AFTERNOON • AUG 19',
      lat: 43.6150,
      lng: -116.2023,
      color: Color(0xFFCFC9BC),
      day: 'WED • AUG 19',
      dish: 'Afternoon departure. Full tank. I-84 E toward Twin Falls / Wells. Heat is the afternoon tax — mesh, water, don’t linger in town.',
      q: 'Boise, ID',
    ),
    TripStop(
      n: '2',
      title: '⛽ Love\'s Bliss',
      town: 'LOVE\'S #812 • I-84 EXIT 141 • ~90 MI',
      lat: 42.9266,
      lng: -114.9468,
      color: Color(0xFFFFB23E),
      day: 'WED • AUG 19',
      dish: '680 US Hwy 30, Bliss, ID 83314. First Love\'s. 10 min. Fuel, water, stretch. If the tank is still fat you can skip it — Jackpot Love\'s #891 (1563 US-93) is the backup before Wells.',
      q: 'Love\'s Travel Stop, 680 US Hwy 30, Bliss, ID 83314',
    ),
    TripStop(
      n: '3',
      title: '🛏️ Night 1 — Wells',
      town: 'LOVE\'S #365 • I-80 EXIT 352 • ~7 PM',
      lat: 41.1113,
      lng: -114.9642,
      color: Color(0xFF4FB6A0),
      day: 'WED • AUG 19',
      dish: '157 Hwy 93 S, Wells, NV 89835. ~250 mi day. Fuel here (McDonald\'s + showers). Grab a Wells motel. Tomorrow is the long US-93 day — do not roll in empty.',
      q: 'Love\'s Travel Stop, 157 Hwy 93 S, Wells, NV 89835',
    ),
    TripStop(
      n: '4',
      title: '⛽ Love\'s Ely',
      town: 'LOVE\'S #691 • US-93 / US-50 • THU MORNING',
      lat: 39.2474,
      lng: -114.8889,
      color: Color(0xFFFFB23E),
      day: 'THU • AUG 20',
      dish: '1701 Great Basin Blvd, Ely, NV 89301. ~70 mi from Wells. Fill even if the light isn\'t on. Next Love\'s is Apex at I-15 — too far without a mid-93 stop.',
      q: 'Love\'s Travel Stop, 1701 Great Basin Blvd, Ely, NV 89301',
    ),
    TripStop(
      n: '5',
      title: '🍳 Lunch & Gas — Caliente',
      town: 'CALIENTE, NV • US-93 • ~140 MI FROM ELY',
      lat: 37.6149,
      lng: -114.5119,
      color: Color(0xFFFF5D5D),
      day: 'THU • AUG 20',
      dish: 'No Love\'s on this stretch. Fill at the pumps in town (25 Spring St / US-93). 45–60 min lunch, hydrate hard. Last real services before the empty run to I-15.',
      q: '25 Spring St, Caliente, NV 89008',
    ),
    TripStop(
      n: '6',
      title: '⛽ Love\'s Apex',
      town: 'LOVE\'S #340 • I-15 EXIT 64 • LAS VEGAS',
      lat: 36.3897,
      lng: -114.8905,
      color: Color(0xFFFFB23E),
      day: 'THU • AUG 20',
      dish: '12501 Apex Great Basin Pkwy, Las Vegas, NV 89165. US-93 dumps you on I-15 here. Fill. Skip the Strip. Last Love\'s before Primm (~45 min south).',
      q: 'Love\'s Travel Stop, 12501 Apex Great Basin Pkwy, Las Vegas, NV 89165',
    ),
    TripStop(
      n: '7',
      title: '🛏️ Night 2 — Primm',
      town: 'PRIMM, NV • I-15 CA BORDER • THU EVENING',
      lat: 35.6105,
      lng: -115.3861,
      color: Color(0xFF4FB6A0),
      ring: true,
      day: 'THU • AUG 20',
      dish: 'All-day US-93 done (~410 mi). Primm Valley / Whiskey Pete\'s / Buffalo Bill\'s. You should already be full from Apex. Friday is I-15 S home.',
      q: 'Primm, NV',
    ),
    TripStop(
      n: '8',
      title: '⛽ Love\'s Barstow',
      town: 'LOVE\'S #374 • I-15 EXIT 178 • FRI MORNING',
      lat: 34.8500,
      lng: -117.0856,
      color: Color(0xFFFFB23E),
      day: 'FRI • AUG 21',
      dish: '2974 Lenwood Rd, Barstow, CA 92311. ~115 mi from Primm. 10 min. Fuel, water, stretch. Last Love\'s before the Cajon and OC.',
      q: 'Love\'s Travel Stop, 2974 Lenwood Rd, Barstow, CA 92311',
    ),
    TripStop(
      n: '9',
      title: '🏁 Home',
      town: 'MISSION VIEJO, CA • FRI AFTERNOON',
      lat: 33.6000,
      lng: -117.6719,
      color: Color(0xFFFFD27A),
      ring: true,
      day: 'FRI • AUG 21',
      dish: 'I-15 S → Cajon → I-215 / I-5 into OC. ~140 mi from Barstow, ~230 from Primm. Bike away. Beer earned. Three days, Boise to home.',
      q: 'Mission Viejo, CA',
    ),
  ],
  companionNames: [
    'DEPART PM • Boise',
    'LOVE\'S • Bliss I-84',
    'NIGHT 1 • Wells Love\'s',
    'LOVE\'S • Ely US-93',
    'LUNCH • Caliente (fill)',
    'LOVE\'S • Apex I-15',
    'NIGHT 2 • Primm',
    'LOVE\'S • Barstow I-15',
    'HOME • Mission Viejo',
  ],
  nextLabels: [
    'NAVIGATE TO LOVE\'S BLISS',
    'NAVIGATE TO WELLS LOVE\'S',
    'NAVIGATE TO ELY LOVE\'S',
    'NAVIGATE TO CALIENTE FILL',
    'NAVIGATE TO APEX LOVE\'S',
    'NAVIGATE TO PRIMM',
    'NAVIGATE TO BARSTOW LOVE\'S',
    'NAVIGATE FINAL — HOME',
    'REPLAY FULL ROUTE',
  ],
  progressLabels: ['Wed Wells', 'Thu Primm', 'Fri Home'],
  progressIndexForLeg: [0, 0, 0, 1, 1, 1, 1, 2, 2],
  lunchLegIndex: 4,
  restTimerHint: 'REST TIMER  •  10 min Love\'s / 60 min Caliente lunch',
  timelineTitle: 'Boise → Home — Three Days',
  timelineBlurb: 'Wed afternoon Boise to Wells. Thu all day US-93 to Primm. Fri I-15 to Mission Viejo. Love\'s whenever it exists. One-tap nav at every pull-over.',
  doneBlurb: 'Home. Three days. Bike away.',
  tipsTitle: 'Fuel Rhythm & Tips — Boise → Home',
  tipsFooter: 'Ride safe, Kyle. Bliss • Wells • Ely • Caliente • Apex • Primm • Barstow then home. Love\'s when you can. Fill when you must. Enjoy the Great Basin.',
  tips: [
    TripTip(icon: '⛽', title: 'Love\'s first', body: 'Bliss #812, Wells #365, Ely #691, Apex #340, Barstow #374. Caliente has no Love\'s — still fill. 150-mile rule stands.'),
    TripTip(icon: '🗺️', title: 'US-93 is the Thursday', body: 'Great Basin Highway Wells → Ely → Caliente → I-15 exit 64. Two-lane, high desert, services far apart. Do not skip Ely or Caliente.'),
    TripTip(icon: '🔥', title: 'August heat', body: 'Wells and Ely sit high. Caliente to Apex and I-15 do not. Mesh, water at every Love\'s, 60 min at Caliente.'),
    TripTip(icon: '🕐', title: 'Time zones', body: 'Boise / Wells / Ely are MDT. Primm and home are PDT (one hour earlier). Thursday is an all-day ride either way.'),
    TripTip(icon: '🎰', title: 'Skip the Strip', body: 'Apex Love\'s (I-15 exit 64) then straight south to Primm. Do not donate an hour to Las Vegas traffic on a tired Thursday.'),
    TripTip(icon: '📍', title: 'One-Tap Google Maps', body: 'Companion giant button, stop chips, FAB, timeline cards — all open Maps with the next baked destination.'),
  ],
);

const List<Trip> kTrips = [kBoiseHome, kRideHome];

Trip tripById(String? id) {
  for (final t in kTrips) {
    if (t.id == id) return t;
  }
  return kBoiseHome;
}
