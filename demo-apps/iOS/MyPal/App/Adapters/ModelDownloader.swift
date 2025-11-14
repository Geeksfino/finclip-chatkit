//
//  ModelDownloader.swift
//  MyPal
//
//  Handles downloading Gemma 270M MLX model files from Hugging Face
//

import Foundation

enum ModelDownloadError: Error, LocalizedError {
  case invalidURL
  case downloadFailed(Error)
  case invalidResponse
  case insufficientStorage
  
  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid model URL"
    case .downloadFailed(let error):
      return "Download failed: \(error.localizedDescription)"
    case .invalidResponse:
      return "Invalid server response"
    case .insufficientStorage:
      return "Insufficient storage space"
    }
  }
}

class ModelDownloader {
  typealias ProgressHandler = (Double) -> Void
  typealias CompletionHandler = (Result<URL, Error>) -> Void
  
  private var downloadTask: URLSessionDownloadTask?
  private var progressHandler: ProgressHandler?
  private var completionHandler: CompletionHandler?
  private var destinationURL: URL?
  
  /// Download model from Hugging Face
  /// - Parameters:
  ///   - repository: Hugging Face repository (e.g., "mlx-community/gemma-270m-it")
  ///   - fileName: Model file name (e.g., "weights.safetensors")
  ///   - destinationURL: Local destination URL
  ///   - progress: Progress handler (0.0 to 1.0)
  ///   - completion: Completion handler
  func download(
    repository: String,
    fileName: String,
    destinationURL: URL,
    progress: @escaping ProgressHandler,
    completion: @escaping CompletionHandler
  ) {
    self.progressHandler = progress
    self.completionHandler = completion
    self.destinationURL = destinationURL
    
    // Hugging Face raw file URL format: https://huggingface.co/{repo}/resolve/main/{file}
    guard let url = URL(string: "https://huggingface.co/\(repository)/resolve/main/\(fileName)") else {
      completion(.failure(ModelDownloadError.invalidURL))
      return
    }
    
    // Check available storage
    if let availableSpace = availableStorageSpace(), availableSpace < 500_000_000 { // 500MB
      completion(.failure(ModelDownloadError.insufficientStorage))
      return
    }
    
    let session = URLSession(
      configuration: .default,
      delegate: DownloadDelegate(downloader: self),
      delegateQueue: nil
    )
    
    downloadTask = session.downloadTask(with: url)
    downloadTask?.resume()
  }
  
  func cancel() {
    downloadTask?.cancel()
    downloadTask = nil
  }
  
  private func availableStorageSpace() -> Int64? {
    guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
          let freeSpace = attributes[.systemFreeSize] as? Int64 else {
      return nil
    }
    return freeSpace
  }
  
  private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    weak var downloader: ModelDownloader?
    
    init(downloader: ModelDownloader) {
      self.downloader = downloader
    }
    
    func urlSession(
      _ session: URLSession,
      downloadTask: URLSessionDownloadTask,
      didWriteData bytesWritten: Int64,
      totalBytesWritten: Int64,
      totalBytesExpectedToWrite: Int64
    ) {
      let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
      DispatchQueue.main.async {
        self.downloader?.progressHandler?(progress)
      }
    }
    
    func urlSession(
      _ session: URLSession,
      downloadTask: URLSessionDownloadTask,
      didFinishDownloadingTo location: URL
    ) {
      guard let downloader = downloader,
            let destinationURL = downloader.destinationURL else { return }
      
      do {
        // Create destination directory if needed
        let destinationDir = destinationURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        
        // Move downloaded file to destination
        if FileManager.default.fileExists(atPath: destinationURL.path) {
          try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.moveItem(at: location, to: destinationURL)
        
        DispatchQueue.main.async {
          downloader.completionHandler?(.success(destinationURL))
        }
      } catch {
        DispatchQueue.main.async {
          downloader.completionHandler?(.failure(ModelDownloadError.downloadFailed(error)))
        }
      }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
      guard let downloader = downloader, let error = error else { return }
      DispatchQueue.main.async {
        downloader.completionHandler?(.failure(ModelDownloadError.downloadFailed(error)))
      }
    }
  }
}

