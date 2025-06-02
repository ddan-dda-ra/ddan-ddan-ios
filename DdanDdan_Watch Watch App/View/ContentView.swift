//
//  ContentView.swift
//  DdanDdan_Watch Watch App
//
//  Created by 이지희 on 10/24/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isTapped: Bool = false
    @ObservedObject var viewModel: WatchViewModel
    
    var centerView: some View {
        Group {
            if isTapped {
                kcalLabel
            } else {
                imageView
            }
        }
        .frame(width: 107, height: 107)
    }
    
    var kcalLabel: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("\(viewModel.currentKcal)")
                .font(.neoDunggeunmo48)
                .foregroundStyle(
                    viewModel.isGoalMet ? viewModel.viewConfig?.1 ?? .white : .white
                )
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("kcal")
                .font(.neoDunggeunmo16)
                .foregroundStyle(.white)
        }
    }
    
    var imageView: some View {
        Image(viewModel.viewConfig?.0 ?? .blueEgg)
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100) 
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            Color(.backgroundBlack)
            centerView
            DonutChartView(
                targetProgress: $viewModel.currentKcalProgress,
                lineColor: viewModel.viewConfig?.1 ?? .blueGraphics
            )
        }
        .ignoresSafeArea()
        .onAppear {
            HealthKitManager.shared.requestAuthorization { isGranted in
                viewModel.observeHealthKitData()
            }
        }
        .onTapGesture {
            isTapped.toggle()
        }
        .alert(isPresented: $viewModel.showLoginAlert) {
            Alert(
                title: Text("로그인이 필요합니다"),
                message: Text("iOS 앱에서 먼저 로그인해주세요."),
                dismissButton: .default(Text("확인"))
            )
        }
    }
}

struct DonutChartView: View {
    @Binding var targetProgress: Double
    @State private var animatedProgress: Double = 0.0
    var lineWidth: CGFloat = 8
    var lineColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(15)
            Circle()
                .trim(from: 1 - CGFloat(animatedProgress), to: 1)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [lineColor]),
                        center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .square)
                )
                .rotationEffect(.degrees(-90))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(15)
                .animation(.easeInOut(duration: 1), value: animatedProgress) // 애니메이션 효과 추가
        }
        .onAppear {
            animatedProgress = targetProgress
        }
        .onChange(of: targetProgress) {
            animatedProgress = targetProgress
        }
    }
}


#Preview {
    ContentView(viewModel: .init(currentKcal: 250))
}
