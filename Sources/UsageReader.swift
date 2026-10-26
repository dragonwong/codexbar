import Foundation
import Darwin

struct ReaderError: Error { let message: String }

func readQuota() throws -> [String: Any] {
    let env = ProcessInfo.processInfo.environment
    let paths = (env["PATH"] ?? "/usr/local/bin:/opt/homebrew/bin:/usr/bin").split(separator: ":").map { "\($0)/codex" }
    let candidates = [env["CODEX_BINARY"] ?? ""] + paths + [
        "/Applications/Codex.app/Contents/Resources/codex",
        "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex",
        "/opt/homebrew/bin/codex", "/usr/local/bin/codex"
    ]
    guard let binary = candidates.first(where: { !$0.isEmpty && FileManager.default.isExecutableFile(atPath: $0) }) else {
        throw ReaderError(message: L10n.text("codex_missing"))
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: binary)
    process.arguments = ["app-server", "--stdio"]
    let input = Pipe(), output = Pipe()
    process.standardInput = input
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice
    try process.run()
    defer {
        try? input.fileHandleForWriting.close()
        if process.isRunning {
            process.terminate()
            let deadline = Date().addingTimeInterval(2)
            while process.isRunning && Date() < deadline { usleep(20_000) }
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
        }
        process.waitUntilExit()
    }
    func send(_ value: [String: Any]) throws {
        var data = try JSONSerialization.data(withJSONObject: value)
        data.append(10)
        try input.fileHandleForWriting.write(contentsOf: data)
    }
    var buffer = Data()
    func response(_ id: Int) throws -> [String: Any] {
        let deadline = ProcessInfo.processInfo.systemUptime + 25
        while ProcessInfo.processInfo.systemUptime < deadline {
            while let newline = buffer.firstIndex(of: 10) {
                let line = Data(buffer[..<newline])
                buffer.removeSubrange(...newline)
                guard let value = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any], value["id"] as? Int == id else { continue }
                if value["error"] != nil { throw ReaderError(message: L10n.text("quota_denied")) }
                return value["result"] as? [String: Any] ?? [:]
            }
            var descriptor = pollfd(fd: output.fileHandleForReading.fileDescriptor, events: Int16(POLLIN), revents: 0)
            let ready = poll(&descriptor, 1, 250)
            if ready < 0 {
                if errno == EINTR { continue }
                throw ReaderError(message: L10n.text("connection_failed"))
            }
            if ready > 0 {
                var bytes = [UInt8](repeating: 0, count: 65536)
                let count = read(descriptor.fd, &bytes, bytes.count)
                guard count > 0 else { throw ReaderError(message: L10n.text("disconnected")) }
                buffer.append(contentsOf: bytes.prefix(count))
                guard buffer.count < 4_194_304 else { throw ReaderError(message: L10n.text("response_too_large")) }
            }
        }
        throw ReaderError(message: L10n.text("timeout"))
    }
    try send(["id": 1, "method": "initialize", "params": ["clientInfo": ["name": "codexbar", "title": "CodexBar", "version": "0.1.1"]]])
    _ = try response(1)
    try send(["method": "initialized"])
    try send(["id": 2, "method": "account/rateLimits/read"])
    let result = try response(2)
    let buckets = result["rateLimitsByLimitId"] as? [String: Any]
    let quota = buckets?["codex"] as? [String: Any] ?? result["rateLimits"] as? [String: Any] ?? [:]
    let windows = [quota["primary"], quota["secondary"]].compactMap { $0 as? [String: Any] }
    return ["windows": windows, "fetchedAt": Date().timeIntervalSince1970]
}

@main
struct UsageReader {
    static func main() {
        // A closed child stdin must become an error, not terminate this process via SIGPIPE.
        signal(SIGPIPE, SIG_IGN)
        let result: [String: Any]
        var status: Int32 = 0
        do { result = try readQuota() }
        catch { result = ["error": (error as? ReaderError)?.message ?? L10n.text("launch_failed")]; status = 1 }
        if let data = try? JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]) {
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data([10]))
        }
        exit(status)
    }
}
