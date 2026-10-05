import Foundation
import AppKit
import Combine
import UserNotifications

/// Represents the four possible timer states.
enum TimerState {
    case stopped
    case running
    case paused
    case completed
}

/// Central manager for all timer logic. Observed by SwiftUI views.
@MainActor
final class TimerManager: ObservableObject {

    // MARK: - Published Properties

    @Published var currentSession: SessionType = .timer
    @Published var timerState: TimerState = .stopped
    @Published var remainingTime: TimeInterval
    @Published var progress: Double = 0.0
    @Published var autoStartNextSession: Bool {
        didSet {
            UserDefaults.standard.set(autoStartNextSession, forKey: "autoStartNextSession")
        }
    }
    @Published var longBreakFrequency: Int {
        didSet {
            UserDefaults.standard.set(longBreakFrequency, forKey: "longBreakFrequency")
        }
    }

    // MARK: - Private Properties

    private var endDate: Date?
    private var pausedRemaining: TimeInterval?
    private var displayTimer: Timer?
    private var completionSoundPlayed = false
    private var completedShortBreaks: Int = 0

    // MARK: - Computed Properties

    /// Formatted remaining time as MM:SS for menu bar display.
    var formattedTime: String {
        Self.formattedTime(for: remainingTime)
    }

    static func formattedTime(for remainingTime: TimeInterval) -> String {
        let totalSeconds = max(0, Int(remainingTime.rounded(.up)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Initialization

    init() {
        let savedAutoStart = UserDefaults.standard.bool(forKey: "autoStartNextSession")
        self.autoStartNextSession = savedAutoStart

        let savedFrequency = UserDefaults.standard.object(forKey: "longBreakFrequency") as? Int ?? 4
        self.longBreakFrequency = savedFrequency

        self.remainingTime = SessionType.timer.duration

        requestNotificationPermission()
    }

    // MARK: - Public Actions

    /// Start or resume the timer.
    func start() {
        switch timerState {
        case .stopped, .completed:
            // Start fresh from full duration
            completionSoundPlayed = false
            let duration = remainingTime
            endDate = Date().addingTimeInterval(duration)
            timerState = .running
            startDisplayTimer()

        case .paused:
            // Resume from paused remaining time
            if let paused = pausedRemaining {
                endDate = Date().addingTimeInterval(paused)
                pausedRemaining = nil
            }
            timerState = .running
            startDisplayTimer()

        case .running:
            break
        }
    }

    /// Pause the running timer.
    func pause() {
        guard timerState == .running, let end = endDate else { return }
        pausedRemaining = max(0, end.timeIntervalSinceNow)
        remainingTime = pausedRemaining ?? 0
        endDate = nil
        timerState = .paused
        stopDisplayTimer()
        updateProgress()
    }

    /// Stop and reset the timer to the current session's full duration.
    func stop() {
        stopDisplayTimer()
        endDate = nil
        pausedRemaining = nil
        remainingTime = currentSession.duration
        progress = 0.0
        timerState = .stopped
        completionSoundPlayed = false
    }

    /// Switch to a different session type.
    /// If a timer is running or paused, this does nothing to protect the active session.
    func switchSession(to session: SessionType) {
        guard timerState == .stopped || timerState == .completed else { return }
        currentSession = session
        remainingTime = session.duration
        progress = 0.0
        timerState = .stopped
        completionSoundPlayed = false
    }

    /// Toggle between start and pause based on current state.
    func toggleStartPause() {
        switch timerState {
        case .stopped, .paused, .completed:
            start()
        case .running:
            pause()
        }
    }

    // MARK: - Private Methods

    private func startDisplayTimer() {
        stopDisplayTimer()
        tick()
    }

    private func scheduleNextDisplayUpdate() {
        guard timerState == .running, let end = endDate else { return }

        let remaining = end.timeIntervalSinceNow
        guard remaining > 0 else {
            tick()
            return
        }

        let displayedSeconds = Int(remaining.rounded(.up))
        let interval = remaining - Double(displayedSeconds - 1)

        displayTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }

    private func tick() {
        guard timerState == .running, let end = endDate else { return }

        let remaining = end.timeIntervalSinceNow
        if remaining <= 0 {
            // Timer completed
            remainingTime = 0
            progress = 1.0
            timerState = .completed
            stopDisplayTimer()
            endDate = nil
            pausedRemaining = nil
            playCompletionSound()
            handleCompletion()
        } else {
            if Int(remaining.rounded(.up)) != Int(remainingTime.rounded(.up)) {
                remainingTime = remaining
                updateProgress()
            }
            scheduleNextDisplayUpdate()
        }
    }

    private func updateProgress() {
        let total = currentSession.duration
        guard total > 0 else {
            progress = 0
            return
        }
        let elapsed = total - remainingTime
        progress = min(1.0, max(0.0, elapsed / total))
    }

    private func playCompletionSound() {
        guard !completionSoundPlayed else { return }
        completionSoundPlayed = true
        NSSound(named: "Glass")?.play()
    }

    // MARK: - Session Transition

    /// Determines the next session based on the completed session and the short break counter.
    private func nextSession(after completed: SessionType) -> SessionType {
        switch completed {
        case .timer:
            // Check if a long break is due
            if longBreakFrequency > 0 && completedShortBreaks >= longBreakFrequency {
                return .longBreak
            }
            return .shortBreak

        case .shortBreak:
            return .timer

        case .longBreak:
            return .timer
        }
    }

    private func handleCompletion() {
        let completedSession = currentSession

        // Track completed short breaks BEFORE determining next session
        if completedSession == .shortBreak {
            completedShortBreaks += 1
        }

        // Determine the next session
        let next = nextSession(after: completedSession)

        // Reset counter after a long break is selected as the next session
        if completedSession == .longBreak {
            completedShortBreaks = 0
        }

        // Send notification for the transition
        sendTransitionNotification(from: completedSession, to: next)

        // Transition to next session
        currentSession = next
        remainingTime = next.duration
        progress = 0.0
        completionSoundPlayed = false

        if autoStartNextSession {
            start()
        } else {
            timerState = .stopped
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in
            // Permission result handled gracefully — timer works regardless
        }
    }

    private func sendTransitionNotification(from completed: SessionType, to next: SessionType) {
        let body: String
        switch next {
        case .timer:
            body = "Time to focus"
        case .shortBreak:
            body = "Time for a short break"
        case .longBreak:
            body = "Time for a long break"
        }

        let content = UNMutableNotificationContent()
        content.title = "Pomodoro/B"
        content.body = body

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request)
    }
}
