import SwiftUI

/// Checkbox-style multi-select list.
/// Up/Down to navigate, Space to toggle, Enter to submit.
struct MultiSelectView: View {
  let options: [String]
  let onSubmit: ([String]) -> Void

  @State private var selectedIndices: Set<Int> = []
  @State private var focusedIndex: Int = 0

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(options.enumerated()), id: \.offset) {
              index, option in
              CheckboxRow(
                label: option,
                isChecked: selectedIndices.contains(index),
                isFocused: index == focusedIndex
              ) {
                toggleSelection(index)
              }
              .id(index)
            }
          }
        }
        .onChange(of: focusedIndex) { _, newValue in
          withAnimation(nil) {
            proxy.scrollTo(newValue, anchor: .center)
          }
        }
      }

      HStack {
        Text("\(selectedIndices.count) selected")
          .font(.caption)
          .foregroundStyle(.secondary)

        Spacer()

        Button("Submit") {
          submit()
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.defaultAction)
        .disabled(selectedIndices.isEmpty)
      }
    }
    .onKeyPress(.upArrow) {
      guard !options.isEmpty else { return .ignored }
      focusedIndex = max(0, focusedIndex - 1)
      return .handled
    }
    .onKeyPress(.downArrow) {
      guard !options.isEmpty else { return .ignored }
      focusedIndex = min(options.count - 1, focusedIndex + 1)
      return .handled
    }
    .onKeyPress(.space) {
      guard focusedIndex < options.count else { return .ignored }
      toggleSelection(focusedIndex)
      return .handled
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Multi-select list")
  }

  /// Toggles selection for the given index.
  /// @param index The option index to toggle
  private func toggleSelection(_ index: Int) {
    if selectedIndices.contains(index) {
      selectedIndices.remove(index)
    } else {
      selectedIndices.insert(index)
    }
  }

  /// Submits the selected options.
  private func submit() {
    let selected = selectedIndices.sorted().compactMap { index in
      index < options.count ? options[index] : nil
    }
    onSubmit(selected)
  }
}

/// A single row with a checkbox indicator.
struct CheckboxRow: View {
  let label: String
  let isChecked: Bool
  let isFocused: Bool
  let action: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: isChecked ? "checkmark.square.fill" : "square")
        .foregroundColor(isChecked ? .accentColor : .secondary)

      Text(label)
        .font(.body)

      Spacer()
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .background(
      RoundedRectangle(cornerRadius: 4)
        .fill(isFocused ? Color.accentColor.opacity(0.1) : .clear)
    )
    .contentShape(Rectangle())
    .onTapGesture { action() }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(label)
    .accessibilityAddTraits([.isButton])
    .accessibilityAddTraits(isChecked ? .isSelected : [])
    .accessibilityHint("Double-tap to toggle")
  }
}
