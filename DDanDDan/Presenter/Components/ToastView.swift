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
    @State private var opacity: CGFloat = 40

    var body: some View {
            ZStack {
                BackgroundBlurView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                HStack {
                    Image(toastType.image)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(.leading, 20)
                    Text(message)
                        .font(.body1_regular16)
                        .lineSpacing(8)
                        .foregroundColor(.textHeadlinePrimary)
                    Spacer()
                }
                .padding(.trailing, 20)
            }
            .frame(height: 48)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .offset(y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    offsetY = 0
                    opacity = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        offsetY = 20
                        opacity = 0
                    }
                }
            }
    }
}

struct BackgroundBlurView: UIViewRepresentable{
    func makeUIView(context: Context) -> some UIView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        
        DispatchQueue.main.async{
            view.superview?.superview?.backgroundColor = .clear
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) { }
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
    ToastView(message: "새로운 펫을 준비중이에요!", toastType: .ready)
}
