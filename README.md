# Verification — 6 September 2026

Citadel 0.12.1 is integrated through the Xcode project

The project is a regular Xcode application with an SFTPOtterTests unit-test target and a shared SFTP Otter scheme

The standalone Package.swift, root Package.resolved, and package workspace metadata have been removed

The Xcode workspace retains its dependency lockfile for Citadel and SwiftNIO

## Implemented

- Password authentication over SSH with a first-connection SHA256 fingerprint prompt
- Saved host-key pinning, rejection of changed keys, and cancellation of pending trust prompts
- Remote directory listing, navigation, search, and hidden-file filtering
- Streaming uploads and downloads with 64 concurrent 32,000-byte requests per file
- Up to three simultaneous transfers per host, each on a separate SFTP subsystem channel
- Progress updates throttled to ten per second, cancellation, and download export
- Temporary upload/download files, cleanup on failure, and refusal to overwrite an existing remote file
- Host persistence without password persistence
- Two independent desktop file panes and an adaptive mobile tab interface

## Build and automated evidence

Both Xcode app builds passed in Swift 6 language mode

```sh
xcodebuild -project 'SFTP Otter.xcodeproj' -scheme 'SFTP Otter' -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project 'SFTP Otter.xcodeproj' -scheme 'SFTP Otter' -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project 'SFTP Otter.xcodeproj' -scheme 'SFTP Otter' -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test
```

Eight Swift 6 tests passed with no failures

- Encrypted loopback SSH/SFTP upload, directory listing, and byte-for-byte download of 2,000,017 bytes
- Short remote reads, empty-file transfers, existing-file collision handling, and temporary-file cleanup
- In-flight download cancellation while retaining the browsing connection
- Host-key rejection, persisted trust, changed-key rejection, and cancelled/rejected keys never being saved
- Byte integrity with out-of-order completion and a partial final chunk
- Premature end-of-file rejection and transfer cancellation
- Synthetic request-latency comparison

The final synthetic run used twenty chunks and 10 ms of latency per read: serial requests took 248.8 ms and pipelined requests took 12.9 ms

That comparison verifies reduced latency overhead in the pipeline — it is not a measured Internet or LAN transfer rate

The integration fixture binds only to 127.0.0.1, uses an ephemeral host key and randomly generated password, stores files in memory, and closes at the end of the test

## Visual evidence and remaining work

The Mac app was inspected through native UI automation

Verified the host editor, empty host vault, preview file rows, file search, compact toolbar, and paired desktop connection panes

The first reference was the tablet screenshot in Termius's [Rethinking SFTP for Mobile](https://termius.com/blog/rethinking-sftp-for-mobile)

On 6 September the installed Termius app displayed its desktop SFTP screen with two side-by-side connection panes, so the desktop implementation was corrected to follow that actual reference

The app now follows the desktop reference's dark palette, Vaults/SFTP tabs, split panes, folder emblems, Connect to host text, and Select host actions

Exact visual parity is not proven — native title bars, fonts, spacing, and connected-screen controls still need comparison

The user subsequently connected Termius to their backup server and prohibited deletion of existing files

The connected screen was inspected using only a screenshot — no file, menu, transfer, rename, or delete action was performed in Termius

The desktop browser was updated to follow the connected reference: Name, Date Modified, Size, and Kind columns; permission subtitles; a host header; Filter and Actions controls; path navigation; and the second connection pane

The result was inspected in the running Mac app with synthetic local archive metadata — Filter reduced ten preview rows to the single matching file

Back/forward navigation was added and tested to preserve history across refresh and failed directory navigation

Both macOS and generic iOS builds passed after these changes, and eight tests passed

No backup-server file was created, uploaded, downloaded, renamed, modified, or deleted by this work

No simulator was launched and no user-provided or production SFTP server was contacted

The iOS interface has been compiled but has not been visually inspected on a device

Authentication currently supports passwords — private-key authentication, directory transfers, remote-to-remote copying, and pause/resume are not implemented
