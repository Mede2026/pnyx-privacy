import QRCore
import SwiftUI

/// Formulaire adapté au type, avec l'aperçu figé en haut pendant le défilement.
/// Le code se redessine à chaque frappe, après un anti-rebond de 300 ms.
struct GeneratorFormView: View {
    @Environment(AppServices.self) private var services
    @Environment(AppRouter.self) private var router
    @State private var model: GeneratorFormModel
    @State private var readability: Readability?
    @State private var isEditingStyle = false
    @State private var isExporting = false
    @State private var savedEntry: CodeEntry?

    init(type: ContentType, prefill: String? = nil) {
        _model = State(initialValue: GeneratorFormModel(type: type, prefill: prefill))
    }

    var body: some View {
        let request = model.request
        let colorCheck = ReadabilityValidator.checkColors(model.style)
        Form {
            Section {
                form
            } footer: {
                if model.hasContent, case .failure(let error) = model.payload {
                    Label(error.localizedDescription, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.red)
                }
            }
            if model.type.generatableSymbologies.count > 1 {
                Section("Format") {
                    Picker("Format", selection: $model.symbology) {
                        ForEach(model.type.generatableSymbologies) { symbology in
                            Text(symbology.displayName).tag(symbology)
                        }
                    }
                    if model.symbology.supportsFullStyling {
                        Button("Personnaliser le style…", systemImage: "paintbrush") { isEditingStyle = true }
                    }
                }
            }
            Section {
                TextField("Libellé (facultatif)", text: $model.label)
            }
        }
        .topBar {
            PinnedPreview(request: request, readability: readability, colorCheck: colorCheck)
        }
        .navigationTitle(model.type.title)
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Exporter", systemImage: "square.and.arrow.up") { isExporting = true }
                    .disabled(!canUse(request, colorCheck))
                Button("Enregistrer") { save(request) }
                    .disabled(!canUse(request, colorCheck))
            }
        }
        .task(id: request) {
            // Garde-fou n° 6 : relecture Vision après chaque changement, hors du fil principal.
            guard let request else {
                readability = nil
                return
            }
            readability = .checking
            guard await pause(.milliseconds(300)) else { return }
            let result = await ReadabilityValidator.verify(request)
            guard !Task.isCancelled else { return }
            readability = result
        }
        .onChange(of: model.productCode) { model.adjustProductSymbology() }
        .onAppear {
            if let prefill = router.generatorPrefill {
                router.generatorPrefill = nil
                model = GeneratorFormModel(type: model.type, prefill: prefill)
            }
        }
        .sheet(isPresented: $isEditingStyle) {
            NavigationStack {
                StyleEditorView(style: $model.style, payload: request?.payload ?? "QR Studio")
            }
        }
        .sheet(isPresented: $isExporting) {
            if let request {
                ExportSheet(request: request, suggestedName: model.label.isEmpty ? model.type.title : model.label)
            }
        }
        .sensoryFeedback(.success, trigger: savedEntry?.id)
    }

    @ViewBuilder
    private var form: some View {
        switch model.type {
        case .text: TextForm(model: model)
        case .url: URLForm(model: model)
        case .wifi: WiFiForm(model: model)
        case .wifiEnterprise: EnterpriseWiFiForm(model: model)
        case .contact: ContactForm(model: model)
        case .location: LocationForm(model: model)
        case .email: EmailForm(model: model)
        case .sms: SMSForm(model: model)
        case .phone: PhoneForm(model: model)
        case .event: EventForm(model: model)
        case .social: SocialForm(model: model)
        case .crypto: CryptoForm(model: model)
        case .product: ProductForm(model: model)
        }
    }

    /// Enregistrement et export bloqués si le contraste est insuffisant ou si le code ne se relit pas.
    private func canUse(_ request: RenderRequest?, _ check: ColorCheck) -> Bool {
        guard request != nil, !check.isContrastTooLow else { return false }
        return readability?.allowsUse ?? false
    }

    private func save(_ request: RenderRequest?) {
        guard let request else { return }
        let style: StyleConfig? = request.symbology.supportsFullStyling ? model.style : nil
        savedEntry = services.store.recordGenerated(
            payload: request.payload, symbology: request.symbology,
            contentType: model.type, style: style, label: model.label
        )
        services.alerts.show(title: String(localized: "Enregistré"),
                             detail: String(localized: "Le code est dans votre historique."))
    }
}
