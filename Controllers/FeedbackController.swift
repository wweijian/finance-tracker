import Combine

@MainActor
final class FeedbackController: ObservableObject {
    @Published var isPresented = false
    @Published var notes = ""
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasLoaded = false

    private let repository: any FeedbackRepository

    var canSave: Bool { hasLoaded && !isLoading && !isSaving }

    init(repository: any FeedbackRepository) {
        self.repository = repository
    }

    func present() async {
        guard !isPresented, !isLoading, !isSaving else { return }
        isPresented = true
        await load()
    }

    func load() async {
        guard !isLoading, !isSaving else { return }
        isLoading = true
        hasLoaded = false
        errorMessage = nil
        do {
            notes = try await repository.load()
            hasLoaded = true
        } catch {
            errorMessage = "Could not load your feedback: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func save() async {
        guard canSave else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await repository.save(notes)
            isPresented = false
        } catch {
            errorMessage = "Could not save your feedback: \(error.localizedDescription)"
        }
        isSaving = false
    }

    func cancel() {
        guard !isLoading, !isSaving else { return }
        isPresented = false
    }
}
