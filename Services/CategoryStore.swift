import Foundation

final class CategoryStore {
    func categories() throws -> [String] {
        guard let url = Bundle.module.url(
            forResource: "categories",
            withExtension: "json",
            subdirectory: "Resources"
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([String].self, from: data)
    }
}
