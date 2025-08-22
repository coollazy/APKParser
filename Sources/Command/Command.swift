import Foundation

public struct Command {
    @discardableResult
    public static func run(_ command: String, arguments: [String], timeout: DispatchTime = .now() + 20, environment customEnv: [String: String]? = nil, logEnable: Bool = false) throws -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<String, Error>?
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        
        // 設定 PATH 環境變數
        var environment = ProcessInfo.processInfo.environment
        let currentPath = environment["PATH"] ?? ""
#if os(macOS)
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + currentPath
#elseif os(Linux)
        environment["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:" + currentPath
#else
        // 其他系統的預設設定
        environment["PATH"] = "/usr/local/bin:/usr/bin:/bin:" + currentPath
#endif
        if let customEnv {
            for (key, value) in customEnv {
                environment[key] = value
            }
        }
        process.environment = environment
        
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // 即時讀取輸出
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if !data.isEmpty {
                if logEnable, let output = String(data: data, encoding: .utf8) {
                    print("\(output.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
            }
        }
        
        // 即時讀取錯誤輸出
        errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if !data.isEmpty {
                if logEnable, let error = String(data: data, encoding: .utf8) {
                    print("Error: \(error.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
            }
        }
        
        // 設定完成回調(Docker container 裡面運行的時候，一定要用 terminatinHandler 才不會卡住)
        process.terminationHandler = { process in
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""
            let combinedOutput = output + error
            
            if process.terminationStatus == 0 {
                result = .success(combinedOutput)
            }
            else {
                let error = NSError(
                    domain: "Command Error \(command)",
                    code: Int(process.terminationStatus),
                    userInfo: [NSLocalizedDescriptionKey: "\(arguments.joined(separator: " "))\n\n\(output)\n\n\(error)"]
                )
                result = .failure(error)
            }
            semaphore.signal()
        }
        
        do {
            try process.run()
            let timeoutResult = semaphore.wait(timeout: timeout)
            if timeoutResult == .timedOut {
                process.terminate()
                throw NSError(
                    domain: "Command Timeout Error",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "\(command) operation timed out"]
                )
            }
        } catch {
            result = .failure(error)
        }
        
        guard let result else {
            throw NSError(
                domain: "Command Error \(command)",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "\(command) operation failed, no result"]
            )
        }
        switch result {
        case .success(let output):
            return output
        case .failure(let error):
            throw error
        }
    }
}
