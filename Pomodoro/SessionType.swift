import Foundation

/// Defines the three Pomodoro session types with their fixed durations.
enum SessionType: String, CaseIterable, Identifiable {
    case timer = "Timer"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"

    var id: String { rawValue }

    /// Fixed duration in seconds for each session type.
    var duration: TimeInterval {
        switch self {
        case .timer:      return 25 * 60  // 25 minutes
        case .shortBreak: return  5 * 60  //  5 minutes
        case .longBreak:  return 15 * 60  // 15 minutes
        }
    }
}
