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
