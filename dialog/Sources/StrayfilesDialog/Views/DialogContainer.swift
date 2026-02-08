import SwiftUI

/// Root SwiftUI view for all dialog types.
/// Provides the common chrome: timeout bar, project badge,
/// message, input view, comment field, snooze/feedback panels.
struct DialogContainer: View {
  let payload: InputPayload
  let config: DialogConfig
  let onComplete: (DialogResponse) -> Void

  @State private var showSnooze = false
  @State private var showFeedback = false
  @State private var comment = ""
  @State private var startDate = Date()
  @State private var keyboardHandler = KeyboardHandler()

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Timeout progress bar
      TimeoutBar(
        totalSeconds: payload.resolvedTimeout(
          configTimeout: config.dialog.timeout
        ),
        startDate: startDate
      )

      VStack(alignment: .leading, spacing: 10) {
        // Project badge
        ProjectBadge(
          name: payload.project,
          path: payload.projectPath
        )

        // Title (if provided)
        if let title = payload.title, !title.isEmpty {
          Text(title)
            .font(.headline)
        }

        // Message
        MarkdownText(text: payload.message)

        // Input-specific view
        inputView

        // Comment field
        CommentField(comment: $comment)

        // Snooze panel
        SnoozePanel(isVisible: $showSnooze) { minutes in
          handleSnooze(minutes: minutes)
        }

        // Feedback panel
        FeedbackPanel(isVisible: $showFeedback) { text in
          handleFeedback(text: text)
        }
      }
      .padding(12)
    }
    .frame(minWidth: 300, maxWidth: 500)
    .fixedSize(horizontal: false, vertical: true)
    .cooldownGuard(
      isEnabled: config.dialog.cooldown,
      duration: config.dialog.cooldownDuration
    )
    .accessibilityElement(children: .contain)
    .accessibilityLabel(
      AccessibilityHelper.dialogLabel(
        title: payload.title,
        message: payload.message
      )
    )
    .accessibilityHint(
      AccessibilityHelper.dialogHint(for: payload.resolvedType)
    )
    .onAppear {
      keyboardHandler.onCancel = {
        onComplete(.cancelled())
      }
      keyboardHandler.onSnoozeToggle = {
        showSnooze.toggle()
      }
      keyboardHandler.onFeedbackToggle = {
        showFeedback.toggle()
      }
      keyboardHandler.install()
    }
    .onDisappear {
      keyboardHandler.uninstall()
    }
  }

  /// The input-specific view based on the dialog type.
  @ViewBuilder
  private var inputView: some View {
    switch payload.resolvedType {
    case .notify:
      EmptyView()

    case .confirmation:
      ConfirmationView { response in
        complete(.single(response, comment: commentOrNil))
      }

    case .choice:
      ChoiceView(
        options: payload.options ?? [],
        descriptions: payload.descriptions,
        defaultSelection: payload.defaultSelection
      ) { selected in
        complete(.single(selected, comment: commentOrNil))
      }

    case .multiSelect:
      MultiSelectView(
        options: payload.options ?? []
      ) { selected in
        complete(.multiple(selected, comment: commentOrNil))
      }

    case .text:
      TextInputView(
        defaultValue: payload.defaultValue
      ) { text in
        complete(.single(text, comment: commentOrNil))
      }

    case .secureText:
      SecureInputView { text in
        complete(.single(text, comment: commentOrNil))
      }

    case .questions:
      WizardView(
        questions: payload.questions ?? [],
        mode: payload.mode ?? .wizard
      ) { answers, count in
        complete(
          .questions(answers, completedCount: count, comment: commentOrNil)
        )
      }
    }
  }

  /// Returns the comment string or nil if empty.
  private var commentOrNil: String? {
    comment.isEmpty ? nil : comment
  }

  /// Sends the response through the completion handler.
  /// @param response The dialog response
  private func complete(_ response: DialogResponse) {
    onComplete(response)
  }

  /// Handles a snooze selection.
  /// @param minutes The snooze duration
  private func handleSnooze(minutes: Int) {
    // Write snooze state to config
    let state = SnoozeState.snooze(minutes: minutes)
    if let until = state.until {
      let formatter = ISO8601DateFormatter()
      ConfigReader.write(
        key: "snooze.until",
        value: formatter.string(from: until)
      )
    }

    let response = DialogResponse.snoozed(
      minutes: minutes,
      retryAfterSeconds: minutes * 60
    )
    onComplete(response)
  }

  /// Handles feedback submission.
  /// @param text The feedback text
  private func handleFeedback(text: String) {
    let response = DialogResponse.feedbackResponse(text: text)
    onComplete(response)
  }
}
