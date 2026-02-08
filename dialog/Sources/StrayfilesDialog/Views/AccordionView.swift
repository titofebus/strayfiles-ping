import SwiftUI

/// Collapsible sections multi-question dialog (accordion mode).
/// All questions visible, auto-advances on selection.
/// Tab/Shift+Tab to expand sections.
struct AccordionView: View {
  let questions: [Question]
  let onComplete: ([String: String], Int) -> Void

  @State private var expandedIndex: Int = 0
  @State private var answers: [String: String] = [:]

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      ScrollView {
        VStack(alignment: .leading, spacing: 4) {
          ForEach(Array(questions.enumerated()), id: \.offset) {
            index, question in
            AccordionSection(
              question: question,
              isExpanded: index == expandedIndex,
              answer: answers[question.id],
              onTap: { expandedIndex = index },
              onAnswer: { value in
                answers[question.id] = value
                // Auto-advance to next unanswered
                if index < questions.count - 1 {
                  expandedIndex = index + 1
                }
              }
            )
          }
        }
      }

      HStack {
        let answeredCount = answers.count
        Text("\(answeredCount)/\(questions.count) answered")
          .font(.caption)
          .foregroundStyle(.secondary)

        Spacer()

        Button("Done") {
          onComplete(answers, answers.count)
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.defaultAction)
        .disabled(answers.isEmpty)
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Question accordion")
  }
}

/// A single collapsible section in the accordion.
struct AccordionSection: View {
  let question: Question
  let isExpanded: Bool
  let answer: String?
  let onTap: () -> Void
  let onAnswer: (String) -> Void

  @State private var textInput = ""
  @State private var selectedOptions: Set<String> = []
  @State private var didInitialize = false

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Header (always visible)
      Button(action: onTap) {
        HStack {
          Image(
            systemName: isExpanded ? "chevron.down" : "chevron.right"
          )
          .font(.caption)
          .foregroundStyle(.secondary)

          Text(question.label)
            .font(.callout)
            .fontWeight(isExpanded ? .medium : .regular)

          Spacer()

          if let answer, !answer.isEmpty {
            Text(answer)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        .padding(.vertical, 4)
      }
      .buttonStyle(.plain)

      // Expanded content
      if isExpanded {
        sectionContent
          .padding(.leading, 20)
          .onAppear {
            guard !didInitialize else { return }
            didInitialize = true
            textInput = answer ?? ""
          }
      }
    }
    .padding(.horizontal, 8)
    .background(
      RoundedRectangle(cornerRadius: 4)
        .fill(isExpanded ? Color.accentColor.opacity(0.05) : .clear)
    )
    .accessibilityElement(children: .contain)
    .accessibilityLabel(question.label)
  }

  /// Renders the input content for the expanded section.
  @ViewBuilder
  private var sectionContent: some View {
    switch question.type {
    case .text:
      TextField("Your answer...", text: $textInput)
        .textFieldStyle(.roundedBorder)
        .onSubmit {
          guard !textInput.isEmpty else { return }
          onAnswer(textInput)
        }

    case .secureText:
      SecureField("Your answer...", text: $textInput)
        .textFieldStyle(.roundedBorder)
        .onSubmit {
          guard !textInput.isEmpty else { return }
          onAnswer(textInput)
        }

    case .confirmation:
      HStack(spacing: 8) {
        Button("No") { onAnswer("no") }
          .buttonStyle(.bordered)
        Button("Yes") { onAnswer("yes") }
          .buttonStyle(.bordered)
      }

    case .choice:
      if let options = question.options {
        if question.isMultiSelect {
          ForEach(options, id: \.self) { option in
            Toggle(option, isOn: Binding(
              get: { selectedOptions.contains(option) },
              set: { isOn in
                if isOn { selectedOptions.insert(option) }
                else { selectedOptions.remove(option) }
                let sorted = options.filter { selectedOptions.contains($0) }
                onAnswer(sorted.joined(separator: "\n"))
              }
            ))
          }
        } else {
          ForEach(Array(options.enumerated()), id: \.offset) { _, option in
            Button(action: { onAnswer(option) }) {
              HStack {
                Text(option)
                Spacer()
                if answer == option {
                  Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                }
              }
              .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
          }
        }
      }

    default:
      TextField("Your answer...", text: $textInput)
        .textFieldStyle(.roundedBorder)
        .onSubmit {
          guard !textInput.isEmpty else { return }
          onAnswer(textInput)
        }
    }
  }
}
