import UIKit
import TensorFlowLite

enum ImagePreprocessor {
    static func resized(_ image: UIImage, to size: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    static func rgbData(from image: UIImage, dataType: Tensor.DataType) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelBuffer = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        guard let context = CGContext(
            data: &pixelBuffer,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        switch dataType {
        case .uInt8:
            var data = Data(capacity: width * height * 3)
            for i in stride(from: 0, to: pixelBuffer.count, by: 4) {
                data.append(pixelBuffer[i])     // R
                data.append(pixelBuffer[i + 1]) // G
                data.append(pixelBuffer[i + 2]) // B
            }
            return data
        case .float32:
            var floats = [Float]()
            floats.reserveCapacity(width * height * 3)
            for i in stride(from: 0, to: pixelBuffer.count, by: 4) {
                let r = (Float(pixelBuffer[i]) - 127.5) / 127.5
                let g = (Float(pixelBuffer[i + 1]) - 127.5) / 127.5
                let b = (Float(pixelBuffer[i + 2]) - 127.5) / 127.5
                floats.append(r)
                floats.append(g)
                floats.append(b)
            }
            return Data(copyingBufferOf: floats)
        default:
            return nil
        }
    }
}

extension Data {
    init<T>(copyingBufferOf array: [T]) {
        self = array.withUnsafeBufferPointer { Data(buffer: $0) }
    }
}
