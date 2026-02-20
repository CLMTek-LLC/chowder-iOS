import UIKit

/// Provides access to the App Group shared container for data shared between the main app and widget extension.
enum SharedStorage {
    static let appGroupIdentifier = "group.app.chowder"

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
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
