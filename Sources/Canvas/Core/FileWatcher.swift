import Foundation

class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private let path: String
    private let queue: DispatchQueue
    private var lastModified: Date?
    private let debounceInterval: TimeInterval = 0.05  // 50ms

    typealias ChangeHandler = (String) -> Void
    private var onChange: ChangeHandler?

    init(path: String) {
        self.path = path
        self.queue = DispatchQueue(label: "com.macos-tools.canvas.filewatcher")
    }

    func watch(onChange: @escaping ChangeHandler) throws {
        self.onChange = onChange

        let fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            throw FileWatcherError.cannotOpenFile(path)
        }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .rename, .delete],
            queue: queue
        )

        source?.setEventHandler { [weak self] in
            self?.handleFileChange()
        }

        source?.setCancelHandler {
            close(fileDescriptor)
        }

        source?.resume()

        // Initial read
        if let content = try? String(contentsOfFile: path, encoding: .utf8) {
            onChange(content)
        }
    }

    private func handleFileChange() {
        // Debounce rapid changes
        let now = Date()
        if let last = lastModified, now.timeIntervalSince(last) < debounceInterval {
            return
        }
        lastModified = now

        // Small delay to let file system settle
        queue.asyncAfter(deadline: .now() + debounceInterval) { [weak self] in
            guard let self = self else { return }

            do {
                let content = try String(contentsOfFile: self.path, encoding: .utf8)
                DispatchQueue.main.async {
                    self.onChange?(content)
                }
            } catch {
                // File might be temporarily unavailable during write
            }
        }
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    deinit {
        stop()
    }
}

enum FileWatcherError: Error, LocalizedError {
    case cannotOpenFile(String)

    var errorDescription: String? {
        switch self {
        case .cannotOpenFile(let path):
            return "Cannot open file for watching: \(path)"
        }
    }
}
