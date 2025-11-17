import SwiftUI
import GemmaTestAppFeature
import Foundation

@main
struct GemmaTestAppApp: App {
    @State private var output: String = "Starting..."
    
    init() {
        // Run the test when app launches
        Task.detached(priority: .userInitiated) {
            await Self.runTest()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                Text("GemmaTest macOS App")
                    .font(.title)
                    .padding()
                Text("Check console output for results")
                    .foregroundColor(.secondary)
                Text("You can also run this app from command line with arguments")
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .frame(minWidth: 400, minHeight: 200)
        }
    }
    
    private static func runTest() async {
        // Parse command-line arguments
        let arguments = CommandLine.arguments
        
        // Convert relative path to absolute based on current directory
        let currentDir = FileManager.default.currentDirectoryPath
        let relativePath = "../App/Models/gemma-3-270m-it-4bit"
        var modelPath = (currentDir as NSString).appendingPathComponent(relativePath)
        modelPath = (modelPath as NSString).standardizingPath
        var prompt = "Hello"
        var maxTokens = 50
        var temperature: Float = 0.7
        var topK = 50
        
        // Simple argument parsing
        var i = 1
        while i < arguments.count {
            switch arguments[i] {
            case "--model-path", "-d":
                if i + 1 < arguments.count {
                    modelPath = arguments[i + 1]
                    i += 2
                } else {
                    i += 1
                }
            case "--prompt", "-p":
                if i + 1 < arguments.count {
                    prompt = arguments[i + 1]
                    i += 2
                } else {
                    i += 1
                }
            case "--max-tokens", "-n":
                if i + 1 < arguments.count {
                    maxTokens = Int(arguments[i + 1]) ?? 50
                    i += 2
                } else {
                    i += 1
                }
            case "--temperature", "-T":
                if i + 1 < arguments.count {
                    temperature = Float(arguments[i + 1]) ?? 0.7
                    i += 2
                } else {
                    i += 1
                }
            case "--top-k", "-k":
                if i + 1 < arguments.count {
                    topK = Int(arguments[i + 1]) ?? 50
                    i += 2
                } else {
                    i += 1
                }
            default:
                i += 1
            }
        }
        
        let config = GemmaTestConfig(
            modelPath: modelPath,
            prompt: prompt,
            maxTokens: maxTokens,
            temperature: temperature,
            topK: topK
        )
        
        let runner = GemmaTestRunner()
        do {
            try await runner.run(config: config)
            print("\n✅ Test completed successfully")
            exit(0)
        } catch {
            print("\n❌ Error: \(error)")
            exit(1)
        }
    }
}
