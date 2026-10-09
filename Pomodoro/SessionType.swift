import Foundation

/// Defines the three Pomodoro session types with their initial default durations.
enum SessionType: String, CaseIterable, Identifiable {
    case shortBreak = "Short Break"
    case focus = "Focus"
    case longBreak = "Long Break"

    var id: String { rawValue }

    /// Default duration in seconds for each session type.
    var defaultDuration: TimeInterval {
        switch self {
        case .focus:      return 25 * 60  // 25 minutes
        case .shortBreak: return  5 * 60  //  5 minutes
        case .longBreak:  return 15 * 60  // 15 minutes
        }
    }
}
