typedef SuccessCallback = void Function();

typedef ErrorCallback = void Function(int errorCode, String message);

typedef RefreshTokenCallback = void Function(String refreshToken);

typedef MissionChallengeCallback = void Function(String missionId);

typedef RewardReceiveCallback = void Function(
    String grantId, String itemCode, int quantity, String missionCode);

typedef MissionListCallback = void Function(List<MissionData> missions);

typedef GrantsCallback = void Function(List<PendingItemGrant> grants);

typedef SyncCompleteCallback = void Function(SyncItemGrantsResult result);

enum ShowMode {
  fullscreen(0),
  embedded(1);

  const ShowMode(this.value);

  final int value;

  static ShowMode fromValue(int value) {
    for (final mode in ShowMode.values) {
      if (mode.value == value) return mode;
    }
    return ShowMode.fullscreen;
  }
}

enum CycleType {
  unspecified(0),
  once(1),
  daily(2),
  weekly(3),
  monthly(4);

  const CycleType(this.value);

  final int value;

  static CycleType fromValue(int value) {
    for (final type in CycleType.values) {
      if (type.value == value) return type;
    }
    return CycleType.unspecified;
  }
}

enum RewardType {
  unspecified(0),
  point(1),
  appOwnedItem(2);

  const RewardType(this.value);

  final int value;

  static RewardType fromValue(int value) {
    for (final type in RewardType.values) {
      if (type.value == value) return type;
    }
    return RewardType.unspecified;
  }
}

enum ProgressMissionMode {
  increase(0),
  atLeast(1);

  const ProgressMissionMode(this.value);

  final int value;
}

class EmbeddedFrame {
  const EmbeddedFrame({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}

class MissionListFilter {
  const MissionListFilter({
    this.cycleType = CycleType.unspecified,
    this.rewardType = RewardType.unspecified,
    this.progressCode,
  });

  final CycleType cycleType;
  final RewardType rewardType;
  final String? progressCode;
}

class MissionData {
  const MissionData({
    required this.inAppMissionId,
    required this.progressCode,
    required this.title,
    required this.details,
    required this.point,
    required this.targetProgress,
    required this.currentProgress,
    required this.hasAchievement,
    required this.isClaimed,
    required this.displayOrder,
    required this.cycleType,
    required this.rewardType,
    required this.rewardItemCode,
    required this.rewardItemQuantity,
  });

  final String inAppMissionId;
  final String progressCode;
  final String title;
  final String details;
  final int point;
  final int targetProgress;
  final int currentProgress;
  final bool hasAchievement;
  final bool isClaimed;
  final int displayOrder;
  final CycleType cycleType;
  final RewardType rewardType;
  final String rewardItemCode;
  final int rewardItemQuantity;
}

class WebPortalOptions {
  WebPortalOptions({
    this.volume,
    this.onClose,
    this.onShown,
    this.onError,
    this.onMissionChallenge,
    this.onRewardReceive,
    this.showMode = ShowMode.fullscreen,
    this.embeddedFrame,
  });

  double? volume;
  SuccessCallback? onClose;
  SuccessCallback? onShown;
  ErrorCallback? onError;
  MissionChallengeCallback? onMissionChallenge;
  RewardReceiveCallback? onRewardReceive;
  ShowMode showMode;
  EmbeddedFrame? embeddedFrame;
}

class PendingItemGrant {
  const PendingItemGrant({
    required this.grantId,
    required this.itemCode,
    required this.quantity,
    required this.grantedAtUnixMs,
  });

  final String grantId;
  final String itemCode;
  final int quantity;
  final int grantedAtUnixMs;
}

class SyncItemGrantsResult {
  const SyncItemGrantsResult({
    required this.totalSynced,
    required this.totalMarked,
    required this.pageCount,
  });

  final int totalSynced;
  final int totalMarked;
  final int pageCount;
}
