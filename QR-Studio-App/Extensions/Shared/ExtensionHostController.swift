import SwiftUI
import UIKit

/// Contrôleur d'hôte commun : affiche l'interface SwiftUI et lit les éléments reçus.
class ExtensionHostController: UIViewController {
    private let model = ExtensionModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        let root = ExtensionRootView(model: model) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
        let host = UIHostingController(rootView: root)
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)

        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        Task { await model.load(items) }
    }
}
