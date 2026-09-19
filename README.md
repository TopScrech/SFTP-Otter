# SFTP Otter

An SFTP client for browsing and transferring files between your Mac and remote servers

## Features

- Two independent file panes for local folders and remote hosts
- Securely saved hosts and passwords in Keychain, with SSH server identity verification
- Parallel file and folder uploads and downloads with configurable concurrency
- Transfer progress, cancellation, and file conflict handling
- Search, sortable columns, multi-selection, and keyboard navigation
- Drag and drop between the app, Finder, and other apps
- Quick Look previews of local and remote files
- File management with copying, renaming, deletion, and permission editing
- Optional restoration of connected hosts, local folders, and remote locations after relaunch

## Targets and source membership

- `macOS` builds the Mac app from `SFTP Otter` and `macOS`
- `iOS` builds the iPhone, iPad, and visionOS app from `SFTP Otter` and `iOS`
- `SFTP Otter` contains shared features and assets, with no app entry point
- `macOS` contains the desktop app entry point, workspace shell, menus, Quick Look, drag promises, and Dock integration
- `iOS` contains the mobile app entry point and workspace shell
- `Unit Tests` runs on macOS and compiles the selected shared and Mac sources listed in `project.xcproj`

The folders use automatic target membership, so add new files to the appropriate folder
Keep platform checks only where a shared implementation needs different platform APIs
The shared `SFTP Otter` scheme builds macOS and runs the tests; the shared `iOS` scheme builds iOS, iPadOS, or visionOS using the selected destination
