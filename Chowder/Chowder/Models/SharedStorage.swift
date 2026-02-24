import UIKit

/// Provides access to shared storage for the agent avatar.
/// NOTE: App Groups are not yet registered in Apple Dev portal.
/// Using local app support directory until group.com.clmtek.shellybot is registered.
enum SharedStorage {
    static let appGroupIdentifier = "group.com.clmtek.shellybot"

    private static var containerURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }

    private static var avatarURL: URL? {
        containerURL?.appendingPathComponent("agent_avatar.jpg")
    }

    static func saveAvatar(_ image: UIImage) {
        guard let url = avatarURL,
              let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func loadAvatarImage() -> UIImage? {
        guard let url = avatarURL,
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    static func deleteAvatar() {
        guard let url = avatarURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
