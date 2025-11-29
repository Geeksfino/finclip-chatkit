//
//  LocalLLMURLProtocol.swift
//  MyPal
//
//  URLProtocol that intercepts network requests and routes them to local LLM (Gemma 270M via MediaPipe)
//  Based on MockSSEURLProtocol pattern from MyChatGPT example
//

import Foundation
import FinClipChatKit

extension InputStream {
  func readAll() -> Data? {
    var data = Data()
    open()
    defer { close() }
    
    let bufferSize = 1024
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }
    
    while hasBytesAvailable {
      let bytesRead = read(buffer, maxLength: bufferSize)
      if bytesRead > 0 {
        data.append(buffer, count: bytesRead)
      } else {
        break
      }
    }
    
    return data.isEmpty ? nil : data
  }
}

/// URLProtocol that intercepts network requests and routes them to local LLM
/// Generates AG-UI events as Server-Sent Events (SSE) stream
final class LocalLLMURLProtocol: URLProtocol {
  private static let queue = DispatchQueue(label: "LocalLLMURLProtocol.queue")
  private static var isEnabled: Bool = false
  private static var interval: TimeInterval = 0.1
  private static var modelManager: LocalLLMModelManager?
  private static var coordinator: ChatKitCoordinator?
  
  static func enableLocalLLMMode(
    modelManager: LocalLLMModelManager,
    coordinator: ChatKitCoordinator? = nil,
    interval: TimeInterval = 0.1
  ) {
    queue.sync {
      isEnabled = true
      self.interval = interval
      self.modelManager = modelManager
      self.coordinator = coordinator
    }
  }
  
  static func disableLocalLLMMode() {
    queue.sync {
      isEnabled = false
      modelManager = nil
      coordinator = nil
    }
  }
  
  override class func canInit(with request: URLRequest) -> Bool {
    // Check if this is a request we should intercept
    // Intercept requests to localhost/127.0.0.1 when URLProtocol is registered
    // This prevents connection errors while model is loading
    guard let url = request.url else { return false }
    
    // Intercept requests to:
    // - local-llm.local (our mock URL)
    // - 127.0.0.1 or localhost (default server URL)
    // - Any URL when explicitly enabled (model loaded)
    let host = url.host ?? ""
    let shouldIntercept = host == "local-llm.local" || 
                         host == "127.0.0.1" ||
                         host == "localhost"
    
    let enabled = queue.sync { isEnabled }
    
    if shouldIntercept || enabled {
      print("🔍 [LocalLLM] canInit called for URL: \(url.absoluteString)")
      print("🔍 [LocalLLM] HTTP Method: \(request.httpMethod ?? "nil")")
      print("🔍 [LocalLLM] Host: \(host)")
      print("🔍 [LocalLLM] Should intercept: \(shouldIntercept), Enabled: \(enabled)")
      return true
    }
    
    return false
  }
  
  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }
  
  override func startLoading() {
    print("🚀 [LocalLLM] startLoading called for URL: \(request.url?.absoluteString ?? "nil")")
    guard let client else {
      print("❌ [LocalLLM] No client available")
      return
    }
    
    let response = HTTPURLResponse(
      url: request.url ?? URL(string: "https://local-llm.local/sse")!,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": "text/event-stream"]
    )!
    
    client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    
    let interval = LocalLLMURLProtocol.queue.sync { LocalLLMURLProtocol.interval }
    let modelManager = LocalLLMURLProtocol.queue.sync { LocalLLMURLProtocol.modelManager }
    
    DispatchQueue.global().async {
      // Extract user message and metadata from request body
      guard let payload = self.extractPayload(from: self.request) else {
        // No user message in request - this is likely a connection/handshake request
        print("ℹ️  [LocalLLM] No user payload found, skipping LLM response")
        client.urlProtocolDidFinishLoading(self)
        return
      }
      
      print("🤖 [LocalLLM] Generating response for '\(payload.message)' (threadId: \(payload.threadId), runId: \(payload.runId))")
      print("🤖 [LocalLLM] Context items count: \(payload.contextItems.count)")
      print("🤖 [LocalLLM] Selected tools count: \(payload.selectedTools.count)")
      
      // Retrieve conversation history for this thread
      let coordinator = LocalLLMURLProtocol.queue.sync { LocalLLMURLProtocol.coordinator }
      let conversationHistory = self.getConversationHistory(threadId: payload.threadId, coordinator: coordinator)
      
      // Call local LLM with the user message
      guard let modelManager = modelManager else {
        print("❌ [LocalLLM] Model manager not available")
        print("   Model may still be loading. Returning error message in AG-UI format.")
        
        // Return proper AG-UI events for error message
        let errorMessage = "Local LLM model is still loading. Please wait a moment and try again."
        do {
          let events = try LocalLLMAGUIEvents.generateEventsFromLLM(
            response: errorMessage,
            threadId: payload.threadId,
            runId: payload.runId,
            contextItems: payload.contextItems,
            selectedTools: payload.selectedTools
          )
          
          // Stream events as SSE
          for (index, event) in events.enumerated() {
            guard let jsonString = String(data: event.data, encoding: .utf8) else { continue }
            let sseChunk = "data: \(jsonString)\n\n"
            if let data = sseChunk.data(using: .utf8) {
              client.urlProtocol(self, didLoad: data)
            }
            Thread.sleep(forTimeInterval: interval)
            print("🌐 [LocalLLM] Emitted error event #\(index + 1)")
          }
          
          print("✅ [LocalLLM] Error message stream complete")
          client.urlProtocolDidFinishLoading(self)
        } catch {
          print("❌ [LocalLLM] Failed to generate error events: \(error)")
          client.urlProtocolDidFinishLoading(self)
        }
        return
      }
      
      // Generate response using local LLM with conversation history
      modelManager.generateResponse(
        prompt: payload.message,
        contextItems: payload.contextItems,
        selectedTools: payload.selectedTools,
        conversationHistory: conversationHistory
      ) { result in
        switch result {
        case .success(let response):
          do {
            // Generate AG-UI events from LLM response
            let events = try LocalLLMAGUIEvents.generateEventsFromLLM(
              response: response,
              threadId: payload.threadId,
              runId: payload.runId,
              contextItems: payload.contextItems,
              selectedTools: payload.selectedTools
            )
            
            // Stream events as SSE
            for (index, event) in events.enumerated() {
              guard let jsonString = String(data: event.data, encoding: .utf8) else { continue }
              let sseChunk = "data: \(jsonString)\n\n"
              if let data = sseChunk.data(using: .utf8) {
                client.urlProtocol(self, didLoad: data)
              }
              Thread.sleep(forTimeInterval: interval)
              print("🌐 [LocalLLM] Emitted event #\(index + 1)")
            }
            
            print("✅ [LocalLLM] Stream complete")
            client.urlProtocolDidFinishLoading(self)
          } catch {
            print("❌ [LocalLLM] Failed to generate AG-UI events: \(error)")
            client.urlProtocolDidFinishLoading(self)
          }
          
        case .failure(let error):
          print("❌ [LocalLLM] LLM generation failed: \(error)")
          client.urlProtocolDidFinishLoading(self)
        }
      }
    }
  }
  
  private struct Payload {
    let message: String
    let threadId: String
    let runId: String
    let contextItems: [[String: Any]]
    let selectedTools: [[String: Any]]
  }
  
  private func extractPayload(from request: URLRequest) -> Payload? {
    guard let bodyData = request.httpBody ?? request.httpBodyStream?.readAll() else {
      print("⚠️ [LocalLLM] Request body missing")
      return nil
    }
    
    if let bodyString = String(data: bodyData, encoding: .utf8) {
      print("📦 [LocalLLM] Request body: \(bodyString.prefix(500))...")
    }
    
    guard let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] else {
      print("⚠️ [LocalLLM] Request body is not valid JSON")
      return nil
    }
    
    guard let threadId = json["threadId"] as? String,
          let runId = json["runId"] as? String else {
      print("⚠️ [LocalLLM] Missing threadId/runId in payload")
      return nil
    }
    
    // Extract attached ConvoUI context items if present
    var contextItems: [[String: Any]] = []
    var selectedTools: [[String: Any]] = []
    
    // AG-UI context is an array of {key, value} objects
    // Look for the "convo_ui" entry which contains ConvoUI composer context
    if let contextArray = json["context"] as? [[String: Any]] {
      for entry in contextArray {
        if let key = entry["key"] as? String, let value = entry["value"] as? [String: Any] {
          // Extract from convo_ui context
          if key == "convo_ui" {
            // Extract context items
            if let items = value["contextItems"] as? [[String: Any]] {
              contextItems = items
              print("🔗 [LocalLLM] Extracted \(contextItems.count) context items from AG-UI context array (key=convo_ui)")
            }
          }
        }
      }
    }
    
    // Extract tools from the proper tools array (AG-UI compliant)
    if let toolsArray = json["tools"] as? [[String: Any]] {
      // Convert AG-UI Tool format back to selectedTools format
      selectedTools = toolsArray.map { tool in
        var toolDict: [String: Any] = [:]
        toolDict["itemId"] = tool["name"] ?? "unknown"
        toolDict["displayName"] = tool["description"] ?? tool["name"] ?? "unknown"
        if let parameters = tool["parameters"] {
          toolDict["metadata"] = parameters
        }
        return toolDict
      }
      print("🔧 [LocalLLM] Extracted \(selectedTools.count) tools from AG-UI tools array")
    }
    
    if let message = json["message"] as? String {
      return Payload(message: message, threadId: threadId, runId: runId, contextItems: contextItems, selectedTools: selectedTools)
    }
    
    // AG-UI payload may bundle messages under an array
    if let messages = json["messages"] as? [[String: Any]] {
      for entry in messages.reversed() {
        if let role = entry["role"] as? String, role == "user", let content = entry["content"] as? String {
          return Payload(message: content, threadId: threadId, runId: runId, contextItems: contextItems, selectedTools: selectedTools)
        }
        if let contentBlocks = entry["content"] as? [[String: Any]] {
          for block in contentBlocks {
            if let type = block["type"] as? String, type == "output_text",
               let text = block["text"] as? String {
              return Payload(message: text, threadId: threadId, runId: runId, contextItems: contextItems, selectedTools: selectedTools)
            }
          }
        }
      }
    }
    
    print("⚠️ [LocalLLM] Could not locate user message in payload")
    return nil
  }
  
  override func stopLoading() {
    // no-op: stream ends automatically
  }
  
  /// Retrieve conversation history for a given thread ID
  /// - Parameters:
  ///   - threadId: The conversation thread identifier
  ///   - coordinator: Optional ChatKitCoordinator to access message store via ChatKit API
  ///   - Note: The coordinator must be the same instance created by SceneDelegate to ensure
  ///           we're using the app's initialized runtime, not creating a new one
  /// - Returns: 
  ///   - `nil`: Coordinator unavailable or query failed (temporary - may succeed later)
  ///   - `[]`: Coordinator available, query succeeded, but no history exists (permanent for this message)
  ///   - `[ConversationMessage]`: Successfully retrieved conversation history
  private func getConversationHistory(threadId: String, coordinator: ChatKitCoordinator?) -> [ConversationMessage]? {
    guard let coordinator = coordinator else {
      print("⚠️  [LocalLLM] ChatKitCoordinator not available, cannot retrieve conversation history")
      print("   This may be temporary - coordinator may become available for subsequent messages")
      print("   Proceeding without conversation history for this request")
      return nil  // nil = coordinator unavailable (temporary)
    }
    
    // Pass the coordinator to history manager - it will access coordinator.runtime
    // This ensures we use the SAME runtime instance initialized by the app
    let historyManager = LocalLLMConversationHistoryManager(coordinator: coordinator)
    let maxTokens = AppConfig.localModelContextSize
    
    // Retrieve conversation history (will be truncated to fit context window)
    let history = historyManager.getConversationHistory(threadId: threadId, maxTokens: maxTokens)
    
    // Distinguish between different return values for better logging
    switch history {
    case .none:
      // nil = coordinator unavailable or query failed (temporary)
      print("⚠️  [LocalLLM] Could not retrieve conversation history (coordinator unavailable or query failed)")
      print("   History may be available for subsequent messages once coordinator is initialized")
    case .some(let messages) where messages.isEmpty:
      // [] = successfully queried but no history (permanent for this message)
      print("ℹ️  [LocalLLM] No conversation history available (first message in thread)")
    case .some(let messages):
      // [ConversationMessage] = successfully retrieved history
      print("📚 [LocalLLM] Retrieved \(messages.count) messages from conversation history")
    }
    
    return history
  }
}

