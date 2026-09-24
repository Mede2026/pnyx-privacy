import QRCore
import SwiftUI

/// Rangée de boutons illustrés pour choisir une forme.
struct ShapeChooser<Option: Hashable>: View {
    @Binding var selection: Option
    let options: [Option]
    let describe: (Option) -> (symbol: String, title: LocalizedStringKey)

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    let description = describe(option)
                    Button {
                        selection = option
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: description.symbol)
                                .font(.title2)
                                .frame(width: 56, height: 44)
                            Text(description.title)
                                .font(.caption)
                        }
                        .padding(8)
                        .background(selection == option ? Color.accentColor.opacity(0.18) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(selection == option ? Color.accentColor : Color.clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == option ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
    }
}
