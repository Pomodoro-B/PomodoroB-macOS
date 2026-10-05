import SwiftUI

/// Settings view — minimal, just the auto-start toggle.
struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager
    @Binding var showingSettings: Bool

    private let bgColor = Color(red: 0.07, green: 0.07, blue: 0.07)
    private let secondaryGray = Color(red: 0.557, green: 0.557, blue: 0.576)
    private let accentOrange = Color(red: 1.0, green: 0.624, blue: 0.039)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with back button
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showingSettings = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(accentOrange)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to timer")

                Spacer()

                Text("Settings")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                // Invisible spacer to balance the header
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 13, weight: .medium))
                }
                .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)

            // Auto-start toggle
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $timerManager.autoStartNextSession) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto Start Next Session")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)

                        Text("Automatically start the next session")
                            .font(.system(size: 11))
                            .foregroundColor(secondaryGray)
                    }
                }
                .toggleStyle(.switch)
                .tint(accentOrange)
                .accessibilityLabel("Auto Start Next Session")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)

            // Long Break Frequency
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Long Break Frequency")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)

                        Text("Number of short breaks before a long break. Set to 0 to disable automatic long breaks.")
                            .font(.system(size: 11))
                            .foregroundColor(secondaryGray)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Stepper(value: $timerManager.longBreakFrequency, in: 0...10) {
                        Text("\(timerManager.longBreakFrequency)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .frame(minWidth: 20, alignment: .trailing)
                    }
                    .accessibilityLabel("Long Break Frequency: \(timerManager.longBreakFrequency)")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer()

            // Quit button
            HStack {
                Spacer()
                Button {
                    NSApp.terminate(nil)
                } label: {
                    Text("Quit Pomodoro/B")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(secondaryGray)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Quit application")
                Spacer()
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bgColor)
    }
}
