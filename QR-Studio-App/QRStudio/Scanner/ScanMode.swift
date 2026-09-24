import CoreLocation
import Foundation
import Observation
import QRCore
import SwiftUI

enum ScanMode: String, CaseIterable, Identifiable {
    case single
    case batch
    var id: String { rawValue }
}
