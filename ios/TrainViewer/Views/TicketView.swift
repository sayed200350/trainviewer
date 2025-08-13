import SwiftUI
import LocalAuthentication
import CoreImage.CIFilterBuiltins
import UIKit

struct TicketView: View {
    @State private var ticket: Ticket?
    @State private var authFailed = false
    @State private var hasLoaded = false
    @State private var previousBrightness: CGFloat = UIScreen.main.brightness

    private let context = LAContext()

    var body: some View {
        VStack(spacing: 16) {
            if let t = ticket {
                validityHeader(t)
                codeImage(t)
                    .frame(maxWidth: 320, maxHeight: 320)
                    .padding()
                Text(expiryText(for: t))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if authFailed {
                Text("Authentication required to view ticket").foregroundColor(.red)
            } else if hasLoaded {
                Text("No ticket found. Add via Settings → Add to Apple Wallet or link your account.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                ProgressView("Loading ticket…")
            }
        }
        .padding()
        .navigationTitle("Student Ticket")
        .task { await loadTicketSecured() }
        .onAppear { boostBrightness() }
        .onDisappear { restoreBrightness() }
    }

    private func loadTicketSecured() async {
        let reason = "Authenticate to show your ticket"
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let ok = (try? await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)) ?? false
            if !ok { authFailed = true; hasLoaded = true; return }
        }
        ticket = TicketService.shared.loadCachedTicket()
        hasLoaded = true
    }

    private func codeImage(_ t: Ticket) -> some View {
        Group {
            if let img = renderCode(payload: t.qrPayload, format: t.format) {
                Image(uiImage: img).interpolation(.none).resizable().scaledToFit()
                    .accessibilityLabel("Scannable ticket code")
            } else {
                Image(systemName: "qrcode")
                    .resizable().scaledToFit().foregroundColor(.secondary)
            }
        }
    }

    private func validityHeader(_ t: Ticket) -> some View {
        HStack {
            Label(t.status == .active ? "Active" : t.status.rawValue.capitalized, systemImage: t.status == .active ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(t.status == .active ? .green : .yellow)
            Spacer()
        }
    }

    private func expiryText(for t: Ticket) -> String {
        if t.isExpired { return "Expired" }
        let minutes = max(0, Int(t.expiresAt.timeIntervalSince(Date()) / 60))
        return "Valid for \(minutes)m"
    }

    private func renderCode(payload: String, format: TicketBarcodeFormat) -> UIImage? {
        let context = CIContext()
        switch format {
        case .qr:
            let filter = CIFilter.qrCodeGenerator()
            filter.setValue(Data(payload.utf8), forKey: "inputMessage")
            guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)), let cg = context.createCGImage(output, from: output.extent) else { return nil }
            return UIImage(cgImage: cg)
        case .aztec:
            let filter = CIFilter.aztecCodeGenerator()
            filter.setValue(Data(payload.utf8), forKey: "inputMessage")
            guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)), let cg = context.createCGImage(output, from: output.extent) else { return nil }
            return UIImage(cgImage: cg)
        }
    }

    private func boostBrightness() {
        previousBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = max(0.9, previousBrightness)
    }

    private func restoreBrightness() {
        UIScreen.main.brightness = previousBrightness
    }
}