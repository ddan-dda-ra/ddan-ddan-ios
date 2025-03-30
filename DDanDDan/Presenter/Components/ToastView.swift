//
//  ToastView.swift
//  DDanDDan
//
//  Created by 이지희 on 11/8/24.
//

import SwiftUI


struct ToastView: View {
    let message: String
    let toastType: ToastType
    @State private var offsetY: CGFloat = 40
    @State var isPresented: Bool
    
    var body: some View {
        ZStack {
            VisualEffectBlur(style: .systemUltraThinMaterialDark)
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            HStack {
                Image(toastType.image)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(.leading, 20)
                Text(message)
                    .font(.body1_regular16)
                    .lineSpacing(8)
                    .foregroundColor(.textHeadlinePrimary)
                    .cornerRadius(8)
                Spacer()
            }
        }
        .opacity(isPresented ? 1 : 0)
        .frame(height: 48)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(.rect(cornerRadius: 24))
        .padding(.horizontal,20)
        .offset(y: offsetY)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                offsetY = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    offsetY = 20
                    isPresented = false
                }
            }
        }
    }
}


struct VisualEffectBlur: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    init(style: UIBlurEffect.Style) {
        self.style = style
    }
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

enum ToastType {
    case info
    case ready
    
    var image: ImageResource {
        switch self {
        case .info:
            return .iconToastInfo
        case .ready:
            return .iconTime
        }
    }
}

#Preview {
    ToastView(message: "새로운 펫을 준비중이에요!", toastType: .ready, isPresented: true)
}

