import Foundation

/// Masque les secrets d'un contenu avant de le confier au système (Spotlight, modèle de langage).
/// Aujourd'hui : le mot de passe d'un réseau Wi-Fi (champ P: de WIFI:…;;).
public enum SecretRedactor {
    public static func redacted(_ raw: String) -> String {
        guard raw.uppercased().hasPrefix("WIFI:") else { return raw }
        var result = ""
        var index = raw.startIndex
        while index < raw.endIndex {
            // Un champ commence au début de la chaîne après « WIFI: », ou après un « ; » non échappé.
            let fieldStart = raw[index...]
            if isFieldBoundary(raw, at: index), fieldStart.uppercased().hasPrefix("P:") {
                result += "P:•••"
                index = raw.index(index, offsetBy: 2)
                // Avance jusqu'au prochain « ; » non échappé.
                while index < raw.endIndex {
                    if raw[index] == "\\" {
                        index = raw.index(after: index)
                        if index < raw.endIndex { index = raw.index(after: index) }
                        continue
                    }
                    if raw[index] == ";" { break }
                    index = raw.index(after: index)
                }
                continue
            }
            result.append(raw[index])
            index = raw.index(after: index)
        }
        return result
    }

    private static func isFieldBoundary(_ raw: String, at index: String.Index) -> Bool {
        guard index > raw.startIndex else { return false }
        let previous = raw[raw.index(before: index)]
        guard previous == ";" || previous == ":" else { return false }
        // « WIFI: » : le « : » du préfixe compte comme séparateur, pas celui d'une valeur.
        if previous == ":" { return raw.distance(from: raw.startIndex, to: index) == 5 }
        let beforeSeparator = raw.index(before: index)
        return beforeSeparator == raw.startIndex || raw[raw.index(before: beforeSeparator)] != "\\"
    }
}
