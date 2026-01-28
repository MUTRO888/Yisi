import Foundation
import Vision
import AppKit

// MARK: - Error Types

enum LocalVisionError: LocalizedError {
    case invalidImage
    case processingFailed(String)
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid or corrupted image"
        case .processingFailed(let reason):
            return "Vision processing failed: \(reason)"
        case .noTextFound:
            return "No text found in image"
        }
    }
}

// MARK: - Local Vision Service

final class LocalVisionService {
    
    static let shared = LocalVisionService()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Recognize text from an NSImage using Vision framework
    /// - Parameter image: Source image for OCR
    /// - Returns: Recognized text in natural reading order
    func recognizeText(from image: NSImage) async throws -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw LocalVisionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: LocalVisionError.processingFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation],
                      !observations.isEmpty else {
                    continuation.resume(throwing: LocalVisionError.noTextFound)
                    return
                }
                
                let text = self.extractText(from: observations)
                continuation.resume(returning: text)
            }
            
            // High accuracy mode with language correction
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: LocalVisionError.processingFailed(error.localizedDescription))
            }
        }
    }
    
    /// Recognize text from image data
    func recognizeText(from data: Data) async throws -> String {
        guard let image = NSImage(data: data) else {
            throw LocalVisionError.invalidImage
        }
        return try await recognizeText(from: image)
    }
    
    /// Recognize text from file URL
    func recognizeText(from url: URL) async throws -> String {
        guard let image = NSImage(contentsOf: url) else {
            throw LocalVisionError.invalidImage
        }
        return try await recognizeText(from: image)
    }
    
    // MARK: - Private Helpers
    
    /// Extract text from observations in natural reading order (top-to-bottom, left-to-right)
    private func extractText(from observations: [VNRecognizedTextObservation]) -> String {
        // Sort by vertical position (top to bottom), then horizontal (left to right)
        let sorted = observations.sorted { lhs, rhs in
            // Vision coordinates: (0,0) at bottom-left, y increases upward
            // For reading order: higher y first (top), then lower x first (left)
            let yThreshold: CGFloat = 0.02 // Consider same line if y difference < 2%
            
            if abs(lhs.boundingBox.midY - rhs.boundingBox.midY) < yThreshold {
                return lhs.boundingBox.minX < rhs.boundingBox.minX
            }
            return lhs.boundingBox.midY > rhs.boundingBox.midY
        }
        
        return sorted
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}
