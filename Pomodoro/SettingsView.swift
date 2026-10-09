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
                    .foregroundColor(Color.themeAccent)
                    .padding(.vertical, 8)
                    .padding(.trailing, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to timer")

                Spacer()

                Text("Settings")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.themePrimaryText)

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
            .padding(.bottom, 16)

            Divider()
                .background(Color.themeBorder)
                .padding(.horizontal, 0)
                
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Durations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Timer Durations")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.themeTertiaryText)
                            .textCase(.uppercase)
                            
                        durationRow(title: "Focus", value: $timerManager.focusDurationMinutes)
                        durationRow(title: "Short Break", value: $timerManager.shortBreakDurationMinutes)
                        durationRow(title: "Long Break", value: $timerManager.longBreakDurationMinutes)
                    }
                    .padding(.top, 16)
                    
                    Divider()
                        .background(Color.themeBorder)
                        
                    // Auto-start toggle
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Session Automation")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.themeTertiaryText)
                            .textCase(.uppercase)
                            
                        HStack {
                            Text("Auto Start Next Session")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.themePrimaryText)
                                
                            Spacer()
                                
                            Toggle("", isOn: $timerManager.autoStartNextSession)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .tint(Color.themeAccent)
                                .accessibilityLabel("Auto Start Next Session")
                        }
                    }
                    
                    Divider()
                        .background(Color.themeBorder)
                        
                    // Theme setting
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Appearance")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.themeTertiaryText)
                            .textCase(.uppercase)
                            
                        HStack {
                            Text("Dark Mode")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.themePrimaryText)
                                
                            Spacer()
                                
                            Toggle("", isOn: $timerManager.isDarkMode)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .tint(Color.themeAccent)
                                .accessibilityLabel("Dark Mode")
                        }

                    }
                    
                    Divider()
                        .background(Color.themeBorder)

                    // Long Break Frequency
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cycles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.themeTertiaryText)
                            .textCase(.uppercase)
                            
                        HStack {
                            Text("Long Break Frequency")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.themePrimaryText)
                            
                            Spacer()

                            Stepper(value: $timerManager.longBreakFrequency, in: 0...10) {
                                Text("\(timerManager.longBreakFrequency)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.themePrimaryText)
                                    .monospacedDigit()
                                    .frame(minWidth: 20, alignment: .trailing)
                            }
                            .accessibilityLabel("Long Break Frequency: \(timerManager.longBreakFrequency)")
                        }
                        Text("Number of focus sessions before a long break.")
                            .font(.system(size: 11))
                            .foregroundColor(Color.themeSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            
            Divider()
                .background(Color.themeBorder)

            // Quit button footer
            HStack {
                Spacer()
                Button {
                    NSApp.terminate(nil)
                } label: {
                    Text("Quit Pomodoro/B")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.themeQuitRed)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Quit application")
                Spacer()
            }
            .padding(.vertical, 16)
            .background(Color.themePopoverBackground)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themePopoverBackground)
    }
    
    private func durationRow(title: String, value: Binding<Int>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.themePrimaryText)
            
            Spacer()

            Stepper(value: value, in: 1...120) {
                Text("\(value.wrappedValue) min")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.themePrimaryText)
                    .monospacedDigit()
                    .frame(minWidth: 45, alignment: .trailing)
            }
        }
    }
}
