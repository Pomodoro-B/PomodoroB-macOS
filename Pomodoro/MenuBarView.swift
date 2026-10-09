import SwiftUI

/// The main menu bar popover view.
struct MenuBarView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var showingSettings = false

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
        .frame(width: 320, height: 350)
        .background(Color.themePopoverBackground)
        .preferredColorScheme(timerManager.isDarkMode ? .dark : .light)
        .animation(.easeInOut(duration: 0.25), value: showingSettings)
    }

    // MARK: - Main Timer View

    private var mainTimerView: some View {
        VStack(spacing: 0) {
            // Session tabs
            sessionTabs
                .padding(.top, 20)
                .padding(.horizontal, 20)

            Spacer()

            // Countdown with progress ring
            countdownSection

            // Session label
            Text(timerManager.currentSession.rawValue)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.themeSecondaryText)
                .padding(.top, 12)

            Spacer()

            // Controls
            controlsSection
                .padding(.horizontal, 24)

            // Keep Quit directly accessible from the timer popup.
            quitButton
                .padding(.top, 20)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Session Tabs

    private var sessionTabs: some View {
        HStack(spacing: 0) {
            ForEach(SessionType.allCases) { session in
                sessionTab(for: session)
            }
        }
    }

    private func sessionTab(for session: SessionType) -> some View {
        let isSelected = timerManager.currentSession == session
        let canSwitch = timerManager.timerState == .stopped || timerManager.timerState == .completed

        return Button {
            if canSwitch {
                timerManager.switchSession(to: session)
            }
        } label: {
            VStack(spacing: 8) {
                Text(session.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? Color.themePrimaryText : Color.themeSecondaryText)
                    .lineLimit(1)
                
                Rectangle()
                    .fill(isSelected ? Color.themeAccent : Color.clear)
                    .frame(height: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
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
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(Color.themePrimaryText)
                .monospacedDigit()
                .accessibilityLabel("Time remaining: \(timerManager.formattedTime)")
        }
        .frame(width: 250, height: 110)
    }

    private var progressRing: some View {
        ZStack {
            // Layer 1: Grey base track
            Capsule()
                .stroke(Color.themeProgressTrack, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 250, height: 110)

            // Layer 2: Blue progress stroke
            Capsule()
                .trim(from: 0, to: 1.0 - timerManager.progress)
                .stroke(
                    Color.themeAccent,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 250, height: 110)
                .animation(.linear(duration: 0.1), value: timerManager.progress)
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: 12) {
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

        return Button {
            timerManager.toggleStartPause()
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.themeAccent)
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
            Text("Stop")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.themeQuitRed)
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
                .font(.system(size: 16))
                .foregroundColor(Color.themeSecondaryText)
                .frame(width: 36, height: 36)
                .background(Color.themeSecondarySurface)
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
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.themeQuitRed)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Quit application")
    }
}
