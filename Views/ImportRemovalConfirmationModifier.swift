import SwiftUI

struct ImportRemovalConfirmationModifier: ViewModifier {
    @Binding var rowIDs: Set<String>
    let isActive: Bool
    let confirm: (Set<String>) -> Void

    func body(content: Content) -> some View {
        content.alert(
            rowIDs.count == 1 ? "Delete this row from the import preview?" : "Delete \(rowIDs.count) rows from the import preview?",
            isPresented: Binding(
                get: { isActive && !rowIDs.isEmpty },
                set: { if !$0 && isActive { rowIDs = [] } }
            ),
            presenting: rowIDs
        ) { ids in
            Button("Cancel", role: .cancel) { rowIDs = [] }
            Button(ids.count == 1 ? "Delete row" : "Delete rows", role: .destructive) { confirm(ids) }
        } message: { _ in
            Text("These rows will be skipped when you import. The source CSV stays unchanged. You can bring them back with Undo removals.")
        }
    }
}
