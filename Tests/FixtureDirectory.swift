@preconcurrency import Citadel

struct FixtureDirectory: SFTPDirectoryHandle {
    let filesystem: FixtureFilesystem
    func listFiles(context: SSHContext) async throws -> [SFTPFileListing] {
        [SFTPFileListing(path: await filesystem.entries())]
    }
}
