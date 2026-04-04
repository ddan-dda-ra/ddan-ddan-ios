//
//  AnalyticsManager.swift
//  DDanDDan
//
//  Created by keone on 2025/03/28.
//

import Foundation
import FirebaseAnalytics

class AnalyticsManager {
    public static let shared = AnalyticsManager()
    private init() {}

    public func logEvent(event: AnalyticsEvent) {
        Analytics.logEvent(event.title, parameters: event.parameter)
    }

    public func setUserProperty(property: UserProperty) {
        Analytics.setUserProperty(property.value, forName: property.name)
    }
}

protocol AnalyticsEvent {
    var title: String { get }
    var parameter: [String: Any] { get }
}

public enum UserProperty {
    case userID(String)
    case userName(String)

    var name: String {
        switch self {
        case .userID:   return "user_id"
        case .userName: return "user_name"
        }
    }

    var value: String? {
        switch self {
        case .userID(let id):     return id
        case .userName(let name): return name
        }
    }
}

// MARK: - OnboardingView

enum OnboardingEvent: AnalyticsEvent {
    case clickCTA(touchpoint: String = "onboarding")
    case clickDisagreeDialogBtn(touchpoint: String = "health")
    case clickAgreeDialogCTA(touchpoint: String = "health")

    var title: String {
        switch self {
        case .clickCTA:               return "click_CTA"
        case .clickDisagreeDialogBtn: return "click_disagree_dialog_btn"
        case .clickAgreeDialogCTA:    return "click_agree_dialog_CTA"
        }
    }

    var parameter: [String: Any] {
        switch self {
        case let .clickCTA(touchpoint):               return ["touchpoint": touchpoint]
        case let .clickDisagreeDialogBtn(touchpoint): return ["touchpoint": touchpoint]
        case let .clickAgreeDialogCTA(touchpoint):    return ["touchpoint": touchpoint]
        }
    }
}

// MARK: - LoginView

enum LoginEvent: AnalyticsEvent {
    case clickKakaoBtn(touchpoint: String = "sign-up")
    case clickAppleBtn(touchpoint: String = "sign-up")

    var title: String {
        switch self {
        case .clickKakaoBtn: return "click_kakao_btn"
        case .clickAppleBtn: return "click_apple_btn"
        }
    }

    var parameter: [String: Any] {
        switch self {
        case let .clickKakaoBtn(touchpoint): return ["touchpoint": touchpoint]
        case let .clickAppleBtn(touchpoint): return ["touchpoint": touchpoint]
        }
    }
}

// MARK: - SignUp (Term / Nickname / Calorie / Egg / Success)

enum SignUpEvent: AnalyticsEvent {
    case clickStartCTA
    case clickNextCTA
    case clickCTA(touchpoint: String)

    var title: String {
        switch self {
        case .clickStartCTA: return "click_start_cta"
        case .clickNextCTA:  return "click_next_cta"
        case .clickCTA:      return "click_cta"
        }
    }

    var parameter: [String: Any] {
        switch self {
        case .clickStartCTA:
            return ["touchpoint": "sign-up-consent"]
        case .clickNextCTA:
            return ["touchpoint": "sign-up-nickname"]
        case let .clickCTA(touchpoint):
            return ["touchpoint": touchpoint]
        }
    }
}

// MARK: - HomeView

enum HomeEvent: AnalyticsEvent {
    case clickNewPetBtn
    case clickPet
    case clickFeedBtn
    case clickPlayBtn
    case clickCancelBtn(path: String = "select-egg")
    case clickBtn(path: String = "select-egg")

    var title: String {
        switch self {
        case .clickNewPetBtn: return "click_new_pet_btn"
        case .clickPet:       return "click_pet"
        case .clickFeedBtn:   return "click_feed_btn"
        case .clickPlayBtn:   return "click_play_btn"
        case .clickCancelBtn: return "click_cancel_btn"
        case .clickBtn:       return "click_btn"
        }
    }

    var parameter: [String: Any] {
        switch self {
        case let .clickCancelBtn(path):       return ["path": path]
        case let .clickBtn(path):             return ["path": path]
        default:                              return [:]
        }
    }
}

// MARK: - MainTabView

enum MainTabEvent: AnalyticsEvent {
    case clickHomeBottomNavi
    case clickRankingBottomNavi
    case clickFriendBottomNavi
    case clickMypageBottomNavi

    var title: String {
        switch self {
        case .clickHomeBottomNavi:    return "click_home_bottom_navi"
        case .clickRankingBottomNavi: return "click_ranking_bottom_navi"
        case .clickFriendBottomNavi:  return "click_friend_bottom_navi"
        case .clickMypageBottomNavi:  return "click_mypage_bottom_navi"
        }
    }

    var parameter: [String: Any] { [:] }
}

// MARK: - RankingView

enum RankingEvent: AnalyticsEvent {
    case clickTab(touchPoint: String = "ranking-kcal")
    case clickTooltip(touchPoint: String = "ranking-kcal")
    case clickMyRanking(touchPoint: String = "ranking-kcal")

    var title: String {
        switch self {
        case .clickTab:    return "click-tab"
        case .clickTooltip: return "click-tooltip"
        case .clickMyRanking:  return "click_my_ranking"
        }
    }

    var parameter: [String: Any] {
        switch self {
        case .clickTab(let touchPoint):
            return ["touchpoint": touchPoint]
        case .clickTooltip(let touchPoint):
            return ["touchpoint": touchPoint]
        case .clickMyRanking(let touchPoint):
            return ["touchpoint": touchPoint]
        }
    }
}


// MARK: - FriendsView

enum FriendsEvent: AnalyticsEvent {
    case clickFriendListGroup
    case clickAddFriendBtn(state: String = "default")
    case clickDeleteFriendBtn
    case clickCheerupBtn
    case clickCloseBtn(touchPoint: String = "dialog")
    case clickCancelDialogCTA(touchpoint: String = "friend-list")
    case clickDeleteDialogCTA(touchpoint: String = "friend-list")
    case clickAddFriendDialogCTA(touchpoint: String = "friend-list")
    case clickBackBtn(touchpoint: String = "friend-list")

    var title: String {
        switch self {
        case .clickFriendListGroup:    return "click_friend_list_group"
        case .clickAddFriendBtn:       return "click_add_friend_btn"
        case .clickDeleteFriendBtn:    return "click_delete_friend_btn"
        case .clickCheerupBtn:         return "click_cheerup_btn"
        case .clickCloseBtn:           return "click_close_btn"
        case .clickCancelDialogCTA:    return "click_cancel_dialog_CTA"
        case .clickDeleteDialogCTA:    return "click_delete_dialog_CTA"
        case .clickAddFriendDialogCTA: return "click_add_friend_dialog_CTA"
        case .clickBackBtn:            return "click-back-btn"
        }
    }

    var parameter: [String: Any] {
        switch self {
        case .clickFriendListGroup:
            return [:]
        case let .clickAddFriendBtn(state):
            return ["state": state]
        case .clickDeleteFriendBtn:
            return [:]
        case .clickCheerupBtn:
            return [:]
        case let .clickCloseBtn(touchPoint):
            return ["touchpoint": touchPoint]
        case let .clickCancelDialogCTA(touchpoint):
            return ["touchpoint": touchpoint]
        case let .clickDeleteDialogCTA(touchpoint):
            return ["touchpoint": touchpoint]
        case let .clickAddFriendDialogCTA(touchpoint):
            return ["touchpoint": touchpoint]
        case let .clickBackBtn(touchpoint):
            return ["touchpoint": touchpoint]
        }
    }
}

enum SettingEvent: AnalyticsEvent {
    // mypage
    case clickPetBox(touchPoint: String = "mypage")
    case clickChangeName(touchPoint: String = "mypage")
    case clickChangeGoal(touchPoint: String = "mypage")
    case clickPushAlarm(touchPoint: String = "mypage")
    case clickTerms(touchPoint: String)
    case clickDeleteAccount(touchPoint: String = "mypage")
    case clickLogout(touchPoint: String = "mypage")
    // mypage-petbox / mypage-change-name / mypage-change-goal
    case clickSavedCTA(touchPoint: String)
    // mypage-terms
    case clickServiceTermBtn(touchPoint: String = "mypage-terms")
    case clickPrivacyTermBtn(touchPoint: String = "mypage-terms")
    // mypage-delect-account
    case clickCTABtn(touchPoint: String = "mypage-delect-account")
    case clickCheckboxReason(touchPoint: String = "mypage-delect-account")
    // mypage-change-goal
    case clickMinusBtn(touchPoint: String = "mypage-change-goal")
    case clickPlusBtn(touchPoint: String = "mypage-change-goal")
    // shared back button (mypage-petbox / mypage-terms / mypage-delect-account)
    case clickBackBtn(touchpoint: String)

    var title: String {
        switch self {
        case .clickPetBox:         return "click-petbox"
        case .clickChangeName:     return "click-change-name"
        case .clickChangeGoal:     return "click-change-goal"
        case .clickPushAlarm:      return "click-push-alarm"
        case .clickTerms:          return "click-terms"
        case .clickDeleteAccount:  return "click-delete-account"
        case .clickLogout:         return "click-logout"
        case .clickSavedCTA:       return "click-saved-cta"
        case .clickServiceTermBtn: return "click-service-terms-btn"
        case .clickPrivacyTermBtn: return "click-privacy-terms-btn"
        case .clickCTABtn:         return "click-CTA-btn"
        case .clickCheckboxReason: return "click-checkbox-reason"
        case .clickMinusBtn:       return "click-minus-btn"
        case .clickPlusBtn:        return "click-plus-btn"
        case .clickBackBtn:        return "click-back-btn"
        }
    }

    var parameter: [String: Any] {
        switch self {
        case let .clickPetBox(touchPoint):         return ["touchpoint": touchPoint]
        case let .clickChangeName(touchPoint):     return ["touchpoint": touchPoint]
        case let .clickChangeGoal(touchPoint):     return ["touchpoint": touchPoint]
        case let .clickPushAlarm(touchPoint):      return ["touchpoint": touchPoint]
        case let .clickTerms(touchPoint):          return ["touchpoint": touchPoint]
        case let .clickDeleteAccount(touchPoint):  return ["touchpoint": touchPoint]
        case let .clickLogout(touchPoint):         return ["touchpoint": touchPoint]
        case let .clickSavedCTA(touchPoint):       return ["touchpoint": touchPoint]
        case let .clickServiceTermBtn(touchPoint): return ["touchpoint": touchPoint]
        case let .clickPrivacyTermBtn(touchPoint): return ["touchpoint": touchPoint]
        case let .clickCTABtn(touchPoint):         return ["touchpoint": touchPoint]
        case let .clickCheckboxReason(touchPoint): return ["touchpoint": touchPoint]
        case let .clickMinusBtn(touchPoint):       return ["touchpoint": touchPoint]
        case let .clickPlusBtn(touchPoint):        return ["touchpoint": touchPoint]
        case let .clickBackBtn(touchpoint):        return ["touchpoint": touchpoint]
        }
    }
}
