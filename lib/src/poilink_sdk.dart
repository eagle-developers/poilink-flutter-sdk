import 'dart:async';

import 'package:flutter/services.dart';

import 'errors.dart';
import 'event_dispatcher.dart';
import 'messages.g.dart';
import 'models.dart';

class PoilinkSDK {
  PoilinkSDK._();

  static final PoilinkHostApi _host = PoilinkHostApi();
  static final PoilinkEventDispatcher _events = PoilinkEventDispatcher.instance;
  static bool _eventApiReady = false;

  static void _ensureEventApi() {
    if (_eventApiReady) return;
    PoilinkEventApi.setUp(_events);
    _eventApiReady = true;
  }

  static void setConfig({required String clientId, required String clientSecret}) {
    _ensureEventApi();
    unawaited(_host.setConfig(clientId, clientSecret));
  }

  static void initialize({SuccessCallback? onSuccess, ErrorCallback? onError}) {
    _ensureEventApi();
    _host
        .initialize()
        .then((_) => onSuccess?.call())
        .catchError((Object e) => _emitError(e, onError));
  }

  static Future<void> initializeAsync() {
    _ensureEventApi();
    return _host.initialize().catchError(_rethrow);
  }

  static void authenticate(String appUserId,
      {SuccessCallback? onSuccess, ErrorCallback? onError}) {
    _ensureEventApi();
    _host
        .authenticate(appUserId)
        .then((_) => onSuccess?.call())
        .catchError((Object e) => _emitError(e, onError));
  }

  static Future<void> authenticateAsync(String appUserId) {
    _ensureEventApi();
    return _host.authenticate(appUserId).catchError(_rethrow);
  }

  static void unauthenticate() {
    unawaited(_host.unauthenticate());
  }

  static void getRefreshToken({RefreshTokenCallback? onSuccess, ErrorCallback? onError}) {
    _ensureEventApi();
    _host
        .getRefreshToken()
        .then((token) => onSuccess?.call(token))
        .catchError((Object e) => _emitError(e, onError));
  }

  static Future<String> getRefreshTokenAsync() {
    _ensureEventApi();
    return _host.getRefreshToken().catchError(_rethrow);
  }

  static void setRefreshToken(String appUserId, String refreshToken,
      {SuccessCallback? onSuccess, ErrorCallback? onError}) {
    _ensureEventApi();
    _host
        .setRefreshToken(appUserId, refreshToken)
        .then((_) => onSuccess?.call())
        .catchError((Object e) => _emitError(e, onError));
  }

  static Future<void> setRefreshTokenAsync(String appUserId, String refreshToken) {
    _ensureEventApi();
    return _host.setRefreshToken(appUserId, refreshToken).catchError(_rethrow);
  }

  static void progressMission(String missionCode, int amount, ProgressMissionMode mode,
      {ErrorCallback? onError}) {
    _ensureEventApi();
    final handle = _events.registerProgressMission(onError);
    unawaited(_host.progressMission(handle, missionCode, amount, mode.value));
  }

  static void progressMissionImmediate(
      String missionCode, int amount, ProgressMissionMode mode,
      {MissionListCallback? onSuccess, ErrorCallback? onError, String? idempotencyKey}) {
    _ensureEventApi();
    _host
        .progressMissionImmediate(missionCode, amount, mode.value, idempotencyKey)
        .then((list) => onSuccess?.call(_toMissionList(list)))
        .catchError((Object e) => _emitError(e, onError));
  }

  static Future<List<MissionData>> progressMissionImmediateAsync(
      String missionCode, int amount, ProgressMissionMode mode,
      {String? idempotencyKey}) {
    _ensureEventApi();
    return _host
        .progressMissionImmediate(missionCode, amount, mode.value, idempotencyKey)
        .then(_toMissionList)
        .catchError(_rethrow);
  }

  // 他PFは同期戻り。Platform Channel の制約で Future (OS固有事情)
  static Future<List<MissionData>> getMissionList({MissionListFilter? filter}) {
    _ensureEventApi();
    return _host.getMissionList(_filterToMsg(filter)).then(_toMissionList);
  }

  static void showWebPortal({WebPortalOptions? options}) {
    _ensureEventApi();
    final handle = _events.registerWebPortal(options);
    unawaited(_host.showWebPortal(_webPortalToMsg(handle, options)));
  }

  static void preloadWebPortal({WebPortalOptions? options}) {
    _ensureEventApi();
    final handle = _events.registerWebPortal(options);
    unawaited(_host.preloadWebPortal(_webPortalToMsg(handle, options)));
  }

  static void closeWebPortal() {
    unawaited(_host.closeWebPortal());
  }

  static void syncItemGrants(GrantsCallback onGrants,
      {SyncCompleteCallback? onComplete, ErrorCallback? onError}) {
    _ensureEventApi();
    final handle = _events.registerSync(onGrants, onComplete, onError);
    unawaited(_host.syncItemGrants(handle));
  }
}

PoilinkException _toException(Object e) {
  if (e is PoilinkException) return e;
  if (e is PlatformException) {
    return PoilinkException(int.tryParse(e.code) ?? 0, e.message ?? '');
  }
  return PoilinkException(0, e.toString());
}

void _emitError(Object e, ErrorCallback? onError) {
  final ex = _toException(e);
  onError?.call(ex.errorCodeValue, ex.message);
}

Never _rethrow(Object e, StackTrace _) => throw _toException(e);

List<MissionData> _toMissionList(List<MissionDataMsg?> list) => [
      for (final m in list)
        if (m != null) _toMissionData(m),
    ];

MissionData _toMissionData(MissionDataMsg m) => MissionData(
      inAppMissionId: m.inAppMissionId ?? '',
      progressCode: m.progressCode ?? '',
      title: m.title ?? '',
      details: m.details ?? '',
      point: m.point ?? 0,
      targetProgress: m.targetProgress ?? 0,
      currentProgress: m.currentProgress ?? 0,
      hasAchievement: m.hasAchievement ?? false,
      isClaimed: m.isClaimed ?? false,
      displayOrder: m.displayOrder ?? 0,
      cycleType: CycleType.fromValue(m.cycleType ?? 0),
      rewardType: RewardType.fromValue(m.rewardType ?? 0),
      rewardItemCode: m.rewardItemCode ?? '',
      rewardItemQuantity: m.rewardItemQuantity ?? 0,
    );

MissionListFilterMsg? _filterToMsg(MissionListFilter? f) {
  if (f == null) return null;
  return MissionListFilterMsg(
    cycleType: f.cycleType.value,
    rewardType: f.rewardType.value,
    progressCode: f.progressCode,
  );
}

WebPortalOptionsMsg _webPortalToMsg(int handle, WebPortalOptions? o) {
  final frame = o?.embeddedFrame;
  return WebPortalOptionsMsg(
    handle: handle,
    volume: o?.volume,
    showMode: (o?.showMode ?? ShowMode.fullscreen).value,
    embeddedX: frame?.x,
    embeddedY: frame?.y,
    embeddedWidth: frame?.width,
    embeddedHeight: frame?.height,
  );
}
