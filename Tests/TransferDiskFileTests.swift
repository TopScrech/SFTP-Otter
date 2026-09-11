import Foundation
import Testing

struct TransferDiskFileTests {
    @Test(arguments: ["file 2.txt.part", "100% complete.txt", "résumé.txt"])
    func writesLiteralFileNames(name: String) async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: name)
        let file = try TransferDiskFile(writing: url)
        let data = Data("download".utf8)
        try await file.write(data, offset: 0)
        try await file.close()
        #expect(try Data(contentsOf: url) == data)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false)) == [name])
    }
}
