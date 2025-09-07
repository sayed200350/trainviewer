import SwiftUI

// MARK: - Error Handling Example View

/// Example view demonstrating how to use the enhanced error handling system
struct ErrorHandlingExampleView: View {
    @StateObject private var viewModel = ErrorHandlingExampleViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enhanced Error Handling Demo")
                    .font(.title)
                    .padding()
                
                VStack(spacing: 12) {
                    Button("Simulate Network Error") {
                        viewModel.simulateNetworkError()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Simulate Widget Error") {
                        viewModel.simulateWidgetError()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Simulate Memory Pressure") {
                        viewModel.simulateMemoryPressure()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Simulate Location Error") {
                        viewModel.simulateLocationError()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Generate Error Report") {
                        viewModel.generateErrorReport()
                    }
                    .buttonStyle(.bordered)
                }
                
                if let errorReport = viewModel.errorReport {
                    ScrollView {
                        Text(errorReport)
                            .font(.caption)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 200)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Error Handling")
        }
        .enhancedErrorHandling() // Apply enhanced error handling
    }
}

// MARK: - Example View Model

@MainActor
final class ErrorHandlingExampleViewModel: ObservableObject {
    @Published var errorReport: String?
    
    private let errorIntegrationService = ErrorIntegrationService.shared
    
    func simulateNetworkError() {
        Task {
            let networkError = URLError(.timedOut)
            await errorIntegrationService.handleNetworkError(networkError, context: .routePlanning)
        }
    }
    
    func simulateWidgetError() {
        Task {
            await errorIntegrationService.handleWidgetConfigurationFailure(reason: "Demo widget configuration failure")
        }
    }
    
    func simulateMemoryPressure() {
        Task {
            await errorIntegrationService.handleMemoryPressure()
        }
    }
    
    func simulateLocationError() {
        Task {
            await errorIntegrationService.handlePermissionError(type: .location)
        }
    }
    
    func generateErrorReport() {
        errorReport = errorIntegrationService.generateErrorReport()
    }
}

// MARK: - Preview

struct ErrorHandlingExampleView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorHandlingExampleView()
    }
}