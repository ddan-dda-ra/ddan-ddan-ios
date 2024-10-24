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
    
    var petType: PetType = .dog
    
    var centerView: some View {
        Group {
            if isTapped {
                kcalLabel
            } else {
                Image(viewModel.configureUI(petType: petType).0)
            }
        }
    }
    
    var kcalLabel: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("\(viewModel.currentKcal)")
                .font(.neoDunggeunmo48)
                .foregroundStyle(viewModel.isGoalMet ? viewModel.configureUI(petType: petType).1 : .white)
            Text("kcal")
                .font(.neoDunggeunmo16)
                .foregroundStyle(.white)
        }
    }
    
    var body: some View {
        ZStack {
            Color(.backgroundBlack)
            centerView
            DonutChartView(
                targetProgress: $viewModel.currentKcalProgress,
                lineColor: viewModel.configureUI(petType: petType).1
            )
        }
        .ignoresSafeArea()
        .onAppear {
            HealthKitManager.shared.requestAuthorization { isGranted in
                viewModel.fetchActiveEnergyFromHealthKit()
            }
        }
        .onTapGesture {
            isTapped.toggle()
        }
    }
}

struct DonutChartView: View {
    @Binding var targetProgress: Double
    @State private var animatedProgress: Double = 0.0
    var lineWidth: CGFloat = 12
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


//#Preview {
//    ContentView(viewModel: .init(goalKcal: 400))
//}
