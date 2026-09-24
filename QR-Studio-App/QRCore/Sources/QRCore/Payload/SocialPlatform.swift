import Foundation

public enum SocialPlatform: String, CaseIterable, Codable, Sendable, Identifiable {
    case instagram, x, facebook, tiktok, linkedin, youtube, github, threads, snapchat, bluesky

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .instagram: "Instagram"
        case .x: "X"
        case .facebook: "Facebook"
        case .tiktok: "TikTok"
        case .linkedin: "LinkedIn"
        case .youtube: "YouTube"
        case .github: "GitHub"
        case .threads: "Threads"
        case .snapchat: "Snapchat"
        case .bluesky: "Bluesky"
        }
    }

    /// Modèle d'URL de profil ; {u} est remplacé par le nom d'utilisateur.
    var profileTemplate: String {
        switch self {
        case .instagram: "https://www.instagram.com/{u}"
        case .x: "https://x.com/{u}"
        case .facebook: "https://www.facebook.com/{u}"
        case .tiktok: "https://www.tiktok.com/@{u}"
        case .linkedin: "https://www.linkedin.com/in/{u}"
        case .youtube: "https://www.youtube.com/@{u}"
        case .github: "https://github.com/{u}"
        case .threads: "https://www.threads.com/@{u}"
        case .snapchat: "https://www.snapchat.com/add/{u}"
        case .bluesky: "https://bsky.app/profile/{u}"
        }
    }
}
