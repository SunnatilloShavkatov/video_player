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
    
    private var window: UIWindow?
    private var screenPrevent = UITextField()
    private var screenshotObserve: NSObjectProtocol?
    private var screenRecordObserve: NSObjectProtocol?
    
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
        guard let w = window else { return }
        
        if !w.subviews.contains(screenPrevent) {
            w.addSubview(screenPrevent)
            screenPrevent.centerYAnchor.constraint(equalTo: w.centerYAnchor).isActive = true
            screenPrevent.centerXAnchor.constraint(equalTo: w.centerXAnchor).isActive = true
            w.layer.superlayer?.addSublayer(screenPrevent.layer)
            if #available(iOS 17.0, *) {
                screenPrevent.layer.sublayers?.last?.addSublayer(w.layer)
            } else {
                screenPrevent.layer.sublayers?.first?.addSublayer(w.layer)
            }
        }
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
        screenPrevent.isSecureTextEntry = true
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
        screenPrevent.isSecureTextEntry = false
    }
    
    /// Remove a specific observer
    /// - Parameter observer: The observer to remove
    public func removeObserver(observer: NSObjectProtocol?) {
        guard let obs = observer else { return }
        NotificationCenter.default.removeObserver(obs)
    }
    
    /// Remove screenshot observer
    public func removeScreenshotObserver() {
        if let screenshotObserve = screenshotObserve {
            removeObserver(observer: screenshotObserve)
            self.screenshotObserve = nil
        }
    }
    
    /// Remove screen recording observer
    public func removeScreenRecordObserver() {
        if let screenRecordObserve = screenRecordObserve {
            removeObserver(observer: screenRecordObserve)
            self.screenRecordObserve = nil
        }
    }
    
    /// Remove all observers
    public func removeAllObserver() {
        removeScreenshotObserver()
        removeScreenRecordObserver()
    }
    
    /// Add observer for screenshot events
    /// - Parameter onScreenshot: Callback executed when a screenshot is taken
    ///
    /// How to use:
    /// ```swift
    /// screenProtectorKit.screenshotObserver {
    ///     // Handle screenshot event
    ///     print("Screenshot detected!")
    /// }
    /// ```
    public func screenshotObserver(using onScreenshot: @escaping () -> Void) {
        screenshotObserve = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: OperationQueue.main
        ) { _ in
            onScreenshot()
        }
    }
    
    /// Add observer for screen recording events
    /// - Parameter onScreenRecord: Callback executed when screen recording state changes
    ///
    /// How to use:
    /// ```swift
    /// if #available(iOS 11.0, *) {
    ///     screenProtectorKit.screenRecordObserver { isCaptured in
    ///         // Handle screen recording event
    ///         print("Screen recording: \(isCaptured)")
    ///     }
    /// }
    /// ```
    @available(iOS 11.0, *)
    public func screenRecordObserver(using onScreenRecord: @escaping (Bool) -> Void) {
        screenRecordObserve = NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: OperationQueue.main
        ) { _ in
            let isCaptured = UIScreen.main.isCaptured
            onScreenRecord(isCaptured)
        }
    }
    
    /// Check if screen is currently being recorded
    /// - Returns: true if screen recording is active, false otherwise
    @available(iOS 11.0, *)
    public func screenIsRecording() -> Bool {
        return UIScreen.main.isCaptured
    }
}