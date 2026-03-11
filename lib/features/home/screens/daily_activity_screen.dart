import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:adhan_dart/adhan_dart.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:ponjika/ponjika.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/core/utils/network_utils.dart';
import 'package:first_project/features/announcements/models/announcement_item.dart';
import 'package:first_project/features/announcements/services/announcement_service.dart';
import 'package:first_project/features/quran/models/quran_models.dart';
import 'package:first_project/features/quran/services/quran_api_service.dart';
import 'package:first_project/features/quran/services/quran_last_read_service.dart';
import 'package:first_project/features/quran/screens/surah_detail_screen.dart';
import 'package:first_project/features/home/models/home_activity_models.dart';

part '../controllers/daily_activity_controller_mixin.dart';
part '../widgets/daily_activity_view_mixin.dart';

class DailyActivityScreen extends StatefulWidget {
  const DailyActivityScreen({super.key});

  @override
  State<DailyActivityScreen> createState() => _DailyActivityScreenState();
}

class _DailyActivityScreenState extends State<DailyActivityScreen>
    with DailyActivityControllerMixin, DailyActivityViewMixin {
  @override
  void initState() {
    super.initState();
    initializeDailyActivityController();
  }

  @override
  void dispose() {
    disposeDailyActivityController();
    super.dispose();
  }
}
