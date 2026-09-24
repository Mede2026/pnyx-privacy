import QRCore
import SwiftUI

/// Création d'un code : type à gauche, formulaire au centre, aperçu et lisibilité à droite.
struct MacGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppServices.self) private var services
    @State private var type: ContentType = .url
    @State private var model = GeneratorFormModel(type: .url)
    @State private var readability: Readability?
    @State private var isEditingStyle = false
    @State private var isExporting = false

    var body: some View {
        let request = model.request
        let colorCheck = ReadabilityValidator.checkColors(model.style)
        HStack(spacing: 0) {
            List(ContentType.allCases, selection: Binding(get: { type }, set: { if let new = $0 { select(new) } })) { type in
                Label(type.title, systemImage: type.symbolName).tag(type)
            }
            .frame(width: 180)

            Divider()

            Form {
                Section {
                    form
                } footer: {
                    if model.hasContent, case .failure(let error) = model.payload {
                        Label(error.localizedDescription, systemImage: "exclamationmark.circle").foregroundStyle(.red)
                    }
                }
                if model.type.generatableSymbologies.count > 1 {
                    Picker("Format", selection: $model.symbology) {
                        ForEach(model.type.generatableSymbologies) { Text($0.displayName).tag($0) }
                    }
                }
                if model.symbology.supportsFullStyling {
                    Button("Personnaliser le style…") { isEditingStyle = true }
                }
                TextField("Libellé (facultatif)", text: $model.label)
            }
            .formStyle(.grouped)
            .frame(minWidth: 300)
            .onChange(of: model.productCode) { model.adjustProductSymbology() }

            Divider()

            VStack(spacing: 12) {
                CodePreview(request: request, pixelWidth: 800, debounce: .milliseconds(300))
                    .frame(width: 260, height: 260)
                    .padding(12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                    .draggable(DraggableCode(request: request ?? RenderRequest(payload: " ", symbology: .qr),
                                             name: model.label.isEmpty ? model.type.title : model.label))
                ReadabilityIndicator(readability: request == nil ? nil : readability, colorCheck: colorCheck)
                    .frame(width: 280)
                Spacer()
            }
            .padding(20)
        }
        .frame(minWidth: 820, idealWidth: 880, minHeight: 500, idealHeight: 540)
        .onAppear {
            // Texte collé depuis Édition › Coller : générateur prérempli.
            guard let prefill = services.generatorPrefill else { return }
            services.generatorPrefill = nil
            let prefilledType: ContentType = if case .url = ScannedContentParser.parse(prefill) { .url } else { .text }
            type = prefilledType
            model = GeneratorFormModel(type: prefilledType, prefill: prefill)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fermer") { dismiss() }
            }
            ToolbarItem {
                Button("Exporter…") { isExporting = true }
                    .disabled(!canUse(request, colorCheck))
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Enregistrer") { save(request) }
                    .disabled(!canUse(request, colorCheck))
            }
        }
        .task(id: request) {
            guard let request else {
                readability = nil
                return
            }
            readability = .checking
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                return
            }
            let result = await ReadabilityValidator.verify(request)
            if !Task.isCancelled { readability = result }
        }
        .sheet(isPresented: $isEditingStyle) {
            NavigationStack {
                StyleEditorView(style: $model.style, payload: request?.payload ?? "QR Studio")
            }
            .frame(minWidth: 560, minHeight: 680)
        }
        .sheet(isPresented: $isExporting) {
            if let request {
                MacExportSheet(request: request, name: model.label.isEmpty ? model.type.title : model.label)
            }
        }
        .alertHost()
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

    private func select(_ newType: ContentType) {
        type = newType
        let style = model.style
        model = GeneratorFormModel(type: newType)
        model.style = style
    }

    private func canUse(_ request: RenderRequest?, _ check: ColorCheck) -> Bool {
        guard request != nil, !check.isContrastTooLow else { return false }
        return readability?.allowsUse ?? false
    }

    private func save(_ request: RenderRequest?) {
        guard let request else { return }
        let entry = services.store.recordGenerated(
            payload: request.payload, symbology: request.symbology, contentType: model.type,
            style: request.symbology.supportsFullStyling ? model.style : nil, label: model.label
        )
        services.sidebar = .allCodes
        services.selectedEntryID = entry.id
        dismiss()
    }
}
