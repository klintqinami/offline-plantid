import SwiftUI

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var predictions: [Prediction] = []
    @State private var isPickerPresented = false
    @State private var errorMessage: String?

    private let modelDataHandler = ModelDataHandler()

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 220)
                        .overlay(Text("Pick a plant photo"))
                }

                Button("Pick Photo") {
                    isPickerPresented = true
                }
                .buttonStyle(.borderedProminent)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                List(predictions) { prediction in
                    HStack {
                        Text(prediction.label)
                        Spacer()
                        Text(String(format: "%.2f", prediction.confidence))
                            .monospacedDigit()
                    }
                }
            }
            .padding()
            .navigationTitle("Offline PlantID")
        }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
