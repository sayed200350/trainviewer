import SwiftUI
import UIKit
import UserNotifications

// MARK: - Error Presentation Service

/// Service for presenting user-friendly error messages and recovery options
final class ErrorPresentationService: ObservableObject {
    static let shared = ErrorPresentationService()
    
    @Published var currentError: PresentableError?
    @Published var isShowingError = false
    
    private init() {}
    
    // MARK: - Error Presentation
    
    func presentError(_ error: Error, context: ErrorContext = .general) {
        Task { @MainActor in
            let presentableError = await createPresentableError(from: error, context: context)
            self.currentError = presentableError
            self.isShowingError = true
        }
    }
    
    func presentEnhancedError(_ error: EnhancedAppError, context: ErrorContext = .general) {
        Task { @MainActor in
            let presentableError = createPresentableError(from: error, context: context)
            self.currentError = presentableError
            self.isShowingError = true
        }
    }
    
    func dismissError() {
        currentError = nil
        isShowingError = false
    }
    
    // MARK: - Error Creation
    
    private func createPresentableError(from error: EnhancedAppError, context: ErrorContext) -> PresentableError {
        let actions = createRecoveryActions(for: error, context: context)
        
        return PresentableError(
            title: error.severity.displayName,
            message: error.localizedDescription,
            recoverySuggestion: error.recoverySuggestion,
            severity: error.severity,
            actions: actions,
            canRetryAutomatically: error.canRetryAutomatically,
            retryDelay: error.retryDelay,
            context: context
        )
    }
    
    private func createPresentableError(from error: Error, context: ErrorContext) async -> PresentableError {
        let errorHandlingService = ErrorHandlingService()
        let (errorInfo, recoveryResult) = await errorHandlingService.analyzeAndRecoverError(error)
        
        var actions: [ErrorHandlingService.ErrorAction] = []
        
        // Add context-specific actions
        switch context {
        case .routePlanning:
            actions.append(contentsOf: [.retry, .adjustTime, .reverseRoute])
        case .locationSearch:
            actions.append(contentsOf: [.useCurrentLocation, .searchNearby, .editSearch])
        case .widgetConfiguration:
            actions.append(contentsOf: [.retry, .reportIssue])
        case .backgroundRefresh:
            actions.append(contentsOf: [.retry, .checkConnection])
        case .general:
            actions.append(contentsOf: errorInfo.suggestedActions)
        }
        
        // Add recovery result specific actions
        if let recovery = recoveryResult {
            switch recovery {
            case .requiresUserInput:
                actions.append(.reportIssue)
            case .retryWithFallback:
                actions.append(.waitAndRetry)
            case .recovered:
                // No additional action needed
                break
            }
        }
        
        return PresentableError(
            title: errorInfo.title,
            message: errorInfo.message,
            recoverySuggestion: errorInfo.originalError?.localizedDescription,
            severity: .medium, // Default severity for non-enhanced errors
            actions: Array(Set(actions)), // Remove duplicates
            canRetryAutomatically: errorInfo.canRetryAutomatically,
            retryDelay: errorInfo.retryDelay,
            context: context
        )
    }
    
    private func createRecoveryActions(for error: EnhancedAppError, context: ErrorContext) -> [ErrorHandlingService.ErrorAction] {
        var actions: [ErrorHandlingService.ErrorAction] = []
        
        // Add error-specific actions
        switch error {
        case .widgetConfigurationFailed:
            actions.append(contentsOf: [.retry, .reportIssue])
        case .locationPermissionDenied:
            actions.append(.reportIssue) // Will be handled as "open settings"
        case .backgroundRefreshDisabled:
            actions.append(.reportIssue) // Will be handled as "open settings"
        case .notificationSchedulingFailed:
            actions.append(.reportIssue) // Will be handled as "open settings"
        case .networkTimeout, .apiRateLimited:
            actions.append(contentsOf: [.retry, .checkConnection])
        case .memoryPressureCritical:
            actions.append(.reportIssue) // Will be handled as "close other apps"
        case .dataCorruption:
            actions.append(contentsOf: [.retry, .reportIssue])
        default:
            actions.append(.retry)
        }
        
        // Add context-specific actions
        switch context {
        case .routePlanning:
            actions.append(contentsOf: [.adjustTime, .reverseRoute])
        case .locationSearch:
            actions.append(contentsOf: [.useCurrentLocation, .searchNearby])
        default:
            break
        }
        
        return Array(Set(actions)) // Remove duplicates
    }
}

// MARK: - Presentable Error Model

struct PresentableError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let recoverySuggestion: String?
    let severity: ErrorSeverity
    let actions: [ErrorHandlingService.ErrorAction]
    let canRetryAutomatically: Bool
    let retryDelay: TimeInterval?
    let context: ErrorContext
    
    var displayIcon: String {
        switch severity {
        case .low:
            return "info.circle"
        case .medium:
            return "exclamationmark.triangle"
        case .high:
            return "exclamationmark.circle"
        case .critical:
            return "xmark.octagon"
        }
    }
    
    var displayColor: Color {
        switch severity {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .purple
        }
    }
}

// MARK: - Error Context

enum ErrorContext {
    case general
    case routePlanning
    case locationSearch
    case widgetConfiguration
    case backgroundRefresh
    
    var displayName: String {
        switch self {
        case .general:
            return "General"
        case .routePlanning:
            return "Route Planning"
        case .locationSearch:
            return "Location Search"
        case .widgetConfiguration:
            return "Widget Setup"
        case .backgroundRefresh:
            return "Background Refresh"
        }
    }
}

// MARK: - Enhanced Error Actions

extension ErrorHandlingService.ErrorAction {
    var isSettingsAction: Bool {
        switch self {
        case .reportIssue:
            return true // We'll use reportIssue as a proxy for settings actions
        default:
            return false
        }
    }
    
    var actionDescription: String {
        switch self {
        case .reportIssue:
            return "Open Settings or report this issue"
        default:
            return displayText
        }
    }
}

// MARK: - Error Alert View

struct ErrorAlertView: View {
    let error: PresentableError
    let onAction: (ErrorHandlingService.ErrorAction) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Error Icon and Title
            HStack {
                Image(systemName: error.displayIcon)
                    .foregroundColor(error.displayColor)
                    .font(.title2)
                
                Text(error.title)
                    .font(.headline)
                    .foregroundColor(error.displayColor)
                
                Spacer()
            }
            
            // Error Message
            Text(error.message)
                .font(.body)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Recovery Suggestion
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Retry Information
            if error.canRetryAutomatically, let delay = error.retryDelay {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                    Text("Automatic retry in \(Int(delay)) seconds")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Action Buttons
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(Array(error.actions.prefix(4).enumerated()), id: \.offset) { index, action in
                    Button(action: {
                        onAction(action)
                    }) {
                        HStack {
                            Image(systemName: action.systemImageName)
                            Text(action.displayText)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                }
            }
            
            // Dismiss Button
            Button("Dismiss") {
                onDismiss()
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}

// MARK: - Error Toast View

struct ErrorToastView: View {
    let error: PresentableError
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        HStack {
            Image(systemName: error.displayIcon)
                .foregroundColor(error.displayColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(error.message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isVisible = true
            }
            
            // Auto-dismiss for low severity errors
            if error.severity == .low {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isVisible = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Error Presentation Modifier

struct ErrorPresentationModifier: ViewModifier {
    @StateObject private var errorService = ErrorPresentationService.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorService.isShowingError) {
                if let error = errorService.currentError {
                    ForEach(Array(error.actions.prefix(3).enumerated()), id: \.offset) { index, action in
                        Button(action.displayText) {
                            handleErrorAction(action, for: error)
                        }
                    }
                    
                    Button("Dismiss", role: .cancel) {
                        errorService.dismissError()
                    }
                }
            } message: {
                if let error = errorService.currentError {
                    Text(error.message)
                }
            }
    }
    
    private func handleErrorAction(_ action: ErrorHandlingService.ErrorAction, for error: PresentableError) {
        switch action {
        case .retry:
            // Implement retry logic
            break
        case .checkConnection:
            // Implement connection check
            break
        case .useCurrentLocation:
            // Implement location usage
            break
        case .reportIssue:
            // Implement issue reporting
            break
        default:
            break
        }
        
        errorService.dismissError()
    }
}

extension View {
    func errorPresentation() -> some View {
        modifier(ErrorPresentationModifier())
    }
}