import SwiftUI

struct Toast: Identifiable {
    let id = UUID()
    let message: String
}

struct ToastView: View {
    let toast: Toast

    var body: some View {
        Text(toast.message)
            .font(.footnote)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.8))
            .clipShape(Capsule())
            .shadow(radius: 4)
    }
}

extension View {
    func toast(_ toast: Binding<Toast?>) -> some View {
        ZStack {
            self
            if let t = toast.wrappedValue {
                VStack {
                    Spacer()
                    ToastView(toast: t)
                        .padding(.bottom, 24)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: toast.wrappedValue?.id)
            }
        }
    }
}