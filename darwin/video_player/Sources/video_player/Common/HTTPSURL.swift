import Foundation

extension URL {
    /// `true` only for `https` URLs with a host. Remote playback accepts nothing else.
    var isSecureRemote: Bool {
        scheme?.lowercased() == "https" && host?.isEmpty == false
    }
}
