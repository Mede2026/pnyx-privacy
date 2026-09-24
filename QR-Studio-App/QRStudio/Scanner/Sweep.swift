import CoreLocation
import Foundation
import Observation
import QRCore
import SwiftUI

/// Balayage en cours sur un code figé.
struct Sweep: Identifiable, Equatable {
    let id = UUID()
    var quad: Quad
}
