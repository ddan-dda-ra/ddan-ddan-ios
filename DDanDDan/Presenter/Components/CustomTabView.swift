//
//  CustomTabView.swift
//  DDanDDan
//
//  Created by 이지희 on 3/9/25.
//

import SwiftUI
import ComposableArchitecture

// MARK: - State, Action, Reducer
@Reducer
struct TabFeature {
    @ObservableState
    struct State: Equatable {
        var selection: Tab = .kcal
        var barXOffset: CGFloat = 0
        var barIsActive: Bool = false
    }
    
    enum Action: Equatable {
        case selectTab(Tab)
        case updateBarPosition(CGFloat)
        case activateBar
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .selectTab(tab):
                withAnimation {
                    state.selection = tab
                }
                return .run { send in
                    await send(.updateBarPosition(CGFloat(tab.rawValue)))
                }
                
            case let .updateBarPosition(offset):
                state.barXOffset = offset
                return .none
                
            case .activateBar:
                state.barIsActive = true
                return .none
            }
        }
    }
    
}


public protocol TabTitleConvertible {
    var title: String { get }
}

// MARK: - CustomTabView
struct CustomTabView<Content: View>: View {
    @Perception.Bindable var store: StoreOf<TabFeature>
    let content: (Tab) -> Content

    var body: some View {
        WithPerceptionTracking {
            let viewStore = ViewStore(store, observe: { $0 })
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        WithPerceptionTracking {
                            Button(action: {
                                viewStore.send(.selectTab(tab))
                            }) {
                                Text(tab.title)
                                    .foregroundStyle(tab == viewStore.state.selection ? Color(.textHeadlinePrimary) : Color(.elevationLevel03))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .padding(.vertical, 15)

                WithPerceptionTracking {
                    GeometryReader { geometry in
                        WithPerceptionTracking {
                            let tabSize = geometry.size.width / CGFloat(Tab.allCases.count)
                            Rectangle()
                                .fill(Color(.lightText))
                                .frame(width: tabSize, height: 3)
                                .offset(x: viewStore.barXOffset * tabSize)
                                .animation(viewStore.barIsActive ? .linear(duration: 0.25) : .none, value: viewStore.barXOffset)
                        }
                    }
                    .frame(height: 3)
                    .padding(.horizontal, 20)
                }

                Rectangle()
                    .fill(Color(.elevationLevel03))
                    .frame(height: 1)

                WithPerceptionTracking {
                    content(viewStore.selection)
                        .transition(.slide)
                }
            }
            .onAppear {
                viewStore.send(.updateBarPosition(CGFloat(viewStore.selection.rawValue)))
                viewStore.send(.activateBar)
            }
        }
    }
}




// MARK: - Tab Enum
enum Tab: Int, Identifiable, Hashable, Comparable, TabTitleConvertible, CaseIterable {
    case kcal
    case goal
    
    var title: String {
        switch self {
        case .kcal: return "칼로리"
        case .goal: return "목표"
        }
    }
    
    var GuideTitle: String {
        switch self {
        case .kcal: "칼로리를\n많이 소비했어요"
        case .goal: "꾸준하게\n목표를 달성했어요"
        }
    }
    
    var toolKitMessage: String {
        switch self {
        case .kcal: "한 달 동안 칼로리를 많이 소비한 순서에요"
        case .goal: "한 달 동안 목표한 칼로리를\n누적 달성한 순서에요"
        }
    }
    
    var guideTitleWidth: CGFloat {
        switch self {
        case .kcal: return 176 / 2 - 48
        case .goal: return 204 / 2
        }
    }
    
    var id: Int {
        rawValue
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
