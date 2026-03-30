import SwiftUI

struct CustomPackEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let existingPack: QuestionPack?
    let onSave: (QuestionPack) -> Void
    let onDelete: ((String) -> Void)?

    @State private var draft: CustomPackDraft
    @State private var questionEditorDraft: CustomQuestionDraft?
    @State private var isShowingDeleteConfirmation = false

    init(
        existingPack: QuestionPack? = nil,
        onSave: @escaping (QuestionPack) -> Void,
        onDelete: ((String) -> Void)? = nil
    ) {
        self.existingPack = existingPack
        self.onSave = onSave
        self.onDelete = onDelete
        _draft = State(initialValue: CustomPackDraft(pack: existingPack))
    }

    var body: some View {
        NavigationStack {
            Form {
                packDetailsSection
                questionsSection

                if let validationMessage = draft.validationMessage {
                    validationSection(message: validationMessage)
                }
            }
            .navigationTitle(existingPack == nil ? "New Pack" : "Edit Pack")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard let pack = draft.buildPack() else {
                            return
                        }

                        onSave(pack)
                        dismiss()
                    }
                    .disabled(!draft.canSave)
                }

                if existingPack != nil, let onDelete {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete Pack", role: .destructive) {
                            isShowingDeleteConfirmation = true
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .sheet(item: $questionEditorDraft) { questionDraft in
                CustomQuestionEditorView(draft: questionDraft) { savedQuestion in
                    draft.saveQuestion(savedQuestion)
                }
            }
            .confirmationDialog(
                "Delete this local pack?",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                if let existingPack, let onDelete {
                    Button("Delete Pack", role: .destructive) {
                        onDelete(existingPack.id)
                        dismiss()
                    }
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes the pack from this phone. It will no longer appear in New Game.")
            }
        }
    }

    private var packDetailsSection: some View {
        Section {
            TextField("Pack title", text: $draft.title)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            TextField("Category", text: $draft.category)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            TextField("Summary (optional)", text: $draft.summary, axis: .vertical)
                .lineLimit(2...4)
                .textInputAutocapitalization(.sentences)
        } header: {
            Text("Pack Details")
        } footer: {
            Text("Custom packs stay local to this phone. Right now each custom pack uses one shared category.")
        }
    }

    private var questionsSection: some View {
        Section {
            if draft.questions.isEmpty {
                Text("No questions yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(draft.questions) { question in
                    questionRow(question)
                }
            }

            Button {
                questionEditorDraft = CustomQuestionDraft()
            } label: {
                Label("Add Question", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Questions")
        } footer: {
            Text("Each question needs exactly 10 unique answers. Saved packs become playable immediately in New Game.")
        }
    }

    private func questionRow(_ question: CustomQuestionDraft) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                questionEditorDraft = question
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(question.promptDisplayTitle)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Text(question.statusLine)
                        .font(.caption)
                        .foregroundStyle(question.isValid ? Color.secondary : Color.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                draft.deleteQuestion(id: question.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete question")
        }
        .padding(.vertical, 4)
    }

    private func validationSection(message: String) -> some View {
        Section {
            Text(message)
                .foregroundStyle(.red)
                .font(.footnote)
        }
    }
}

private struct CustomQuestionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CustomQuestionDraft

    let onSave: (CustomQuestionDraft) -> Void

    init(
        draft: CustomQuestionDraft,
        onSave: @escaping (CustomQuestionDraft) -> Void
    ) {
        self.onSave = onSave
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextField("Prompt", text: $draft.prompt, axis: .vertical)
                        .lineLimit(2...5)

                    Picker("Style", selection: $draft.validationStyle) {
                        ForEach(ValidationStyle.allCases, id: \.self) { style in
                            Text(style.displayName)
                                .tag(style)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("Notes for your group (optional)", text: $draft.notes, axis: .vertical)
                        .lineLimit(2...4)
                        .textInputAutocapitalization(.sentences)
                }

                Section {
                    ForEach(Array(draft.answers.indices), id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField(
                                "Answer \(index + 1)",
                                text: answerBinding(at: index).text
                            )
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()

                            Stepper(
                                "Points: \(draft.answers[index].points)",
                                value: answerBinding(at: index).points,
                                in: 1...5
                            )
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Answers")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total points: \(draft.totalPoints)")
                        Text(draft.difficultyLabel)
                    }
                }

                if let validationMessage = draft.validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(draft.persistedQuestionID == nil ? "New Question" : "Edit Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(!draft.isValid)
                }
            }
        }
    }

    private func answerBinding(at index: Int) -> Binding<CustomAnswerDraft> {
        Binding(
            get: { draft.answers[index] },
            set: { draft.answers[index] = $0 }
        )
    }
}

private struct CustomPackDraft {
    var persistedPackID: String?
    var title: String
    var category: String
    var summary: String
    var questions: [CustomQuestionDraft]

    init(pack: QuestionPack? = nil) {
        persistedPackID = pack?.id
        title = pack?.title ?? ""
        category = pack?.questions.first?.category ?? ""
        summary = pack?.summary ?? ""
        questions = pack?.questions.map { CustomQuestionDraft(question: $0) } ?? []
    }

    var canSave: Bool {
        validationMessage == nil
    }

    var validationMessage: String? {
        if title.trimmedForCustomPacks.isEmpty {
            return "Add a pack title."
        }

        if category.trimmedForCustomPacks.isEmpty {
            return "Add a category for this pack."
        }

        if questions.isEmpty {
            return "Add at least one question."
        }

        if let invalidQuestionIndex = questions.firstIndex(where: { !$0.isValid }) {
            return "Question \(invalidQuestionIndex + 1) still needs finishing."
        }

        return nil
    }

    mutating func saveQuestion(_ question: CustomQuestionDraft) {
        if let existingIndex = questions.firstIndex(where: { $0.id == question.id }) {
            questions[existingIndex] = question
        } else {
            questions.append(question)
        }
    }

    mutating func deleteQuestion(id: UUID) {
        questions.removeAll { $0.id == id }
    }

    func buildPack() -> QuestionPack? {
        guard validationMessage == nil else {
            return nil
        }

        let normalizedCategory = category.trimmedForCustomPacks
        let builtQuestions = questions.compactMap { $0.buildQuestion(category: normalizedCategory) }
        guard builtQuestions.count == questions.count else {
            return nil
        }

        return QuestionPack(
            id: persistedPackID ?? "local-pack-\(UUID().uuidString.lowercased())",
            title: title.trimmedForCustomPacks,
            summary: summary.trimmedForCustomPacks.nilIfEmpty,
            languageCode: "en",
            questions: builtQuestions,
            packVersion: "local-v1",
            monetization: nil,
            origin: .customLocal
        )
    }
}

private struct CustomQuestionDraft: Identifiable, Equatable {
    let id: UUID
    var persistedQuestionID: String?
    var prompt: String
    var validationStyle: ValidationStyle
    var notes: String
    var answers: [CustomAnswerDraft]

    init(
        id: UUID = UUID(),
        persistedQuestionID: String? = nil,
        prompt: String = "",
        validationStyle: ValidationStyle = .editorial,
        notes: String = "",
        answers: [CustomAnswerDraft] = CustomAnswerDraft.defaultAnswers
    ) {
        self.id = id
        self.persistedQuestionID = persistedQuestionID
        self.prompt = prompt
        self.validationStyle = validationStyle
        self.notes = notes
        self.answers = answers
    }

    init(question: Question) {
        self.init(
            persistedQuestionID: question.id,
            prompt: question.prompt,
            validationStyle: question.validationStyle,
            notes: question.editorialNotes ?? "",
            answers: question.answers.map {
                CustomAnswerDraft(text: $0.text, points: $0.points)
            }
        )
    }

    var totalPoints: Int {
        answers.reduce(0) { $0 + $1.points }
    }

    var detectedDifficulty: QuestionDifficulty? {
        QuestionDifficulty.tier(forScore: totalPoints)
    }

    var isValid: Bool {
        validationMessage == nil
    }

    var validationMessage: String? {
        if prompt.trimmedForCustomPacks.isEmpty {
            return "Add a question prompt."
        }

        if answers.count != 10 {
            return "Each question needs exactly 10 answers."
        }

        if let emptyAnswerIndex = answers.firstIndex(where: { $0.text.trimmedForCustomPacks.isEmpty }) {
            return "Answer \(emptyAnswerIndex + 1) needs text."
        }

        let uniqueAnswerCount = Set(answers.map { $0.text.trimmedForCustomPacks.lowercased() }).count
        if uniqueAnswerCount != answers.count {
            return "Answers must be unique."
        }

        if detectedDifficulty == nil {
            return "Total points must land in an easy, medium, or hard band."
        }

        return nil
    }

    var promptDisplayTitle: String {
        let trimmedPrompt = prompt.trimmedForCustomPacks
        return trimmedPrompt.isEmpty ? "Untitled question" : trimmedPrompt
    }

    var difficultyLabel: String {
        if let detectedDifficulty {
            return "Detected difficulty: \(detectedDifficulty.rawValue.capitalized)"
        }

        return "Detected difficulty: Invalid score range"
    }

    var statusLine: String {
        if isValid {
            return "\(answers.count) answers • \(difficultyLabel)"
        }

        return validationMessage ?? "Needs work"
    }

    func buildQuestion(category: String) -> Question? {
        guard validationMessage == nil,
              let detectedDifficulty else {
            return nil
        }

        let questionID = persistedQuestionID ?? "local-question-\(UUID().uuidString.lowercased())"

        return Question(
            id: questionID,
            category: category,
            prompt: prompt.trimmedForCustomPacks,
            difficultyTier: detectedDifficulty,
            difficultyScore: totalPoints,
            validationStyle: validationStyle,
            sourceURL: LocalQuestionPackStore.placeholderSourceURL(forQuestionID: questionID),
            answers: answers.map {
                AnswerOption(
                    text: $0.text.trimmedForCustomPacks,
                    points: $0.points
                )
            },
            quality: "custom",
            editorialNotes: notes.trimmedForCustomPacks.nilIfEmpty
        )
    }
}

private struct CustomAnswerDraft: Equatable {
    var text: String
    var points: Int

    static let defaultAnswers: [CustomAnswerDraft] = [
        CustomAnswerDraft(text: "", points: 1),
        CustomAnswerDraft(text: "", points: 1),
        CustomAnswerDraft(text: "", points: 1),
        CustomAnswerDraft(text: "", points: 1),
        CustomAnswerDraft(text: "", points: 1),
        CustomAnswerDraft(text: "", points: 1),
        CustomAnswerDraft(text: "", points: 1),
        CustomAnswerDraft(text: "", points: 1),
        CustomAnswerDraft(text: "", points: 2),
        CustomAnswerDraft(text: "", points: 2)
    ]
}

private extension ValidationStyle {
    var displayName: String {
        rawValue.capitalized
    }
}

private extension String {
    var trimmedForCustomPacks: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nilIfEmpty: String? {
        let trimmedValue = trimmedForCustomPacks
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
