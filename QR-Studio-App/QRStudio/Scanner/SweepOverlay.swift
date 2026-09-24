import QRCore
import SwiftUI

/// Faisceau qui balaie le code détecté, puis cadre vert de confirmation.
/// La vue reste toujours dans la hiérarchie pour que KeyframeAnimator voie changer son déclencheur.
struct SweepOverlay: View {
    let sweep: Sweep?
    let succeeded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if reduceMotion {
                // Animations réduites : simple fondu du cadre, sans faisceau.
                if let sweep {
                    QuadFrame(quad: sweep.quad, opacity: 1, succeeded: succeeded)
                        .transition(.opacity)
                }
            } else {
                KeyframeAnimator(initialValue: SweepValues(), trigger: sweep?.id) { values in
                    if let sweep {
                        ZStack {
                            QuadFrame(quad: sweep.quad, opacity: values.frameOpacity, succeeded: succeeded)
                            SweepBar(quad: sweep.quad, progress: values.progress)
                                .opacity(values.barOpacity)
                        }
                    }
                } keyframes: { _ in
                    // Vitesse en trois temps : élan, lecture, sortie (600 ms au total).
                    KeyframeTrack(\.progress) {
                        LinearKeyframe(0, duration: 0)
                        LinearKeyframe(0.15, duration: 0.12, timingCurve: .easeOut)
                        LinearKeyframe(0.85, duration: 0.38, timingCurve: .easeInOut)
                        LinearKeyframe(1, duration: 0.10, timingCurve: .easeIn)
                    }
                    // Le cadre pulse légèrement pendant le balayage, de 0,6 à 1.
                    KeyframeTrack(\.frameOpacity) {
                        LinearKeyframe(0.6, duration: 0)
                        LinearKeyframe(1, duration: 0.15)
                        LinearKeyframe(0.6, duration: 0.15)
                        LinearKeyframe(1, duration: 0.15)
                        LinearKeyframe(0.8, duration: 0.15)
                        LinearKeyframe(1, duration: 0.05)
                    }
                    KeyframeTrack(\.barOpacity) {
                        LinearKeyframe(1, duration: 0.52)
                        LinearKeyframe(0, duration: 0.08)
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.15), value: succeeded)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
