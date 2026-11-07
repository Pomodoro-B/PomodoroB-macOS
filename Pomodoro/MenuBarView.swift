import SwiftUI

// MARK: - Isolated Timer Display
// This tiny view only subscribes to formattedTime, so only it re-renders each tick.
private struct TimerTextView: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        Text(timerManager.formattedTime)
            .font(.system(size: 64, weight: .bold, design: .rounded))
            .foregroundColor(Color.themePrimaryText)
            .monospacedDigit()
            .contentTransition(.numericText(countsDown: true))
            .animation(.linear(duration: 0.15), value: timerManager.formattedTime)
            .accessibilityLabel("Time remaining: \(timerManager.formattedTime)")
    }
}

// MARK: - Isolated Progress Ring
// Subscribes only to progress; re-renders independently of timer text.
private struct ProgressRingView: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
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
                .animation(.linear(duration: 0.15), value: timerManager.progress)
        }
    }
}

/// The main menu bar popover view.
struct MenuBarView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var showingSettings = false
    @Namespace private var tabNamespace

    var body: some View {
        ZStack {
            if showingSettings {
                SettingsView(timerManager: timerManager, showingSettings: $showingSettings)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else {
                mainTimerView
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .frame(width: 320, height: 350)
        .background(Color.themePopoverBackground)
        .preferredColorScheme(timerManager.isDarkMode ? .dark : .light)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showingSettings)
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

            // Session label — animates when session changes
            Text(timerManager.currentSession.rawValue)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.themeSecondaryText)
                .padding(.top, 12)
                .animation(.easeInOut(duration: 0.2), value: timerManager.currentSession)

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
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    timerManager.switchSession(to: session)
                }
            }
        } label: {
            VStack(spacing: 8) {
                Text(session.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? Color.themePrimaryText : Color.themeSecondaryText)
                    .lineLimit(1)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)

                // matchedGeometryEffect makes the accent bar slide between tabs
                ZStack {
                    if isSelected {
                        Rectangle()
                            .fill(Color.themeAccent)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "tabUnderline", in: tabNamespace)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 2)
                    }
                }
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
            // Isolated progress ring — only re-renders when progress changes
            ProgressRingView(timerManager: timerManager)

            // Isolated timer text — only re-renders when formatted time changes
            TimerTextView(timerManager: timerManager)
        }
        .frame(width: 250, height: 110)
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: 12) {
            // Start / Pause button
            startPauseButton

            // Stop button (only visible when timer is active)
            if timerManager.timerState != .stopped {
                stopButton
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            Spacer()

            // Settings button
            settingsButton
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: timerManager.timerState)
    }

    private var startPauseButton: some View {
        let isRunning = timerManager.timerState == .running
        let label = isRunning ? "Pause" : "Start"

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                timerManager.toggleStartPause()
            }
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
                .contentTransition(.interpolate)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .animation(.easeInOut(duration: 0.15), value: isRunning)
    }

    private var stopButton: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
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
            showingSettings = true
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
