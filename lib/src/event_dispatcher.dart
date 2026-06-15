import 'messages.g.dart';
import 'models.dart';

class _SyncRegistration {
  _SyncRegistration(this.onGrants, this.onComplete, this.onError);

  final GrantsCallback onGrants;
  final SyncCompleteCallback? onComplete;
  final ErrorCallback? onError;
}

class PoilinkEventDispatcher implements PoilinkEventApi {
  PoilinkEventDispatcher._();

  static final PoilinkEventDispatcher instance = PoilinkEventDispatcher._();

  int _nextHandle = 1;
  final Map<int, WebPortalOptions> _webPortal = {};
  final Map<int, ErrorCallback?> _progressMission = {};
  final Map<int, _SyncRegistration> _sync = {};

  int registerWebPortal(WebPortalOptions? options) {
    final handle = _nextHandle++;
    if (options != null) _webPortal[handle] = options;
    return handle;
  }

  int registerProgressMission(ErrorCallback? onError) {
    final handle = _nextHandle++;
    _progressMission[handle] = onError;
    return handle;
  }

  int registerSync(
      GrantsCallback onGrants, SyncCompleteCallback? onComplete, ErrorCallback? onError) {
    final handle = _nextHandle++;
    _sync[handle] = _SyncRegistration(onGrants, onComplete, onError);
    return handle;
  }

  @override
  void onWebPortalShown(int handle) {
    _webPortal[handle]?.onShown?.call();
  }

  @override
  void onWebPortalClose(int handle) {
    _webPortal.remove(handle)?.onClose?.call();
  }

  @override
  void onWebPortalError(int handle, int errorCode, String message) {
    _webPortal[handle]?.onError?.call(errorCode, message);
  }

  @override
  void onMissionChallenge(int handle, String missionId) {
    _webPortal[handle]?.onMissionChallenge?.call(missionId);
  }

  @override
  void onRewardReceive(int handle, String grantId, String itemCode, int quantity) {
    _webPortal[handle]?.onRewardReceive?.call(grantId, itemCode, quantity);
  }

  @override
  void onProgressMissionError(int handle, int errorCode, String message) {
    _progressMission.remove(handle)?.call(errorCode, message);
  }

  @override
  void onGrantsPage(int handle, List<PendingItemGrantMsg?> grants) {
    final reg = _sync[handle];
    if (reg == null) return;
    reg.onGrants([
      for (final g in grants)
        if (g != null) _toGrant(g),
    ]);
  }

  @override
  void onSyncComplete(int handle, SyncItemGrantsResultMsg result) {
    _sync.remove(handle)?.onComplete?.call(_toResult(result));
  }

  @override
  void onSyncError(int handle, int errorCode, String message) {
    _sync.remove(handle)?.onError?.call(errorCode, message);
  }
}

PendingItemGrant _toGrant(PendingItemGrantMsg m) => PendingItemGrant(
      grantId: m.grantId ?? '',
      itemCode: m.itemCode ?? '',
      quantity: m.quantity ?? 0,
      grantedAtUnixMs: m.grantedAtUnixMs ?? 0,
    );

SyncItemGrantsResult _toResult(SyncItemGrantsResultMsg m) => SyncItemGrantsResult(
      totalSynced: m.totalSynced ?? 0,
      totalMarked: m.totalMarked ?? 0,
      pageCount: m.pageCount ?? 0,
    );
