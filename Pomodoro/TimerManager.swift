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

    @Published var currentSession: SessionType = .focus
    @Published var timerState: TimerState = .stopped
    @Published var remainingTime: TimeInterval
    @Published var progress: Double = 0.0
    @Published var autoStartNextSession: Bool {
        didSet {
            UserDefaults.standard.set(autoStartNextSession, forKey: "autoStartNextSession")
        }
    }
    
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    @Published var longBreakFrequency: Int {
        didSet {
            UserDefaults.standard.set(longBreakFrequency, forKey: "longBreakFrequency")
        }
    }
    
    @Published var focusDurationMinutes: Int {
        didSet {
            UserDefaults.standard.set(focusDurationMinutes, forKey: "focusDurationMinutes")
            if currentSession == .focus && timerState == .stopped {
                remainingTime = duration(for: .focus)
            }
        }
    }
    
    @Published var shortBreakDurationMinutes: Int {
        didSet {
            UserDefaults.standard.set(shortBreakDurationMinutes, forKey: "shortBreakDurationMinutes")
            if currentSession == .shortBreak && timerState == .stopped {
                remainingTime = duration(for: .shortBreak)
            }
        }
    }
    
    @Published var longBreakDurationMinutes: Int {
        didSet {
            UserDefaults.standard.set(longBreakDurationMinutes, forKey: "longBreakDurationMinutes")
            if currentSession == .longBreak && timerState == .stopped {
                remainingTime = duration(for: .longBreak)
            }
        }
    }

    // MARK: - Private Properties

    private var endDate: Date?
    private var pausedRemaining: TimeInterval?
    private var displayTimer: Timer?
    private var completionSoundPlayed = false
    private var completedFocusSessions: Int = 0

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
        
        // Use true as default for dark mode if not explicitly set, or read from UserDefaults
        if UserDefaults.standard.object(forKey: "isDarkMode") != nil {
            self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        } else {
            self.isDarkMode = true // Default to true or match system
        }
        
        self.focusDurationMinutes = UserDefaults.standard.object(forKey: "focusDurationMinutes") as? Int ?? 25
        self.shortBreakDurationMinutes = UserDefaults.standard.object(forKey: "shortBreakDurationMinutes") as? Int ?? 5
        self.longBreakDurationMinutes = UserDefaults.standard.object(forKey: "longBreakDurationMinutes") as? Int ?? 15

        self.remainingTime = 0 // Will be set by switchSession or immediately below
        
        requestNotificationPermission()
        
        self.remainingTime = duration(for: .focus)
    }

    // MARK: - Public Actions
    
    func duration(for session: SessionType) -> TimeInterval {
        switch session {
        case .focus: return TimeInterval(focusDurationMinutes * 60)
        case .shortBreak: return TimeInterval(shortBreakDurationMinutes * 60)
        case .longBreak: return TimeInterval(longBreakDurationMinutes * 60)
        }
    }

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
        remainingTime = duration(for: currentSession)
        progress = 0.0
        timerState = .stopped
        completionSoundPlayed = false
    }

    /// Switch to a different session type.
    /// If a timer is running or paused, this does nothing to protect the active session.
    func switchSession(to session: SessionType) {
        guard timerState == .stopped || timerState == .completed else { return }
        currentSession = session
        remainingTime = duration(for: session)
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
        let total = duration(for: currentSession)
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
        case .focus:
            // Check if a long break is due
            if longBreakFrequency > 0 && completedFocusSessions >= longBreakFrequency {
                return .longBreak
            }
            return .shortBreak

        case .shortBreak:
            return .focus

        case .longBreak:
            return .focus
        }
    }

    private func handleCompletion() {
        let completedSession = currentSession

        // Track completed focus sessions BEFORE determining next session
        if completedSession == .focus {
            completedFocusSessions += 1
        }

        // Determine the next session
        let next = nextSession(after: completedSession)

        // Reset counter after a long break is selected as the next session
        if completedSession == .longBreak {
            completedFocusSessions = 0
        }

        // Send notification for the transition
        sendTransitionNotification(from: completedSession, to: next)

        // Transition to next session
        currentSession = next
        remainingTime = duration(for: next)
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
        case .focus:
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
