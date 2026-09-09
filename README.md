# SFTP Otter

## Features
- Password authentication over SSH with a first-connection SHA256 fingerprint prompt
- Saved host-key pinning, rejection of changed keys, and cancellation of pending trust prompts
- Remote directory listing, navigation, search, and hidden-file filtering
- Streaming uploads and downloads with 64 concurrent 32,000-byte requests per file
- Up to three simultaneous transfers per host, each on a separate SFTP subsystem channel
- Progress updates throttled to ten per second, cancellation, and download export
- Temporary upload/download files, cleanup on failure, and refusal to overwrite an existing remote file
- Host persistence without password persistence
- Two independent desktop file panes and an adaptive mobile tab interface

## Tests
- Encrypted loopback SSH/SFTP upload, directory listing, and byte-for-byte download of 2,000,017 bytes
- Short remote reads, empty-file transfers, existing-file collision handling, and temporary-file cleanup
- In-flight download cancellation while retaining the browsing connection
- Host-key rejection, persisted trust, changed-key rejection, and cancelled/rejected keys never being saved
- Byte integrity with out-of-order completion and a partial final chunk
- Premature end-of-file rejection and transfer cancellation
- Synthetic request-latency comparison
