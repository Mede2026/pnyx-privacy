#if DEBUG
import Darwin
import Foundation
import OSLog

/// Mesure de développement : temps entre le démarrage du processus et le premier écran affiché.
/// La mesure officielle du budget (moins de 400 ms) se fait dans Instruments, modèle App Launch, sur appareil.
enum LaunchTimer {
    private static var logged = false

    /// Jalon intermédiaire (millisecondes depuis le démarrage du processus).
    static func mark(_ label: StaticString) {
        guard let start = processStart() else { return }
        Logger.general.notice("Lancement, \(label) : \(Int(Date.now.timeIntervalSince(start) * 1000)) ms")
    }

    @MainActor
    static func firstScreenAppeared() {
        guard !logged, let start = processStart() else { return }
        logged = true
        let milliseconds = Date.now.timeIntervalSince(start) * 1000
        Logger.general.notice("Premier écran après \(Int(milliseconds)) ms")
    }

    private static func processStart() -> Date? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0 else { return nil }
        let time = info.kp_proc.p_un.__p_starttime
        return Date(timeIntervalSince1970: Double(time.tv_sec) + Double(time.tv_usec) / 1_000_000)
    }
}
#endif
