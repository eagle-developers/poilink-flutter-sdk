import Flutter
import UIKit
import poilink_sdk

public class PoilinkSdkPlugin: NSObject, FlutterPlugin {
  private static var instances: [PoilinkHostApiImpl] = []

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    let impl = PoilinkHostApiImpl()
    impl.eventApi = PoilinkEventApi(binaryMessenger: messenger)
    PoilinkHostApiSetup.setUp(binaryMessenger: messenger, api: impl)
    instances.append(impl)
  }
}

class PoilinkHostApiImpl: PoilinkHostApi {
  var eventApi: PoilinkEventApi?

  func setConfig(clientId: String, clientSecret: String) throws {
    PoilinkSDK.setConfig(clientId: clientId, clientSecret: clientSecret)
  }

  func initialize(completion: @escaping (Result<Void, Error>) -> Void) {
    PoilinkSDK.initialize(
      onSuccess: { completion(.success(())) },
      onError: { code, msg in completion(.failure(flutterError(code, msg))) }
    )
  }

  func authenticate(appUserId: String, completion: @escaping (Result<Void, Error>) -> Void) {
    PoilinkSDK.authenticate(
      appUserId: appUserId,
      onSuccess: { completion(.success(())) },
      onError: { code, msg in completion(.failure(flutterError(code, msg))) }
    )
  }

  func unauthenticate() throws {
    PoilinkSDK.unauthenticate()
  }

  func getRefreshToken(completion: @escaping (Result<String, Error>) -> Void) {
    PoilinkSDK.getRefreshToken(
      onSuccess: { token in completion(.success(token)) },
      onError: { code, msg in completion(.failure(flutterError(code, msg))) }
    )
  }

  func setRefreshToken(appUserId: String, refreshToken: String, completion: @escaping (Result<Void, Error>) -> Void) {
    PoilinkSDK.setRefreshToken(
      appUserId: appUserId,
      refreshToken: refreshToken,
      onSuccess: { completion(.success(())) },
      onError: { code, msg in completion(.failure(flutterError(code, msg))) }
    )
  }

  func progressMission(handle: Int64, missionCode: String, amount: Int64, mode: Int64) throws {
    PoilinkSDK.progressMission(
      missionCode: missionCode,
      amount: Int32(amount),
      mode: ProgressMissionMode(rawValue: Int(mode)) ?? .increase,
      onComplete: nil,
      onError: { [weak self] code, msg in
        self?.eventApi?.onProgressMissionError(handle: handle, errorCode: Int64(code), message: msg) { _ in }
      }
    )
  }

  func progressMissionImmediate(
    missionCode: String,
    amount: Int64,
    mode: Int64,
    idempotencyKey: String?,
    completion: @escaping (Result<[MissionDataMsg], Error>) -> Void
  ) {
    PoilinkSDK.progressMissionImmediate(
      missionCode: missionCode,
      amount: Int32(amount),
      mode: ProgressMissionMode(rawValue: Int(mode)) ?? .increase,
      onSuccess: { list in completion(.success(list.map(toMissionMsg))) },
      onError: { code, msg in completion(.failure(flutterError(code, msg))) },
      idempotencyKey: idempotencyKey
    )
  }

  func getMissionList(filter: MissionListFilterMsg?, completion: @escaping (Result<[MissionDataMsg], Error>) -> Void) {
    let nativeFilter: MissionListFilter?
    if let f = filter {
      nativeFilter = MissionListFilter.buildForNative(
        cycleType: Int32(f.cycleType ?? 0),
        rewardType: Int32(f.rewardType ?? 0),
        progressCode: f.progressCode
      )
    } else {
      nativeFilter = nil
    }
    let list = PoilinkSDK.getMissionList(filter: nativeFilter)
    completion(.success(list.map(toMissionMsg)))
  }

  func showWebPortal(options: WebPortalOptionsMsg) throws {
    PoilinkSDK.showWebPortal(options: buildWebPortalOptions(options))
  }

  func preloadWebPortal(options: WebPortalOptionsMsg) throws {
    PoilinkSDK.preloadWebPortal(options: buildWebPortalOptions(options))
  }

  func closeWebPortal() throws {
    PoilinkSDK.closeWebPortal()
  }

  func syncItemGrants(handle: Int64) throws {
    PoilinkSDK.syncItemGrants(
      onGrants: { [weak self] grants in
        self?.eventApi?.onGrantsPage(handle: handle, grants: grants.map(toGrantMsg)) { _ in }
      },
      onComplete: { [weak self] result in
        self?.eventApi?.onSyncComplete(handle: handle, result: toResultMsg(result)) { _ in }
      },
      onError: { [weak self] code, msg in
        self?.eventApi?.onSyncError(handle: handle, errorCode: Int64(code), message: msg) { _ in }
      }
    )
  }

  private func buildWebPortalOptions(_ msg: WebPortalOptionsMsg) -> PoilinkSDK.WebPortalOptions {
    let handle = msg.handle ?? 0
    let opts = PoilinkSDK.WebPortalOptions()
    if let v = msg.volume { opts.volume = NSNumber(value: v) }
    opts.showMode = PoilinkSDK.ShowMode(rawValue: Int(msg.showMode ?? 0)) ?? .fullscreen
    if let x = msg.embeddedX, let y = msg.embeddedY, let w = msg.embeddedWidth, let h = msg.embeddedHeight {
      opts.embeddedFrame = NSValue(cgRect: CGRect(
        x: CGFloat(x), y: CGFloat(y), width: CGFloat(w), height: CGFloat(h)))
    }
    opts.onShown = { [weak self] in
      self?.eventApi?.onWebPortalShown(handle: handle) { _ in }
    }
    opts.onClose = { [weak self] in
      self?.eventApi?.onWebPortalClose(handle: handle) { _ in }
    }
    opts.onError = { [weak self] code, msg in
      self?.eventApi?.onWebPortalError(handle: handle, errorCode: Int64(code), message: msg) { _ in }
    }
    opts.onMissionChallenge = { [weak self] missionId in
      self?.eventApi?.onMissionChallenge(handle: handle, missionId: missionId) { _ in }
    }
    opts.onRewardReceive = { [weak self] grantId, itemCode, quantity in
      self?.eventApi?.onRewardReceive(
        handle: handle, grantId: grantId, itemCode: itemCode, quantity: Int64(quantity)) { _ in }
    }
    return opts
  }
}

private func flutterError(_ code: Int32, _ message: String) -> PigeonError {
  return PigeonError(code: String(code), message: message, details: nil)
}

private func toMissionMsg(_ m: MissionData) -> MissionDataMsg {
  return MissionDataMsg(
    inAppMissionId: m.inAppMissionId,
    progressCode: m.progressCode,
    title: m.title,
    details: m.details,
    point: m.point,
    targetProgress: Int64(m.targetProgress),
    currentProgress: Int64(m.currentProgress),
    hasAchievement: m.hasAchievement,
    isClaimed: m.isClaimed,
    displayOrder: Int64(m.displayOrder),
    cycleType: Int64(m.cycleType.rawValue),
    rewardType: Int64(m.rewardType.rawValue),
    rewardItemCode: m.rewardItemCode,
    rewardItemQuantity: Int64(m.rewardItemQuantity)
  )
}

private func toGrantMsg(_ m: PendingItemGrant) -> PendingItemGrantMsg {
  return PendingItemGrantMsg(
    grantId: m.grantId,
    itemCode: m.itemCode,
    quantity: Int64(m.quantity),
    grantedAtUnixMs: m.grantedAtUnixMs
  )
}

private func toResultMsg(_ m: SyncItemGrantsResult) -> SyncItemGrantsResultMsg {
  return SyncItemGrantsResultMsg(
    totalSynced: Int64(m.totalSynced),
    totalMarked: Int64(m.totalMarked),
    pageCount: Int64(m.pageCount)
  )
}
