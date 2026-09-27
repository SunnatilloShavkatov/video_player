#if os(iOS)
//
//  ScreenProtectorKit.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 01/11/24.
//

import UIKit

/// A utility class to prevent screenshots and screen recording in iOS applications.
/// Provides comprehensive screen protection features for video content.
public class ScreenProtectorKit {
    
    // Shared across all instances and never removed from the window: each player open
    // would otherwise add a fresh UITextField that stays in the window forever (leak).
    // The field must never deallocate — its dealloc walks a layer tree mangled by the
    // window-layer reparenting below and crashes in -[UITextField dealloc] on iOS 17+.
    private static let sharedScreenPrevent = UITextField()

    // The layer surgery below must run at most once per app lifetime. Re-running it
    // while w.layer already sits inside the field's canvas layer makes addSubview
    // create a CALayer cycle, and Core Animation throws an NSException from
    // CA::Layer::ensure_transaction_recursively (SIGABRT).
    private static var isInstalled = false

    private var window: UIWindow?
    private var screenPrevent: UITextField { Self.sharedScreenPrevent }
    
    /// Initialize ScreenProtectorKit with the app's main window
    /// - Parameter window: The main window of the application
    public init(window: UIWindow?) {
        self.window = window
    }
    
    /// Configure prevention of screenshots by adding a secure text field overlay
    /// 
    /// How to use:
    /// ```swift
    /// override func application(
    ///     _ application: UIApplication,
    ///     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    /// ) -> Bool {
    ///     screenProtectorKit.configurePreventionScreenshot()
    ///     return true
    /// }
    /// ```
    public func configurePreventionScreenshot() {
        guard let w = window, !Self.isInstalled else { return }

        // Secure BEFORE capturing the canvas layer: setting isSecureTextEntry later
        // replaces the field's internal canvas view (iOS 17+), freeing the view whose
        // layer would then still host w.layer.
        screenPrevent.isSecureTextEntry = true

        w.addSubview(screenPrevent)
        Self.isInstalled = true
        screenPrevent.centerYAnchor.constraint(equalTo: w.centerYAnchor).isActive = true
        screenPrevent.centerXAnchor.constraint(equalTo: w.centerXAnchor).isActive = true
        w.layer.superlayer?.addSublayer(screenPrevent.layer)
        if #available(iOS 17.0, *) {
            guard let targetLayer = screenPrevent.layer.sublayers?.last else { return }
            targetLayer.addSublayer(w.layer)
        } else {
            guard let targetLayer = screenPrevent.layer.sublayers?.first else { return }
            targetLayer.addSublayer(w.layer)
        }
    }

    // Toggling isSecureTextEntry replaces the field's internal canvas view (iOS 17+).
    // While installed, w.layer lives inside that canvas layer, so detach it around the
    // toggle and re-attach to the freshly created canvas — otherwise the window layer
    // is left inside a freed layer (dangling delegate) or off screen (black window).
    private func setSecureTextEntry(_ secure: Bool) {
        guard screenPrevent.isSecureTextEntry != secure else { return }
        guard Self.isInstalled, let w = window else {
            screenPrevent.isSecureTextEntry = secure
            return
        }
        w.layer.removeFromSuperlayer()
        screenPrevent.isSecureTextEntry = secure
        let targetLayer: CALayer?
        if #available(iOS 17.0, *) {
            targetLayer = screenPrevent.layer.sublayers?.last
        } else {
            targetLayer = screenPrevent.layer.sublayers?.first
        }
        targetLayer?.addSublayer(w.layer)
    }
    
    /// Enable screenshot prevention by making the text field secure
    ///
    /// How to use:
    /// ```swift
    /// override func applicationDidBecomeActive(_ application: UIApplication) {
    ///     screenProtectorKit.enabledPreventScreenshot()
    /// }
    /// ```
    public func enabledPreventScreenshot() {
        setSecureTextEntry(true)
    }
    
    /// Disable screenshot prevention
    ///
    /// How to use:
    /// ```swift
    /// override func applicationWillResignActive(_ application: UIApplication) {
    ///     screenProtectorKit.disablePreventScreenshot()
    /// }
    /// ```
    public func disablePreventScreenshot() {
        setSecureTextEntry(false)
    }
}
#endif
