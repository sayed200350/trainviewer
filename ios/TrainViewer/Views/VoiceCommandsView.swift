import SwiftUI
import Speech

/// Voice Commands interface for hands-free route management
struct VoiceCommandsView: View {
    @EnvironmentObject var vm: RoutesViewModel
    @State private var isRecording = false
    @State private var recognizedText = ""
    @State private var commandSuggestions: [VoiceCommand] = []
    @State private var lastExecutedCommand: String = ""
    @State private var showingPermissionsAlert = false

    // Simplified implementation - full speech recognition would be implemented in production

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandDark.edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Voice Commands")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)

                                Text("Control your routes with your voice")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .background(Color.brandDark)

                    // Voice recording interface
                    ScrollView {
                        VStack(spacing: 24) {
                            voiceRecordingSection
                            commandSuggestionsSection
                            recentCommandsSection
                            voiceCommandListSection
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Microphone Permission Required", isPresented: $showingPermissionsAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enable microphone access in your device Settings > Privacy & Security > Microphone to use voice commands.")
            }
        }
    }

    private var voiceRecordingSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.accentRed.opacity(0.2) : Color.brandBlue.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Circle()
                            .stroke(isRecording ? Color.accentRed : Color.brandBlue, lineWidth: 3)
                    )
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isRecording)

                VStack(spacing: 16) {
                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 48))
                        .foregroundColor(isRecording ? .accentRed : .brandBlue)
                        .scaleEffect(isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isRecording)

                    Text(isRecording ? "Listening..." : "Tap to speak")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                }
            }
            .onTapGesture {
                toggleRecording()
            }

            if !recognizedText.isEmpty {
                VStack(spacing: 8) {
                    Text("Recognized:")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)

                    Text("\"\(recognizedText)\"")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .padding(12)
                        .background(Color.cardBackground)
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if !lastExecutedCommand.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentGreen)
                    Text("Executed: \(lastExecutedCommand)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.accentGreen)
                }
                .padding(12)
                .background(Color.accentGreen.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private var commandSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Commands")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.textPrimary)

            if commandSuggestions.isEmpty {
                Text("Try saying: \"Show next departures\" or \"Add route to work\"")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .padding(16)
                    .background(Color.cardBackground)
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(commandSuggestions) { command in
                        VoiceCommandSuggestionRow(command: command) {
                            executeCommand(command)
                        }
                    }
                }
            }
        }
    }

    private var recentCommandsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Commands")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.textPrimary)

            VStack(spacing: 8) {
                RecentCommandRow(command: "Show next departures", timestamp: Date().addingTimeInterval(-300))
                RecentCommandRow(command: "Add route to gym", timestamp: Date().addingTimeInterval(-1800))
                RecentCommandRow(command: "Set reminder for work", timestamp: Date().addingTimeInterval(-3600))
            }
        }
    }

    private var voiceCommandListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Commands")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.textPrimary)

            VStack(spacing: 12) {
                VoiceCommandCategory(
                    title: "Route Management",
                    commands: [
                        "Add route to [destination]",
                        "Show route to [destination]",
                        "Delete route to [destination]",
                        "Favorite route to [destination]"
                    ]
                )

                VoiceCommandCategory(
                    title: "Journey Information",
                    commands: [
                        "Show next departures",
                        "What's the delay for [route]?",
                        "When is the next train?",
                        "Show platform for [route]"
                    ]
                )

                VoiceCommandCategory(
                    title: "Reminders & Alerts",
                    commands: [
                        "Set reminder for [route]",
                        "Remind me to leave in [time]",
                        "Cancel reminder for [route]"
                    ]
                )
            }
        }
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        // Demo implementation - no actual microphone access needed
        // In production, implement full speech recognition with proper permissions
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isRecording = false
            recognizedText = "Add route to work"
            processVoiceCommand(recognizedText)
        }
        isRecording = true
    }

    private func beginRecording() {
        // Simplified implementation - in production, implement full speech recognition
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isRecording = false
            recognizedText = "Add route to work"
            processVoiceCommand(recognizedText)
        }
        isRecording = true
    }

    private func stopRecording() {
        isRecording = false
    }

    private func processVoiceCommand(_ command: String) {
        let lowercasedCommand = command.lowercased()

        // Generate suggestions based on the command
        commandSuggestions = generateCommandSuggestions(for: lowercasedCommand)

        // Auto-execute if it's a clear command
        if let autoCommand = findMatchingCommand(lowercasedCommand) {
            executeCommand(autoCommand)
        }
    }

    private func generateCommandSuggestions(for text: String) -> [VoiceCommand] {
        // Simple matching logic - in a real implementation, this would use NLP
        if text.contains("add") || text.contains("create") {
            return [VoiceCommand(type: .addRoute, text: "Add new route", confidence: 0.8)]
        } else if text.contains("show") || text.contains("display") {
            return [
                VoiceCommand(type: .showDepartures, text: "Show next departures", confidence: 0.9),
                VoiceCommand(type: .showRoute, text: "Show route details", confidence: 0.7)
            ]
        } else if text.contains("delete") || text.contains("remove") {
            return [VoiceCommand(type: .deleteRoute, text: "Delete route", confidence: 0.8)]
        }

        return []
    }

    private func findMatchingCommand(_ text: String) -> VoiceCommand? {
        // Find the best matching command
        return commandSuggestions.first { $0.confidence > 0.8 }
    }

    private func executeCommand(_ command: VoiceCommand) {
        lastExecutedCommand = command.text

        switch command.type {
        case .addRoute:
            // Navigate to add route screen
            print("Executing: Add route")
        case .showDepartures:
            // Refresh all routes
            Task { await vm.refreshAll() }
            print("Executing: Show departures")
        case .showRoute:
            // Show route details
            print("Executing: Show route")
        case .deleteRoute:
            // Show delete confirmation
            print("Executing: Delete route")
        }

        // Clear suggestions after execution
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.commandSuggestions.removeAll()
        }
    }
}

// MARK: - Supporting Components
struct VoiceCommandSuggestionRow: View {
    let command: VoiceCommand
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(command.text)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.textPrimary)

                    HStack(spacing: 4) {
                        ForEach(0..<command.confidenceLevel, id: \.self) { _ in
                            Circle()
                                .fill(Color.accentGreen)
                                .frame(width: 4, height: 4)
                        }
                    }
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .foregroundColor(.textSecondary)
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct RecentCommandRow: View {
    let command: String
    let timestamp: Date

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(command)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text(timestamp.formattedTimeAgo())
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Image(systemName: "mic.fill")
                .font(.system(size: 16))
                .foregroundColor(.textSecondary)
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(8)
    }
}

struct VoiceCommandCategory: View {
    let title: String
    let commands: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.textPrimary)

            VStack(spacing: 6) {
                ForEach(commands, id: \.self) { command in
                    HStack {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)

                        Text(command)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.textSecondary)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.elevatedBackground)
                    .cornerRadius(6)
                }
            }
        }
    }
}

// MARK: - Voice Command Types
struct VoiceCommand: Identifiable {
    let id = UUID()
    let type: VoiceCommandType
    let text: String
    let confidence: Double

    var confidenceLevel: Int {
        if confidence >= 0.9 { return 5 }
        else if confidence >= 0.8 { return 4 }
        else if confidence >= 0.7 { return 3 }
        else if confidence >= 0.6 { return 2 }
        else { return 1 }
    }
}

enum VoiceCommandType {
    case addRoute
    case showDepartures
    case showRoute
    case deleteRoute
}

#Preview {
    VoiceCommandsView()
        .environmentObject(RoutesViewModel())
        .preferredColorScheme(.dark)
}
