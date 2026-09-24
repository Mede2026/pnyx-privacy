import Foundation

/// Attente annulable : renvoie faux si la tâche a été annulée.
func pause(_ duration: Duration) async -> Bool {
    do {
        try await Task.sleep(for: duration)
        return true
    } catch {
        return false
    }
}
