package com.poilink.sdk.flutter

import android.app.Activity
import android.os.Handler
import android.os.Looper
import com.poilink.sdk.CycleType
import com.poilink.sdk.MissionData
import com.poilink.sdk.MissionListFilter
import com.poilink.sdk.RewardType
import com.poilink.sdk.PendingItemGrant
import com.poilink.sdk.PoilinkSDK
import com.poilink.sdk.ProgressMissionMode
import com.poilink.sdk.SyncItemGrantsResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class PoilinkSdkPlugin : FlutterPlugin, ActivityAware, PoilinkHostApi {
  private var eventApi: PoilinkEventApi? = null
  private var activity: Activity? = null
  private val mainHandler = Handler(Looper.getMainLooper())

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    PoilinkHostApi.setUp(binding.binaryMessenger, this)
    eventApi = PoilinkEventApi(binding.binaryMessenger)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    PoilinkHostApi.setUp(binding.binaryMessenger, null)
    eventApi = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun setConfig(clientId: String, clientSecret: String) {
    PoilinkSDK.setConfig(clientId, clientSecret)
  }

  override fun initialize(callback: (Result<Unit>) -> Unit) {
    val act = activity
    if (act == null) {
      callback(Result.failure(FlutterError("1002", "Activity is not available", null)))
      return
    }
    PoilinkSDK.initialize(act,
      { callback(Result.success(Unit)) },
      { code, msg -> callback(Result.failure(FlutterError(code.toString(), msg, null))) }
    )
  }

  override fun authenticate(appUserId: String, callback: (Result<Unit>) -> Unit) {
    PoilinkSDK.authenticate(appUserId,
      { callback(Result.success(Unit)) },
      { code, msg -> callback(Result.failure(FlutterError(code.toString(), msg, null))) }
    )
  }

  override fun unauthenticate() {
    PoilinkSDK.unauthenticate()
  }

  override fun getRefreshToken(callback: (Result<String>) -> Unit) {
    PoilinkSDK.getRefreshToken(
      { token -> callback(Result.success(token)) },
      { code, msg -> callback(Result.failure(FlutterError(code.toString(), msg, null))) }
    )
  }

  override fun setRefreshToken(appUserId: String, refreshToken: String, callback: (Result<Unit>) -> Unit) {
    PoilinkSDK.setRefreshToken(appUserId, refreshToken,
      { callback(Result.success(Unit)) },
      { code, msg -> callback(Result.failure(FlutterError(code.toString(), msg, null))) }
    )
  }

  override fun progressMission(handle: Long, missionCode: String, amount: Long, mode: Long) {
    PoilinkSDK.progressMission(missionCode, amount.toInt(), ProgressMissionMode.fromValue(mode.toInt())) { code, msg ->
      runOnMain { eventApi?.onProgressMissionError(handle, code.toLong(), msg) { } }
    }
  }

  override fun progressMissionImmediate(
    missionCode: String,
    amount: Long,
    mode: Long,
    idempotencyKey: String?,
    callback: (Result<List<MissionDataMsg>>) -> Unit
  ) {
    PoilinkSDK.progressMissionImmediate(missionCode, amount.toInt(), ProgressMissionMode.fromValue(mode.toInt()),
      { list -> callback(Result.success(list.map(::toMissionMsg))) },
      { code, msg -> callback(Result.failure(FlutterError(code.toString(), msg, null))) },
      idempotencyKey
    )
  }

  override fun getMissionList(filter: MissionListFilterMsg?, callback: (Result<List<MissionDataMsg>>) -> Unit) {
    val nativeFilter = filter?.let {
      val f = MissionListFilter()
      f.cycleType = CycleType.fromValue((it.cycleType ?: 0).toInt())
      f.rewardType = RewardType.fromValue((it.rewardType ?: 0).toInt())
      val code = it.progressCode
      if (!code.isNullOrEmpty()) f.progressCode = code
      f
    }
    val list = if (nativeFilter != null) PoilinkSDK.getMissionList(nativeFilter) else PoilinkSDK.getMissionList()
    callback(Result.success(list.map(::toMissionMsg)))
  }

  override fun showWebPortal(options: WebPortalOptionsMsg) {
    PoilinkSDK.showWebPortal(buildWebPortalOptions(options))
  }

  override fun preloadWebPortal(options: WebPortalOptionsMsg) {
    PoilinkSDK.preloadWebPortal(buildWebPortalOptions(options))
  }

  override fun closeWebPortal() {
    PoilinkSDK.closeWebPortal()
  }

  override fun syncItemGrants(handle: Long) {
    PoilinkSDK.syncItemGrants(
      { grants -> runOnMain { eventApi?.onGrantsPage(handle, grants.map(::toGrantMsg)) { } } },
      { result -> runOnMain { eventApi?.onSyncComplete(handle, toResultMsg(result)) { } } },
      { code, msg -> runOnMain { eventApi?.onSyncError(handle, code.toLong(), msg) { } } }
    )
  }

  private fun buildWebPortalOptions(msg: WebPortalOptionsMsg): PoilinkSDK.WebPortalOptions {
    val handle = msg.handle ?: 0L
    val opts = PoilinkSDK.WebPortalOptions()
    opts.volume = msg.volume?.toFloat()
    opts.showMode = PoilinkSDK.ShowMode.fromValue((msg.showMode ?: 0).toInt())
    val x = msg.embeddedX
    val y = msg.embeddedY
    val w = msg.embeddedWidth
    val h = msg.embeddedHeight
    if (x != null && y != null && w != null && h != null) {
      opts.embeddedFrame = PoilinkSDK.EmbeddedFrame(x.toInt(), y.toInt(), w.toInt(), h.toInt())
    }
    opts.onShown = PoilinkSDK.SuccessCallback { runOnMain { eventApi?.onWebPortalShown(handle) { } } }
    opts.onClose = PoilinkSDK.SuccessCallback { runOnMain { eventApi?.onWebPortalClose(handle) { } } }
    opts.onError = PoilinkSDK.ErrorCallback { code, msg2 ->
      runOnMain { eventApi?.onWebPortalError(handle, code.toLong(), msg2) { } }
    }
    opts.onMissionChallenge = PoilinkSDK.MissionChallengeCallback { missionId ->
      runOnMain { eventApi?.onMissionChallenge(handle, missionId) { } }
    }
    opts.onRewardReceive = PoilinkSDK.RewardReceiveCallback { grantId, itemCode, quantity ->
      runOnMain { eventApi?.onRewardReceive(handle, grantId, itemCode, quantity.toLong()) { } }
    }
    return opts
  }

  // Android の SDK callback は呼び出しスレッドが一定でないため main に集約 (iOS は main 保証で不要)
  private fun runOnMain(block: () -> Unit) {
    mainHandler.post(block)
  }
}

private fun toMissionMsg(m: MissionData): MissionDataMsg = MissionDataMsg(
  inAppMissionId = m.inAppMissionId,
  progressCode = m.progressCode,
  title = m.title,
  details = m.details,
  point = m.point,
  targetProgress = m.targetProgress.toLong(),
  currentProgress = m.currentProgress.toLong(),
  hasAchievement = m.hasAchievement,
  isClaimed = m.isClaimed,
  displayOrder = m.displayOrder.toLong(),
  cycleType = m.cycleType.value.toLong(),
  rewardType = m.rewardType.value.toLong(),
  rewardItemCode = m.rewardItemCode,
  rewardItemQuantity = m.rewardItemQuantity.toLong()
)

private fun toGrantMsg(m: PendingItemGrant): PendingItemGrantMsg = PendingItemGrantMsg(
  grantId = m.grantId,
  itemCode = m.itemCode,
  quantity = m.quantity.toLong(),
  grantedAtUnixMs = m.grantedAtUnixMs
)

private fun toResultMsg(m: SyncItemGrantsResult): SyncItemGrantsResultMsg = SyncItemGrantsResultMsg(
  totalSynced = m.totalSynced.toLong(),
  totalMarked = m.totalMarked.toLong(),
  pageCount = m.pageCount.toLong()
)
