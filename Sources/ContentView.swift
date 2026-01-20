import SwiftUI

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var predictions: [Prediction] = []
    @State private var isPickerPresented = false
    @State private var errorMessage: String?

    private let modelDataHandler = ModelDataHandler()

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                photoCard
                actionRow
                resultCard
                tipsCard
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height, alignment: .top)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            LinearGradient(
                colors: [Color(red: 0.96, green: 0.98, blue: 0.94),
                         Color(red: 0.90, green: 0.95, blue: 0.90)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $isPickerPresented) {
            PhotoPicker { image in
                selectedImage = image
                runInference(image: image)
            }
        }
    }

    private func runInference(image: UIImage) {
        errorMessage = nil
        predictions = []

        guard let handler = modelDataHandler else {
            errorMessage = "Model failed to load. Check model file name."
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let results = try handler.runModel(on: image, topK: 5)
                DispatchQueue.main.async {
                    predictions = results
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

private extension ContentView {
    var topPrediction: Prediction? {
        predictions.max(by: { $0.confidence < $1.confidence })
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Offline PlantID")
                        .font(.custom("AvenirNext-Heavy", size: 26))
                        .foregroundColor(Color(red: 0.10, green: 0.16, blue: 0.13))
                    Text("Identify plants on-device, no signal needed.")
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundColor(Color(red: 0.30, green: 0.40, blue: 0.32))
                }
                Spacer()
                Button {
                    selectedImage = nil
                    predictions = []
                    errorMessage = nil
                } label: {
                    Image(systemName: "house.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.18, green: 0.40, blue: 0.28))
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                }
                .accessibilityLabel("Go home")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var photoCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipped()
                    .cornerRadius(16)
                    .padding(6)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.35, green: 0.55, blue: 0.38))
                    Text("Pick a plant photo")
                        .font(.custom("AvenirNext-DemiBold", size: 14))
                        .foregroundColor(Color(red: 0.28, green: 0.35, blue: 0.30))
                    Text("Leaf close-up or flower helps")
                        .font(.custom("AvenirNext-Regular", size: 11))
                        .foregroundColor(Color(red: 0.40, green: 0.48, blue: 0.42))
                }
                .frame(height: 180)
            }
        }
    }

    var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                isPickerPresented = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text(selectedImage == nil ? "Pick Photo" : "Pick Another")
                        .font(.custom("AvenirNext-DemiBold", size: 15))
                }
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.18, green: 0.50, blue: 0.32),
                                 Color(red: 0.10, green: 0.40, blue: 0.28)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top matches")
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                Spacer()
                if !predictions.isEmpty {
                    Text("Confidence")
                        .font(.custom("AvenirNext-Medium", size: 10))
                        .foregroundColor(Color(red: 0.45, green: 0.52, blue: 0.46))
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundColor(Color(red: 0.72, green: 0.18, blue: 0.18))
            } else if predictions.isEmpty {
                Text("Pick a photo to see predictions.")
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(Color(red: 0.45, green: 0.52, blue: 0.46))
            } else {
                if let topPrediction {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("Most likely:")
                            .font(.custom("AvenirNext-Medium", size: 12))
                            .foregroundColor(Color(red: 0.35, green: 0.42, blue: 0.36))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(topPrediction.displayName)
                                .font(.custom("AvenirNext-DemiBold", size: 13))
                                .foregroundColor(Color(red: 0.12, green: 0.18, blue: 0.14))
                            if let secondary = topPrediction.secondaryName {
                                Text(secondary)
                                    .font(.custom("AvenirNext-Regular", size: 11))
                                    .foregroundColor(Color(red: 0.42, green: 0.50, blue: 0.44))
                            }
                        }
                    }
                }
                VStack(spacing: 8) {
                    ForEach(predictions) { prediction in
                        let isTop = prediction.id == topPrediction?.id
                        VStack(spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(prediction.displayName)
                                        .font(.custom("AvenirNext-Medium", size: 13))
                                        .foregroundColor(Color(red: 0.16, green: 0.20, blue: 0.17))
                                    if let secondary = prediction.secondaryName {
                                        Text(secondary)
                                            .font(.custom("AvenirNext-Regular", size: 11))
                                            .foregroundColor(Color(red: 0.42, green: 0.50, blue: 0.44))
                                    }
                                }
                                Spacer()
                                Text(String(format: "%.0f%%", min(max(prediction.confidence, 0), 1) * 100))
                                    .font(.custom("AvenirNext-DemiBold", size: 11))
                                    .foregroundColor(Color(red: 0.18, green: 0.40, blue: 0.28))
                            }
                            ConfidenceBar(value: prediction.confidence)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isTop ? Color(red: 0.90, green: 0.97, blue: 0.90) : Color.clear)
                        )
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 5)
    }

    var tipsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Better results")
                .font(.custom("AvenirNext-DemiBold", size: 13))
                .foregroundColor(Color(red: 0.18, green: 0.24, blue: 0.20))
            HStack(spacing: 10) {
                tipPill(icon: "leaf", text: "Leaf close-up")
                tipPill(icon: "camera.macro", text: "Sharp focus")
                tipPill(icon: "sun.max", text: "Good light")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    func tipPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
                .font(.custom("AvenirNext-Medium", size: 12))
        }
        .foregroundColor(Color(red: 0.30, green: 0.44, blue: 0.34))
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(red: 0.93, green: 0.97, blue: 0.93))
        .clipShape(Capsule())
    }
}

private struct ConfidenceBar: View {
    let value: Float

    var body: some View {
        GeometryReader { proxy in
            let clamped = min(max(CGFloat(value), 0), 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(red: 0.90, green: 0.94, blue: 0.90))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.22, green: 0.55, blue: 0.36),
                                     Color(red: 0.12, green: 0.43, blue: 0.30)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * clamped)
            }
        }
        .frame(height: 6)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
