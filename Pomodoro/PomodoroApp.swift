import SwiftUI
import AppKit
import Combine
import UserNotifications

/// Delegate that configures the app as a menu bar accessory (no Dock icon).
/// This runs after NSApplication is fully initialized, avoiding the nil crash.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    // `lazy` ensures TimerManager is created after applicationDidFinishLaunching sets the
    // UNUserNotificationCenter delegate. This guarantees the delegate is in place before
    // requestNotificationPermission() fires inside TimerManager.init().
    lazy var timerManager = TimerManager()

    private let statusItemWidth: CGFloat = 72
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var remainingTimeObserver: AnyCancellable?
    private var statusItemTitle: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // ⚠️ CRITICAL: Set the delegate BEFORE anything posts a notification.
        // TimerManager.init() calls requestNotificationPermission() synchronously,
        // so the delegate must be assigned first so the system can route future
        // willPresent callbacks correctly.
        UNUserNotificationCenter.current().delegate = self

        // Clear any stale badge/notifications from a previous session
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        NSApp.dockTile.badgeLabel = nil

        configureStatusItem()

        // Explicitly re-verify permission now that the delegate is set.
        // The lazy timerManager init may have already called this, but calling
        // it again is cheap and idempotent — the system shows the prompt only once.
        timerManager.requestNotificationPermission()

        // Auto-open popover on launch if the user has enabled this setting
        if timerManager.openOnLaunch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.openPopover()
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification is about to be presented while the app is in the foreground.
    /// Menu bar apps are considered "foreground" at all times, so without this delegate method
    /// macOS would swallow every notification silently. We must explicitly opt in to display.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // .banner  — the slide-in alert
        // .sound   — the audible chime
        // .badge   — dock/status badge (no dock icon for this app, but harmless)
        // .list    — appears in Notification Center history
        completionHandler([.banner, .sound, .badge, .list])
    }

    /// Called when the user taps/clicks a delivered notification.
    /// Open the popover so the user can see the current timer state.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            self.openPopover()
        }
        completionHandler()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: statusItemWidth)
        guard let button = item.button else { return }

        button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Pomodoro/B")
        button.imagePosition = .imageLeft
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        // Enable native NSPopover animation
        popover.animates = true
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(timerManager: timerManager)
        )
        // Set a fixed content size to prevent layout thrash during animation
        popover.contentSize = NSSize(width: 320, height: 350)

        statusItem = item
        updateStatusItemTitle(for: timerManager.remainingTime)
        remainingTimeObserver = timerManager.$remainingTime.sink { [weak self] remainingTime in
            self?.updateStatusItemTitle(for: remainingTime)
        }
    }

    private func openPopover() {
        guard let button = statusItem?.button, !popover.isShown else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
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
            openPopover()
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
