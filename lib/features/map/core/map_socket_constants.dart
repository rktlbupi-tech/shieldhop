class MapSocketConstants {
  // Emitters
  static const String heatmapSubscribe = 'heatmap.subscribe';
  static const String heatmapUnsubscribe = 'heatmap.unsubscribe';
  static const String heatmapLocationUpdate = 'heatmap.location.update';
  static const String heatmapAlertShare = 'heatmap.alert.share';
  static const String heatmapAlertResolve = 'heatmap.alert.resolve';

  // Listeners
  static const String eventHeatmapSnapshot = 'heatmap.snapshot';
  static const String eventHeatmapWorkerUpdated = 'heatmap.worker.updated';
  static const String eventHeatmapAlertCreated = 'heatmap.alert.created';
  static const String eventHeatmapAlertUpdated = 'heatmap.alert.updated';
  static const String eventHeatmapError = 'heatmap.error';

  // SOS
  static const String eventSosSessionStarted = 'sos.session.started';
  static const String eventSosSessionUpdated = 'sos.session.updated';
  static const String eventSosSessionResolved = 'sos.session.resolved';
}
