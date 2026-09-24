import Foundation
import SwiftData

/// Prédicat de l'historique, construit avec PredicateExpressions, une sous-expression par ligne.
/// Au-delà de six conditions, le compilateur n'arrive plus à vérifier les types d'un #Predicate ;
/// cette forme explicite compile vite et se traduit toujours en requête SQL (rien n'est filtré en Swift).
public enum HistoryPredicate {
    private typealias E = PredicateExpressions

    public struct Criteria: Sendable {
        public var inTrash = false
        public var origins: [String]
        public var contentTypes: [String]
        public var symbologies: [String]
        public var favoritesOnly = false
        public var from = Date.distantPast
        public var to = Date.distantFuture
        /// nil = pas de recherche.
        public var text: String?
        /// nil = tous les dossiers.
        public var folderID: UUID?

        public init(origins: [String], contentTypes: [String], symbologies: [String]) {
            self.origins = origins
            self.contentTypes = contentTypes
            self.symbologies = symbologies
        }
    }

    public static func make(_ c: Criteria) -> Predicate<CodeEntry> {
        let trash = c.inTrash
        let origins = c.origins
        let types = c.contentTypes
        let symbologies = c.symbologies
        let favorites = c.favoritesOnly ? [true] : [true, false]
        let from = c.from
        let to = c.to
        let anyText = c.text == nil
        let text = c.text ?? ""
        let anyFolder = c.folderID == nil
        let folder = c.folderID

        return Predicate<CodeEntry> { entry in
            let deleted = E.build_NotEqual(lhs: E.build_KeyPath(root: entry, keyPath: \CodeEntry.deletedAt),
                                           rhs: E.build_NilLiteral() as E.NilLiteral<Date>)
            let trashOK = E.build_Equal(lhs: deleted, rhs: E.build_Arg(trash))
            let createdAt = E.build_KeyPath(root: entry, keyPath: \CodeEntry.createdAt)
            let fromOK = E.build_Comparison(lhs: createdAt, rhs: E.build_Arg(from), op: .greaterThanOrEqual)
            let toOK = E.build_Comparison(lhs: createdAt, rhs: E.build_Arg(to), op: .lessThan)
            let originOK = E.build_contains(E.build_Arg(origins), E.build_KeyPath(root: entry, keyPath: \CodeEntry.origin))
            let typeOK = E.build_contains(E.build_Arg(types), E.build_KeyPath(root: entry, keyPath: \CodeEntry.contentType))
            let symbologyOK = E.build_contains(E.build_Arg(symbologies),
                                               E.build_KeyPath(root: entry, keyPath: \CodeEntry.symbology))
            let favoriteOK = E.build_contains(E.build_Arg(favorites), E.build_KeyPath(root: entry, keyPath: \CodeEntry.isFavorite))

            // Recherche dans le contenu, la note et le libellé.
            let rawMatch = E.build_localizedStandardContains(E.build_KeyPath(root: entry, keyPath: \CodeEntry.rawValue),
                                                             E.build_Arg(text))
            let noteMatch = E.build_localizedStandardContains(E.build_KeyPath(root: entry, keyPath: \CodeEntry.note),
                                                              E.build_Arg(text))
            let labelMatch = E.build_localizedStandardContains(E.build_KeyPath(root: entry, keyPath: \CodeEntry.label),
                                                               E.build_Arg(text))
            let anyMatch = E.build_Disjunction(lhs: rawMatch, rhs: E.build_Disjunction(lhs: noteMatch, rhs: labelMatch))
            let textOK = E.build_Disjunction(lhs: E.build_Arg(anyText), rhs: anyMatch)

            let folderID = E.build_flatMap(E.build_KeyPath(root: entry, keyPath: \CodeEntry.folder)) { folder in
                E.build_KeyPath(root: folder, keyPath: \Folder.id)
            }
            let folderOK = E.build_Disjunction(lhs: E.build_Arg(anyFolder),
                                               rhs: E.build_Equal(lhs: folderID, rhs: E.build_Arg(folder)))

            let dates = E.build_Conjunction(lhs: fromOK, rhs: toOK)
            let kinds = E.build_Conjunction(lhs: E.build_Conjunction(lhs: originOK, rhs: typeOK),
                                            rhs: E.build_Conjunction(lhs: symbologyOK, rhs: favoriteOK))
            let base = E.build_Conjunction(lhs: E.build_Conjunction(lhs: trashOK, rhs: dates), rhs: kinds)
            return E.build_Conjunction(lhs: base, rhs: E.build_Conjunction(lhs: textOK, rhs: folderOK))
        }
    }
}
