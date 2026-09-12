import Foundation
import Testing

struct FileSortOrderTests {
    @Test func parentAndFoldersStayFirstInBothDirections() {
        let entries = [file("item2"), file("folder", directory: true), file("..", directory: true), file("item10")]
        #expect(FileSortOrder().sorted(entries).map(\.name) == ["..", "folder", "item2", "item10"])
        #expect(FileSortOrder(ascending: false).sorted(entries).map(\.name) == ["..", "folder", "item10", "item2"])
    }

    @Test func numericSizesAndDatesSortWithStableNameTies() {
        let entries = [file("b", size: 2, modified: 2), file("c", size: 10, modified: 1), file("a", size: 2, modified: 2)]
        #expect(FileSortOrder(column: .size).sorted(entries).map(\.name) == ["a", "b", "c"])
        #expect(FileSortOrder(column: .size, ascending: false).sorted(entries).map(\.name) == ["c", "a", "b"])
        #expect(FileSortOrder(column: .modified).sorted(entries).map(\.name) == ["c", "a", "b"])
    }

    @Test func kindsUseTheDisplayedExtension() {
        let entries = [file("archive.tar.zst"), file("photo.png"), file("README")]
        #expect(FileSortOrder(column: .kind).sorted(entries).map(\.name) == ["README", "photo.png", "archive.tar.zst"])
    }

    @Test func selectingAColumnReversesOnlyTheCurrentColumn() {
        var order = FileSortOrder()
        order.select(.name)
        #expect(!order.ascending)
        order.select(.size)
        #expect(order.column == .size)
        #expect(order.ascending)
    }

    private func file(_ name: String, directory: Bool = false, size: UInt64 = 0, modified: TimeInterval = 0) -> RemoteFile {
        RemoteFile(path: "/" + name, name: name, isDirectory: directory, size: size, modified: Date(timeIntervalSince1970: modified), permissions: "")
    }
}
