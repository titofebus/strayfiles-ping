import SwiftUI

/// Single-select choice list with optional descriptions.
/// Up/Down to navigate (auto-scrolls to focused item),
/// Space to select, Enter to submit.
struct ChoiceView: View {
  let options: [String]
  let descriptions: [String]?
  let defaultSelection: String?
  let onSelect: (String) -> Void

  @State private var selectedIndex: Int = 0

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(options.enumerated()), id: \.offset) {
              index, option in
              OptionRow(
                label: option,
                description: descriptionFor(index),
                isSelected: index == selectedIndex,
                action: { submit(option) }
              )
              .id(index)
              .onTapGesture { selectedIndex = index }
            }
          }
        }
        .onChange(of: selectedIndex) { _, newValue in
          withAnimation(nil) {
            proxy.scrollTo(newValue, anchor: .center)
          }
        }
      }

      HStack {
        Spacer()
        Button("Select") {
          guard selectedIndex < options.count else { return }
          submit(options[selectedIndex])
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.defaultAction)
      }
    }
    .onAppear {
      if let defaultSelection,
        let index = options.firstIndex(of: defaultSelection)
      {
        selectedIndex = index
      }
    }
    .onKeyPress(.upArrow) {
      guard !options.isEmpty else { return .ignored }
      selectedIndex = max(0, selectedIndex - 1)
      return .handled
    }
    .onKeyPress(.downArrow) {
      guard !options.isEmpty else { return .ignored }
      selectedIndex = min(options.count - 1, selectedIndex + 1)
      return .handled
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Choice list")
  }

  /// Gets the description for an option at the given index.
  /// @param index The option index
  /// @returns The description string, or nil
  private func descriptionFor(_ index: Int) -> String? {
    guard let descriptions, index < descriptions.count else { return nil }
    return descriptions[index]
  }

  /// Submits the selected option.
  /// @param option The selected option label
  private func submit(_ option: String) {
    onSelect(option)
  }
}

/// A single row in the choice or multi-select list.
struct OptionRow: View {
  let label: String
  let description: String?
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(label)
          .font(.body)

        if let description, !description.isEmpty {
          Text(description)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      if isSelected {
        Image(systemName: "checkmark")
          .foregroundColor(.accentColor)
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .background(
      RoundedRectangle(cornerRadius: 4)
        .fill(isSelected ? Color.accentColor.opacity(0.1) : .clear)
    )
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
    .accessibilityLabel(label)
    .accessibilityHint(description ?? "Double-tap to select")
    .accessibilityAddTraits([.isButton])
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}
