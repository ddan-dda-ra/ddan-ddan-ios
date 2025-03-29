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
struct CustomTabView: View {
    let store: StoreOf<TabFeature>
    let views: [Tab: AnyView]

    var body: some View {
        WithPerceptionTracking {
            let viewStore = ViewStore(store, observe: { $0 })
            
            VStack {
                WithPerceptionTracking {
                    GeometryReader { geometry in
                        let tabSize = geometry.size.width / CGFloat(views.count)
                        WithPerceptionTracking {
                            VStack(spacing: 0) {
                                HStack(spacing: 0) {
                                    ForEach(Tab.allCases, id: \.self) { tab in
                                        Button(action: {
                                            viewStore.send(.selectTab(tab))
                                        }) {
                                            HStack(spacing: 0) {
                                                Spacer()
                                                Text(tab.title)
                                                    .foregroundStyle(Color(.white))
                                                Spacer()
                                            }
                                        }
                                        .frame(width: tabSize)
                                    }
                                }
                                .padding(.vertical, 15)
                                
                                ZStack(alignment: .bottom) {
                                    Rectangle()
                                        .fill(Color(.backgroundBlack))
                                    HStack {
                                        Rectangle()
                                            .fill(Color(.lightText))
                                            .frame(width: tabSize, height: 3)
                                            .offset(x: viewStore.barXOffset * tabSize)
                                            .animation(viewStore.barIsActive ? .linear(duration: 0.25) : .none, value: viewStore.barXOffset)
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .onAppear {
                            viewStore.send(.updateBarPosition(CGFloat(viewStore.selection.rawValue)))
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                viewStore.send(.activateBar)
                            }
                        }
                    }
                    .frame(height: 56)
                    .padding(.horizontal, 20)
                    
                    if let view = views[viewStore.selection] {
                        view
                            .transition(.slide)
                    } else {
                        EmptyView()
                    }
                }
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
        case .goal: "한 달 동안 목표한 칼로리를 누적 달성한 순서에요"
        }
    }
    
    var id: Int {
        rawValue
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
