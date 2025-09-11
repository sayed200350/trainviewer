import SwiftUI

struct SemesterTicketNotificationSettingsView: View {
    @StateObject private var viewModel = SemesterTicketNotificationViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("Enable Renewal Notifications", isOn: $viewModel.notificationsEnabled)
                        .onChange(of: viewModel.notificationsEnabled) { _ in
                            viewModel.toggleNotifications()
                        }
                        .tint(.brandBlue)
                } header: {
                    Text("Notifications")
                } footer: {
                    if viewModel.notificationsEnabled {
                        Text("You'll receive reminders before your semester ticket expires")
                    } else {
                        Text("Turn on notifications to get renewal reminders")
                    }
                }

                if viewModel.notificationsEnabled {
                    Section {
                        ForEach(viewModel.availableDaysOptions, id: \.self) { days in
                            NotificationDayRow(
                                days: days,
                                isSelected: viewModel.isDaySelected(days)
                            ) {
                                viewModel.toggleDay(days)
                            }
                        }
                    } header: {
                        Text("Remind me")
                    } footer: {
                        Text("Choose when you want to be notified before expiry")
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview")
                                .font(.headline)
                                .foregroundColor(.brandBlue)

                            Text("You'll receive notifications like:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 12) {
                                NotificationPreview(
                                    title: "Semester Ticket Expires Soon",
                                    subtitle: "30 days remaining",
                                    content: "Your semester ticket for Technical University of Munich expires in 30 days. Start planning your renewal!"
                                )

                                NotificationPreview(
                                    title: "Semester Ticket Expires Soon",
                                    subtitle: "1 week remaining",
                                    content: "Your semester ticket for Technical University of Munich expires in 1 week. Time to renew!"
                                )

                                NotificationPreview(
                                    title: "Semester Ticket Expires Soon",
                                    subtitle: "Expires tomorrow",
                                    content: "⚠️ Your semester ticket for Technical University of Munich expires tomorrow!"
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Preview")
                    }

                    Section {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.brandBlue)
                            Text("Notifications will be scheduled automatically when you add or update semester tickets.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Renewal Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.checkAuthorization()
            }
        }
    }
}

struct NotificationDayRow: View {
    let days: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(dayDescription)
                        .foregroundColor(.primary)
                    if let subtitle = daySubtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.brandBlue)
                }
            }
        }
    }

    private var dayDescription: String {
        switch days {
        case 1: return "1 day before"
        case 3: return "3 days before"
        case 7: return "1 week before"
        case 14: return "2 weeks before"
        case 21: return "3 weeks before"
        case 30: return "1 month before"
        case 45: return "6 weeks before"
        case 60: return "2 months before"
        default: return "\(days) days before"
        }
    }

    private var daySubtitle: String? {
        switch days {
        case 1: return "Last chance to renew"
        case 7: return "Recommended renewal time"
        case 30: return "Early planning reminder"
        default: return nil
        }
    }
}

struct NotificationPreview: View {
    let title: String
    let subtitle: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.brandBlue)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.brandBlue)
                .padding(.leading, 16)

            Text(content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(.leading, 16)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SemesterTicketNotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SemesterTicketNotificationSettingsView()
    }
}
