import SwiftUI
import AppKit
import Combine
import UserNotifications

/// Delegate that configures the app as a menu bar accessory (no Dock icon).
/// This runs after NSApplication is fully initialized, avoiding the nil crash.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    let timerManager = TimerManager()

    private let statusItemWidth: CGFloat = 72
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var remainingTimeObserver: AnyCancellable?
    private var statusItemTitle: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate = self
        configureStatusItem()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Present notification banners even when the app is the active application.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: statusItemWidth)
        guard let button = item.button else { return }

        button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Pomodoro/B")
        button.imagePosition = .imageLeft
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(timerManager: timerManager)
        )

        statusItem = item
        updateStatusItemTitle(for: timerManager.remainingTime)
        remainingTimeObserver = timerManager.$remainingTime.sink { [weak self] remainingTime in
            self?.updateStatusItemTitle(for: remainingTime)
        }
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            let menu = NSMenu()
            let quitItem = NSMenuItem(
                title: "Quit Pomodoro/B",
                action: #selector(quitApplication),
                keyEquivalent: ""
            )
            quitItem.target = self
            menu.addItem(quitItem)
            menu.popUp(positioning: nil, at: .zero, in: sender)
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }

    @objc private func quitApplication() {
        NSApp.terminate(nil)
    }

    private func updateStatusItemTitle(for remainingTime: TimeInterval) {
        let title = TimerManager.formattedTime(for: remainingTime)
        guard title != statusItemTitle else { return }

        statusItemTitle = title
        statusItem?.button?.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(
                    ofSize: NSFont.systemFontSize,
                    weight: .regular
                )
            ]
        )
    }
}

/// Pomodoro Timer — a macOS menu bar utility.
/// Uses MenuBarExtra with .window style for a compact popover.
/// Configured as an accessory app (no Dock icon, no main window).
@main
struct PomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

extension Color {
    // Dynamic color helper
    static func dynamicColor(light: UInt32, dark: UInt32) -> Color {
        return Color(NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let hex = isDark ? dark : light
            let r = CGFloat((hex >> 16) & 0xFF) / 255.0
            let g = CGFloat((hex >> 8) & 0xFF) / 255.0
            let b = CGFloat(hex & 0xFF) / 255.0
            return NSColor(red: r, green: g, blue: b, alpha: 1.0)
        })
    }

    static let themePopoverBackground = dynamicColor(light: 0xF5F7F8, dark: 0x1C1C1E)
    static let themeSecondarySurface = dynamicColor(light: 0xE9EEF0, dark: 0x2C2C2E)
    static let themePrimaryText = dynamicColor(light: 0x212B32, dark: 0xF2F2F2)
    static let themeSecondaryText = dynamicColor(light: 0x4C6272, dark: 0xAEB7BD)
    static let themeTertiaryText = dynamicColor(light: 0x768692, dark: 0x768692)
    static let themeBorder = dynamicColor(light: 0xD8DDE0, dark: 0x3A3A3C)
    static let themeProgressTrack = dynamicColor(light: 0xD8E0E4, dark: 0x3A4145)
    static let themeAccent = dynamicColor(light: 0x005EB8, dark: 0x4D8AC7)
    
    static let themeQuitRed = Color(NSColor(red: 0xFF/255.0, green: 0x3B/255.0, blue: 0x30/255.0, alpha: 1.0))
}
