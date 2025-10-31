//
//  MockSSEURLProtocol.swift
//  MyChatGPT
//
//  URLProtocol that replays AG-UI events as a Server-Sent Events (SSE) stream.
//

import Foundation

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

/// URLProtocol that replays AG-UI events as a Server-Sent Events (SSE) stream.
final class MockSSEURLProtocol: URLProtocol {
  private static let queue = DispatchQueue(label: "MockSSEURLProtocol.queue")
  private static var events: [Data] = []
  private static var interval: TimeInterval = 0.2
  private static var completionHandler: (() -> Void)?
  private static var echoMode: Bool = false

  static func configure(events newEvents: [Data], interval: TimeInterval = 0.2, completion: (() -> Void)? = nil) {
    queue.sync {
      events = newEvents
      self.interval = interval
      completionHandler = completion
      echoMode = false
    }
  }
  
  static func enableEchoMode(interval: TimeInterval = 0.2) {
    queue.sync {
      echoMode = true
      self.interval = interval
    }
  }

  override class func canInit(with request: URLRequest) -> Bool {
    print("🔍 [MockSSE] canInit called for URL: \(request.url?.absoluteString ?? "nil")")
    print("🔍 [MockSSE] HTTP Method: \(request.httpMethod ?? "nil")")
    return true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    print("🚀 [MockSSE] startLoading called for URL: \(request.url?.absoluteString ?? "nil")")
    guard let client else { 
      print("❌ [MockSSE] No client available")
      return 
    }

    let response = HTTPURLResponse(
      url: request.url ?? URL(string: "https://mock.local/sse")!,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": "text/event-stream"]
    )!

    client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

    let isEchoMode = MockSSEURLProtocol.queue.sync { MockSSEURLProtocol.echoMode }
    let interval = MockSSEURLProtocol.queue.sync { MockSSEURLProtocol.interval }
    
    DispatchQueue.global().async {
      let eventsToSend: [Data]
      
      if isEchoMode {
        // Extract user message and metadata from request body
        if let payload = self.extractPayload(from: self.request) {
          print("🦜 [MockSSE] Echo mode: generating response for '\(payload.message)' (threadId: \(payload.threadId), runId: \(payload.runId))")
          print("🦜 [MockSSE] Context items count: \(payload.contextItems.count)")
          if !payload.contextItems.isEmpty {
            print("🦜 [MockSSE] Context items dump: \(payload.contextItems)")
          }
          
          do {
            let echoEvents = try AGUIFixtures.echoEvents(
              userInput: payload.message,
              threadId: payload.threadId,
              runId: payload.runId,
              contextItems: payload.contextItems
            )
            eventsToSend = echoEvents.map(\.data)
          } catch {
            print("❌ [MockSSE] Failed to generate echo events: \(error)")
            eventsToSend = []
          }
        } else {
          // No user message in request - this is likely a connection/handshake request
          print("ℹ️  [MockSSE] No user payload found, skipping echo response")
          eventsToSend = []
        }
      } else {
        eventsToSend = MockSSEURLProtocol.queue.sync { MockSSEURLProtocol.events }
      }

      for (index, payload) in eventsToSend.enumerated() {
        guard let jsonString = String(data: payload, encoding: .utf8) else { continue }
        let sseChunk = "data: \(jsonString)\n\n"
        if let data = sseChunk.data(using: .utf8) {
          client.urlProtocol(self, didLoad: data)
        }
        Thread.sleep(forTimeInterval: interval)
        print("🌐 [MockSSE] Emitted event #\(index + 1)")
      }
      print("✅ [MockSSE] Stream complete, finishing loading for URL: \(self.request.url?.absoluteString ?? "nil")")
      client.urlProtocolDidFinishLoading(self)

      let completion = MockSSEURLProtocol.queue.sync { () -> (() -> Void)? in
        let handler = MockSSEURLProtocol.completionHandler
        MockSSEURLProtocol.completionHandler = nil
        return handler
      }
      completion?()
    }
  }
  
  private struct Payload {
    let message: String
    let threadId: String
    let runId: String
    let contextItems: [[String: Any]]
  }

  private func extractPayload(from request: URLRequest) -> Payload? {
    guard let bodyData = request.httpBody ?? request.httpBodyStream?.readAll() else {
      print("⚠️ [MockSSE] Request body missing")
      return nil
    }
    
    if let bodyString = String(data: bodyData, encoding: .utf8) {
      print("📦 [MockSSE] Request body: \(bodyString)")
    }
    
    guard let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] else {
      print("⚠️ [MockSSE] Request body is not valid JSON")
      return nil
    }
    
    guard let threadId = json["threadId"] as? String,
          let runId = json["runId"] as? String else {
      print("⚠️ [MockSSE] Missing threadId/runId in payload")
      return nil
    }

    // Extract attached ConvoUI context items if present
    var contextItems: [[String: Any]] = []
    
    // AG-UI context is an array of {key, value} objects
    // Look for the "convo_ui" entry which contains ConvoUI composer context
    if let contextArray = json["context"] as? [[String: Any]] {
      for entry in contextArray {
        if let key = entry["key"] as? String, key == "convo_ui",
           let value = entry["value"] as? [String: Any],
           let items = value["contextItems"] as? [[String: Any]] {
          contextItems = items
          print("🔗 [MockSSE] Extracted \(contextItems.count) context items from AG-UI context array (key=convo_ui)")
          break
        }
      }
    }

    if let message = json["message"] as? String {
      return Payload(message: message, threadId: threadId, runId: runId, contextItems: contextItems)
    }
    
    // AG-UI payload may bundle messages under an array
    if let messages = json["messages"] as? [[String: Any]] {
      for entry in messages.reversed() {
        if let role = entry["role"] as? String, role == "user", let content = entry["content"] as? String {
          return Payload(message: content, threadId: threadId, runId: runId, contextItems: contextItems)
        }
        if let contentBlocks = entry["content"] as? [[String: Any]] {
          for block in contentBlocks {
            if let type = block["type"] as? String, type == "output_text",
               let text = block["text"] as? String {
              return Payload(message: text, threadId: threadId, runId: runId, contextItems: contextItems)
            }
          }
        }
      }
    }
    
    print("⚠️ [MockSSE] Could not locate user message in payload")
    return nil
  }

  override func stopLoading() {
    // no-op: stream ends automatically
  }
}
