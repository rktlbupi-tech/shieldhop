import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presshop_enterprise/features/map/core/map_socket_client.dart';
import 'package:presshop_enterprise/features/map/core/map_socket_constants.dart';
import 'package:presshop_enterprise/features/map/data/models/map_models.dart';

const String _baseUrl = 'https://dev-api.presshop.news:5019/';

class HeatmapApiService {
  late final Dio _dio;

  HeatmapApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? '';
        if (token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  static final HeatmapApiService _instance = HeatmapApiService._();
  factory HeatmapApiService() => _instance;

  Future<List<HeatmapWorker>> getWorkers({
    required double lat,
    required double lng,
    double radiusMiles = 25,
    bool includeSelf = true,
    bool includeStale = true,
  }) async {
    try {
      final response = await _dio.get(
        'enterprise/heatmap/workers',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radiusMiles': radiusMiles,
          'includeSelf': includeSelf,
          'includeStale': includeStale,
        },
      );
      final list = (response.data['data'] ?? []) as List;
      return list.map((e) => HeatmapWorker.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('getWorkers error: $e');
      return [];
    }
  }

  Future<List<HeatmapAlert>> getAlerts({
    required double lat,
    required double lng,
    double radiusMiles = 25,
    String? type,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'lat': lat,
        'lng': lng,
        'radiusMiles': radiusMiles,
      };
      if (type != null && type.isNotEmpty) params['type'] = type;
      final response = await _dio.get('enterprise/heatmap/alerts',
          queryParameters: params);
      final list = (response.data['data'] ?? []) as List;
      return list.map((e) => HeatmapAlert.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('getAlerts error: $e');
      return [];
    }
  }

  Future<void> publishLocation({
    required double lat,
    required double lng,
    double? accuracyMeters,
    DateTime? recordedAt,
    Map<String, dynamic>? address,
  }) async {
    try {
      final body = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'recordedAt': (recordedAt ?? DateTime.now()).toUtc().toIso8601String(),
      };
      if (accuracyMeters != null) body['accuracyMeters'] = accuracyMeters;
      if (address != null && address.isNotEmpty) body['address'] = address;
      await _dio.post('enterprise/heatmap/location', data: body);
    } catch (_) {}
  }
}

class HeatmapSocketService {
  void connect(String token) {
    MapSocketClient.connectHeatmap(token);
    MapSocketClient.heatmapSocket
        ?.on(MapSocketConstants.eventHeatmapError, (data) {
      if (kDebugMode) debugPrint('[MapSocket] error: $data');
    });
  }

  void subscribe({
    required double lat,
    required double lng,
    double radiusMiles = 25,
  }) {
    MapSocketClient.heatmapSocket?.emitWithAck(
      MapSocketConstants.heatmapSubscribe,
      {'lat': lat, 'lng': lng, 'radiusMiles': radiusMiles},
      ack: (_) {},
    );
  }

  void unsubscribe() {
    MapSocketClient.heatmapSocket?.emitWithAck(
      MapSocketConstants.heatmapUnsubscribe,
      {},
      ack: (_) {},
    );
  }

  void shareAlert({
    required String type,
    required String severity,
    required double lat,
    required double lng,
    required String description,
    Map<String, dynamic>? address,
    Map<String, dynamic>? metadata,
  }) {
    final socket = MapSocketClient.heatmapSocket;
    print('[HeatmapSocketService] shareAlert: socket connected? ${socket?.connected}');
    if (socket == null) {
      print('[HeatmapSocketService] ERROR: heatmapSocket is null!');
      return;
    }
    final payload = {
      'type': type,
      'severity': severity,
      'lat': lat,
      'lng': lng,
      'description': description,
      'address': address,
      'metadata': metadata ?? {},
    };
    print('[HeatmapSocketService] Emitting event: ${MapSocketConstants.heatmapAlertShare} with payload: $payload');
    socket.emitWithAck(
      MapSocketConstants.heatmapAlertShare,
      payload,
      ack: (ackData) {
        print('[HeatmapSocketService] shareAlert ACK received: $ackData');
      },
    );
  }

  void onSnapshot(void Function(Map<String, dynamic>) handler) {
    MapSocketClient.heatmapSocket
        ?.on(MapSocketConstants.eventHeatmapSnapshot, (data) {
      handler(Map<String, dynamic>.from(data));
    });
  }

  void onWorkerUpdated(void Function(Map<String, dynamic>) handler) {
    MapSocketClient.heatmapSocket
        ?.on(MapSocketConstants.eventHeatmapWorkerUpdated, (data) {
      handler(Map<String, dynamic>.from(data));
    });
  }

  void onAlertCreated(void Function(Map<String, dynamic>) handler) {
    MapSocketClient.heatmapSocket
        ?.on(MapSocketConstants.eventHeatmapAlertCreated, (data) {
      handler(Map<String, dynamic>.from(data));
    });
  }

  void onAlertUpdated(void Function(Map<String, dynamic>) handler) {
    MapSocketClient.heatmapSocket
        ?.on(MapSocketConstants.eventHeatmapAlertUpdated, (data) {
      handler(Map<String, dynamic>.from(data));
    });
  }

  void clearListeners() {
    MapSocketClient.heatmapSocket
        ?.off(MapSocketConstants.eventHeatmapSnapshot);
    MapSocketClient.heatmapSocket
        ?.off(MapSocketConstants.eventHeatmapWorkerUpdated);
    MapSocketClient.heatmapSocket
        ?.off(MapSocketConstants.eventHeatmapAlertCreated);
    MapSocketClient.heatmapSocket
        ?.off(MapSocketConstants.eventHeatmapAlertUpdated);
    MapSocketClient.heatmapSocket?.off(MapSocketConstants.eventHeatmapError);
  }

  void onSosSessionStarted(void Function(Map<String, dynamic>) handler) {
    MapSocketClient.heatmapSocket
        ?.on(MapSocketConstants.eventSosSessionStarted, (data) {
      handler(Map<String, dynamic>.from(data));
    });
  }

  void onSosSessionResolved(void Function(Map<String, dynamic>) handler) {
    MapSocketClient.heatmapSocket
        ?.on(MapSocketConstants.eventSosSessionResolved, (data) {
      handler(Map<String, dynamic>.from(data));
    });
  }

  void clearSosListeners() {
    MapSocketClient.heatmapSocket
        ?.off(MapSocketConstants.eventSosSessionStarted);
    MapSocketClient.heatmapSocket
        ?.off(MapSocketConstants.eventSosSessionUpdated);
    MapSocketClient.heatmapSocket
        ?.off(MapSocketConstants.eventSosSessionResolved);
  }
}
