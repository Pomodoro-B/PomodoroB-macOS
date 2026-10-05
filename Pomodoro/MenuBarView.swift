import SwiftUI

/// The main menu bar popover view — compact dark timer UI.
struct MenuBarView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var showingSettings = false

    // MARK: - Colors

    private let bgColor = Color(red: 0.07, green: 0.07, blue: 0.07)
    private let accentOrange = Color(red: 1.0, green: 0.624, blue: 0.039)  // #FF9F0A
    private let secondaryGray = Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93
    private let stopRed = Color(red: 0.85, green: 0.18, blue: 0.18)
    private let stopBgRed = Color(red: 0.25, green: 0.08, blue: 0.08)

    var body: some View {
        ZStack {
            if showingSettings {
                SettingsView(timerManager: timerManager, showingSettings: $showingSettings)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                mainTimerView
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .frame(width: 340, height: 380)
        .background(bgColor)
        .animation(.easeInOut(duration: 0.25), value: showingSettings)
    }

    // MARK: - Main Timer View

    private var mainTimerView: some View {
        VStack(spacing: 0) {
            // Session tabs
            sessionTabs
                .padding(.top, 20)
                .padding(.horizontal, 16)

            Spacer()

            // Countdown with progress ring
            countdownSection

            // Session label
            Text(timerManager.currentSession.rawValue)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(secondaryGray)
                .padding(.top, 8)

            Spacer()

            // Controls
            controlsSection
                .padding(.horizontal, 20)

            // Keep Quit directly accessible from the timer popup.
            quitButton
                .padding(.top, 18)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Session Tabs

    private var sessionTabs: some View {
        HStack(spacing: 4) {
            ForEach(SessionType.allCases) { session in
                sessionTab(for: session)
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func sessionTab(for session: SessionType) -> some View {
        let isSelected = timerManager.currentSession == session
        let canSwitch = timerManager.timerState == .stopped || timerManager.timerState == .completed

        return Button {
            if canSwitch {
                // Switching sessions should update immediately without animating
                // the entire timer view.
                timerManager.switchSession(to: session)
            }
        } label: {
            Text(session.rawValue)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : secondaryGray)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? accentOrange.opacity(0.2) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isSelected ? accentOrange.opacity(0.5) : Color.clear, lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, minHeight: 34)
        .accessibilityLabel(session.rawValue)
        .accessibilityHint(isSelected ? "Currently selected" : (canSwitch ? "Switch to \(session.rawValue)" : "Stop timer first to switch"))
        .opacity(canSwitch || isSelected ? 1.0 : 0.5)
    }

    // MARK: - Countdown Section

    private var countdownSection: some View {
        ZStack {
            // Progress ring
            progressRing

            // Countdown text
            Text(timerManager.formattedTime)
                .font(.system(size: 56, weight: .light, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
                .accessibilityLabel("Time remaining: \(timerManager.formattedTime)")
        }
        .frame(width: 180, height: 180)
    }

    private var progressRing: some View {
        ZStack {
            // Background track
            RoundedRectangle(cornerRadius: 32)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 3)
                .frame(width: 180, height: 180)

            // Progress overlay
            RoundedRectangle(cornerRadius: 32)
                .trim(from: 0, to: timerManager.progress)
                .stroke(
                    accentOrange,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: timerManager.progress)
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: 10) {
            // Start / Pause button
            startPauseButton

            // Stop button (only visible when timer is active)
            if timerManager.timerState != .stopped {
                stopButton
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // Settings button
            settingsButton
        }
        .animation(.easeInOut(duration: 0.2), value: timerManager.timerState)
    }

    private var startPauseButton: some View {
        let isRunning = timerManager.timerState == .running
        let label = isRunning ? "Pause" : "Start"
        let icon = isRunning ? "pause.fill" : "play.fill"

        return Button {
            timerManager.toggleStartPause()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(accentOrange)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var stopButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                timerManager.stop()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("Stop")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(stopRed)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(stopBgRed)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stop")
    }

    private var settingsButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                showingSettings = true
            }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 14))
                .foregroundColor(secondaryGray)
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.06))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
    }

    private var quitButton: some View {
        Button {
            NSApp.terminate(nil)
        } label: {
            Text("Quit Pomodoro/B")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(secondaryGray)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Quit application")
    }
}
