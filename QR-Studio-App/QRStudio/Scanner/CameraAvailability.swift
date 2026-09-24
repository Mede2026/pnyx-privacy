import AVFoundation
import PhotosUI
import QRCore
import SwiftUI
import VisionKit

enum CameraAvailability {
    case checking, visionKit, avFallback, denied, unavailable

    var isLive: Bool { self == .visionKit || self == .avFallback }
}
