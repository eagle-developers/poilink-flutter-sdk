#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*PoilinkSuccessCallback)(void);
typedef void (*PoilinkErrorCallback)(int errorCode, const char* message);
typedef void (*PoilinkRefreshTokenCallback)(const char* refreshToken);
typedef void (*PoilinkMissionChallengeCallback)(const char* missionId);
typedef void (*PoilinkRewardReceiveCallback)(const char* grantId, const char* itemCode, int quantity);

typedef enum {
    POILINK_SHOW_MODE_FULLSCREEN = 0,
    POILINK_SHOW_MODE_EMBEDDED = 1
} PoilinkShowMode;

typedef struct {
    int x;
    int y;
    int width;
    int height;
} EmbeddedFrame;

typedef struct {
    float volume;
    PoilinkSuccessCallback onClose;
    PoilinkErrorCallback onError;
    PoilinkSuccessCallback onShown;
    PoilinkShowMode showMode;
    EmbeddedFrame embeddedFrame;
    PoilinkMissionChallengeCallback onMissionChallenge;
    PoilinkRewardReceiveCallback onRewardReceive;
} WebPortalOptions;

typedef enum {
    POILINK_CYCLE_UNSPECIFIED = 0,
    POILINK_CYCLE_ONCE        = 1,
    POILINK_CYCLE_DAILY       = 2,
    POILINK_CYCLE_WEEKLY      = 3,
    POILINK_CYCLE_MONTHLY     = 4
} PoilinkCycleType;

typedef enum {
    POILINK_REWARD_UNSPECIFIED    = 0,
    POILINK_REWARD_POINT          = 1,
    POILINK_REWARD_APP_OWNED_ITEM = 2
} PoilinkRewardType;

typedef struct {
    const char* inAppMissionId;
    const char* progressCode;
    const char* title;
    const char* details;
    long long   point;
    int         targetProgress;
    int         currentProgress;
    int         hasAchievement;
    int         isClaimed;
    int         displayOrder;
    PoilinkCycleType  cycleType;
    PoilinkRewardType rewardType;
    const char* rewardItemCode;
    int         rewardItemQuantity;
} PoilinkMissionData;

typedef struct {
    const PoilinkMissionData* missions;
    int                       count;
} PoilinkMissionProgressResult;

typedef void (*PoilinkMissionProgressResultCallback)(const PoilinkMissionProgressResult* result);

void ShowWebPortal(const WebPortalOptions* options);
void CloseWebPortal(void);
void PreloadWebPortal(const WebPortalOptions* options);

#if defined(__ANDROID__)
void SetActivity(void* activity);
#endif

void SetConfig(const char* clientId, const char* clientSecret);

void Initialize(
    PoilinkSuccessCallback onSuccess,
    PoilinkErrorCallback onError
);

void Authenticate(
    const char* appUserId,
    PoilinkSuccessCallback onSuccess,
    PoilinkErrorCallback onError
);

void Unauthenticate(void);

void GetRefreshToken(
    PoilinkRefreshTokenCallback onSuccess,
    PoilinkErrorCallback onError
);

void SetRefreshToken(
    const char* appUserId,
    const char* refreshToken,
    PoilinkSuccessCallback onSuccess,
    PoilinkErrorCallback onError
);

typedef void (*PoilinkProgressMissionCompleteCallback)(int64_t userData);
typedef void (*PoilinkProgressMissionErrorCallback)(int64_t userData, int errorCode, const char* message);

void ProgressMission(
    const char* missionCode,
    int amount,
    int mode,
    int64_t userData,
    PoilinkProgressMissionCompleteCallback onComplete,
    PoilinkProgressMissionErrorCallback onError
);

void ProgressMissionImmediate(
    const char* missionCode,
    int amount,
    int mode,
    PoilinkMissionProgressResultCallback onSuccess,
    PoilinkErrorCallback onError,
    const char* idempotencyKey
);

typedef struct {
    const PoilinkMissionData* items;
    int                       count;
} PoilinkMissionList;

typedef struct {
    PoilinkCycleType  cycleType;
    PoilinkRewardType rewardType;
    const char*       progressCode;
} PoilinkGetMissionListFilter;

PoilinkMissionList GetMissionList(const PoilinkGetMissionListFilter* filter);

typedef struct {
    const char* grantId;
    const char* itemCode;
    int         quantity;
    long long   grantedAtUnixMs;
} PoilinkPendingItemGrantData;

typedef struct {
    const PoilinkPendingItemGrantData* grants;
    int                                count;
    int                                hasMore;
} PoilinkListPendingItemGrantsResultData;

typedef struct {
    const char* const* markedGrantIds;
    int                markedCount;
    const char* const* alreadyConsumedOrUnknownGrantIds;
    int                alreadyConsumedOrUnknownCount;
} PoilinkMarkItemGrantsConsumedResultData;

typedef void (*PoilinkListPendingItemGrantsCallback)(const PoilinkListPendingItemGrantsResultData* result);
typedef void (*PoilinkMarkItemGrantsConsumedCallback)(const PoilinkMarkItemGrantsConsumedResultData* result);

void ListPendingItemGrants(
    PoilinkListPendingItemGrantsCallback onSuccess,
    PoilinkErrorCallback onError
);

void MarkItemGrantsConsumed(
    const char* const* grantIds,
    int                count,
    PoilinkMarkItemGrantsConsumedCallback onSuccess,
    PoilinkErrorCallback onError
);

#ifdef __cplusplus
}
#endif
