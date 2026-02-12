// SPDX-License-Identifier: MIT
import SwiftUI

/// Step-by-step multi-question dialog (wizard mode).
/// Left/Right to navigate steps, Up/Down for options within steps.
/// Also used as the entry point for accordion mode.
struct WizardView: View {
  let questions: [Question]
  let mode: QuestionMode
  let onComplete: ([String: String], Int) -> Void

  @State private var currentStep = 0
  @State private var answers: [String: String] = [:]
  @State private var multiSelectSets: [String: Set<String>] = [:]
  @Environment(\.dialogAccent) private var accent
  @State private var currentText = ""

  var body: some View {
    if mode == .accordion {
      AccordionView(
        questions: questions,
        onComplete: onComplete
      )
    } else {
      wizardContent
    }
  }

  private var wizardContent: some View {
    VStack(alignment: .leading, spacing: 10) {
      // Progress indicator
      HStack(spacing: 4) {
        ForEach(0..<questions.count, id: \.self) { index in
          Circle()
            .fill(
              index == currentStep
                ? accent
                : index < currentStep
                  ? accent.opacity(0.5) : Color.secondary.opacity(0.3)
            )
            .frame(width: 6, height: 6)
        }
        Spacer()
        Text("\(currentStep + 1)/\(questions.count)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      if currentStep < questions.count {
        let question = questions[currentStep]

        // Question label
        Text(question.label)
          .font(.callout)
          .fontWeight(.medium)

        // Question input
        questionInput(for: question)
      }

      // Navigation buttons
      HStack {
        if currentStep > 0 {
          Button("Back") {
            currentStep -= 1
            loadAnswer()
          }
          .buttonStyle(.bordered)
        }

        Spacer()

        if currentStep < questions.count - 1 {
          Button("Next") {
            saveAnswer()
            currentStep += 1
            loadAnswer()
          }
          .buttonStyle(.borderedProminent)
          .keyboardShortcut(.defaultAction)
        } else {
          Button("Done") {
            saveAnswer()
            onComplete(answers, answers.count)
          }
          .buttonStyle(.borderedProminent)
          .keyboardShortcut(.defaultAction)
        }
      }
    }
    .onKeyPress(.leftArrow) {
      // Don't consume arrow keys in text/secureText fields
      guard currentStep < questions.count else { return .ignored }
      let questionType = questions[currentStep].type
      guard questionType != .text && questionType != .secureText else {
        return .ignored
      }
      if currentStep > 0 {
        currentStep -= 1
        loadAnswer()
      }
      return .handled
    }
    .onKeyPress(.rightArrow) {
      guard currentStep < questions.count else { return .ignored }
      let questionType = questions[currentStep].type
      guard questionType != .text && questionType != .secureText else {
        return .ignored
      }
      if currentStep < questions.count - 1 {
        saveAnswer()
        currentStep += 1
        loadAnswer()
      }
      return .handled
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Question wizard")
  }

  /// Renders the appropriate input for a question type.
  /// @param question The question to render
  @ViewBuilder
  private func questionInput(for question: Question) -> some View {
    switch question.type {
    case .text:
      TextField("Your answer...", text: $currentText)
        .textFieldStyle(.roundedBorder)

    case .secureText:
      SecureField("Your answer...", text: $currentText)
        .textFieldStyle(.roundedBorder)

    case .confirmation:
      HStack(spacing: 8) {
        Button("No") { setAnswer("no") }
          .buttonStyle(.bordered)
        Button("Yes") { setAnswer("yes") }
          .buttonStyle(.bordered)
      }

    case .choice:
      if let options = question.options {
        if question.isMultiSelect {
          ForEach(options, id: \.self) { option in
            Toggle(option, isOn: Binding(
              get: {
                multiSelectSets[question.id]?.contains(option) ?? false
              },
              set: { isOn in
                var current = multiSelectSets[question.id] ?? []
                if isOn { current.insert(option) }
                else { current.remove(option) }
                multiSelectSets[question.id] = current
                // Sync to answers as JSON array for output
                let sorted = options.filter { current.contains($0) }
                answers[question.id] = sorted.joined(separator: "\n")
              }
            ))
          }
        } else {
          ForEach(Array(options.enumerated()), id: \.offset) {
            _, option in
            Button(action: { setAnswer(option) }) {
              HStack {
                Text(option)
                Spacer()
                if answers[question.id] == option {
                  Image(systemName: "checkmark")
                    .foregroundColor(accent)
                }
              }
              .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
          }
        }
      }

    default:
      TextField("Your answer...", text: $currentText)
        .textFieldStyle(.roundedBorder)
    }
  }

  /// Sets an answer for the current question and auto-advances.
  /// @param value The answer value
  private func setAnswer(_ value: String) {
    let question = questions[currentStep]
    answers[question.id] = value
    currentText = value
  }

  /// Saves the current text input as the answer.
  private func saveAnswer() {
    guard currentStep < questions.count else { return }
    let question = questions[currentStep]
    if !currentText.isEmpty {
      answers[question.id] = currentText
    }
  }

  /// Loads the saved answer for the current step.
  private func loadAnswer() {
    guard currentStep < questions.count else { return }
    let question = questions[currentStep]
    currentText = answers[question.id] ?? ""
  }
}
