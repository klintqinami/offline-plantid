import Foundation
import TensorFlowLite
import UIKit

struct Prediction: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float
}

enum ModelDataHandlerError: Error, LocalizedError {
    case modelNotFound
    case labelsNotFound
    case invalidInputImage
    case unsupportedInputType

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Model file not found in app bundle."
        case .labelsNotFound:
            return "Labels file not found in app bundle."
        case .invalidInputImage:
            return "Unable to preprocess image for model input."
        case .unsupportedInputType:
            return "Model input type is not supported."
        }
    }
}

final class ModelDataHandler {
    private let interpreter: Interpreter
    private let labels: [String]
    private let inputWidth: Int
    private let inputHeight: Int
    private let inputChannels: Int
    private let inputDataType: Tensor.DataType

    private let modelFileName = "inat_plant"
    private let modelFileExtension = "tflite"
    private let labelsFileName = "aiy_plants_V1_labelmap"
    private let labelsFileExtension = "csv"

    init?() {
        do {
            guard let modelPath = Bundle.main.path(forResource: modelFileName, ofType: modelFileExtension) else {
                throw ModelDataHandlerError.modelNotFound
            }
            guard let labelsPath = Bundle.main.path(forResource: labelsFileName, ofType: labelsFileExtension) else {
                throw ModelDataHandlerError.labelsNotFound
            }

            interpreter = try Interpreter(modelPath: modelPath)
            try interpreter.allocateTensors()

            let inputTensor = try interpreter.input(at: 0)
            inputWidth = inputTensor.shape.dimensions[1]
            inputHeight = inputTensor.shape.dimensions[2]
            inputChannels = inputTensor.shape.dimensions[3]
            inputDataType = inputTensor.dataType

            let labelText = try String(contentsOfFile: labelsPath, encoding: .utf8)
            labels = ModelDataHandler.parseCSVLabels(from: labelText)
        } catch {
            return nil
        }
    }

    func runModel(on image: UIImage, topK: Int) throws -> [Prediction] {
        let size = CGSize(width: inputWidth, height: inputHeight)
        guard let resized = ImagePreprocessor.resized(image, to: size) else {
            throw ModelDataHandlerError.invalidInputImage
        }
        guard let inputData = ImagePreprocessor.rgbData(from: resized, dataType: inputDataType) else {
            throw ModelDataHandlerError.unsupportedInputType
        }

        try interpreter.copy(inputData, toInputAt: 0)
        try interpreter.invoke()

        let outputTensor = try interpreter.output(at: 0)
        let outputScores = try outputTensor.toFloatArray()

        return topKPredictions(from: outputScores, topK: topK)
    }

    private func topKPredictions(from scores: [Float], topK: Int) -> [Prediction] {
        let indexedScores = scores.enumerated().map { index, score in
            (index, score)
        }

        let topIndices = indexedScores
            .sorted { $0.1 > $1.1 }
            .prefix(topK)

        return topIndices.map { index, score in
            let label = (index < labels.count ? labels[index] : nil) ?? "Unknown"
            return Prediction(label: label, confidence: score)
        }
    }

    private static func parseCSVLabels(from text: String) -> [String] {
        var maxId = -1
        var rows: [(Int, String)] = []

        for (lineIndex, line) in text.components(separatedBy: .newlines).enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            if lineIndex == 0 { continue } // Header: id,name

            let parts = trimmed.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2, let id = Int(parts[0]) else { continue }
            let name = String(parts[1])
            rows.append((id, name))
            if id > maxId { maxId = id }
        }

        if maxId < 0 { return [] }
        var labels = Array(repeating: "", count: maxId + 1)
        for (id, name) in rows {
            labels[id] = name
        }
        return labels
    }
}

private extension Tensor {
    func toFloatArray() throws -> [Float] {
        switch dataType {
        case .float32:
            return data.toArray(type: Float.self)
        case .uInt8:
            let uint8Values = data.toArray(type: UInt8.self)
            let scale = quantizationParameters?.scale ?? 1.0
            let zeroPoint = Float(quantizationParameters?.zeroPoint ?? 0)
            return uint8Values.map { (Float($0) - zeroPoint) * scale }
        default:
            throw ModelDataHandlerError.unsupportedInputType
        }
    }
}

private extension Data {
    func toArray<T>(type: T.Type) -> [T] {
        let count = self.count / MemoryLayout<T>.stride
        return withUnsafeBytes { pointer in
            Array(pointer.bindMemory(to: T.self).prefix(count))
        }
    }
}
