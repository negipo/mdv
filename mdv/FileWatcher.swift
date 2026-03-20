import Foundation

class FileWatcher {
    private var stream: FSEventStreamRef?
    private let filePath: String
    private let directory: String
    private let fileName: String
    private let callback: () -> Void
    private var debounceTimer: DispatchSourceTimer?
    private let debounceInterval: TimeInterval

    init(filePath: String, debounceInterval: TimeInterval = 0.1, callback: @escaping () -> Void) {
        self.filePath = filePath
        self.directory = (filePath as NSString).deletingLastPathComponent
        self.fileName = (filePath as NSString).lastPathComponent
        self.callback = callback
        self.debounceInterval = debounceInterval
    }

    func start() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        var streamContext = FSEventStreamContext(
            version: 0,
            info: context,
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let flags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes |
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagNoDefer
        )

        guard let stream = FSEventStreamCreate(
            nil,
            { _, info, numEvents, eventPaths, _, _ in
                guard let info = info else { return }
                let watcher = Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue()
                let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as! [String]
                for i in 0..<numEvents {
                    let path = paths[i]
                    if (path as NSString).lastPathComponent == watcher.fileName {
                        watcher.scheduleCallback()
                        break
                    }
                }
            },
            &streamContext,
            [directory] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0,
            flags
        ) else { return }

        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)
    }

    func stop() {
        debounceTimer?.cancel()
        debounceTimer = nil
        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }

    private func scheduleCallback() {
        debounceTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + debounceInterval)
        timer.setEventHandler { [weak self] in
            self?.callback()
        }
        timer.resume()
        debounceTimer = timer
    }

    deinit {
        stop()
    }
}
