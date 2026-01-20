import SwiftUI

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var predictions: [Prediction] = []
    @State private var isPickerPresented = false
    @State private var errorMessage: String?
    @State private var isTipsPresented = false
    @State private var history: [HistoryEntry] = []
    @State private var undoItem: UndoItem?

    private let modelDataHandler = ModelDataHandler()

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                photoCard
                actionRow
                resultCard
                historyCard
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
        .sheet(isPresented: $isTipsPresented) {
            TipsView()
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

        let thumbnail = ImagePreprocessor.resized(image, to: CGSize(width: 96, height: 96))

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let results = try handler.runModel(on: image, topK: 5)
                DispatchQueue.main.async {
                    predictions = results
                    if let top = results.max(by: { $0.confidence < $1.confidence }) {
                        history.insert(
                            HistoryEntry(
                                thumbnail: thumbnail,
                                displayName: top.displayName,
                                secondaryName: top.secondaryName,
                                confidence: top.confidence
                            ),
                            at: 0
                        )
                        if history.count > 20 {
                            history.removeLast(history.count - 20)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func scheduleUndo(_ item: UndoItem) {
        undoItem = item
    }

    private func handleUndo(_ item: UndoItem) {
        switch item.action {
        case .delete(let entry, let index):
            let safeIndex = min(max(index, 0), history.count)
            history.insert(entry, at: safeIndex)
        case .clear(let entries):
            history = entries
        }
        undoItem = nil
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
                HStack(spacing: 10) {
                    Button {
                        isTipsPresented = true
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.18, green: 0.40, blue: 0.28))
                            .padding(8)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    }
                    .accessibilityLabel("Tips")

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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var photoCard: some View {
        let cardHeight: CGFloat = selectedImage == nil ? 140 : 180
        return ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(selectedImage == nil ? Color.white.opacity(0.9) : Color.clear)
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: cardHeight)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.35, green: 0.55, blue: 0.38))
                    Text("Pick a plant photo")
                        .font(.custom("AvenirNext-DemiBold", size: 13))
                        .foregroundColor(Color(red: 0.28, green: 0.35, blue: 0.30))
                    Text("Leaf close-up or flower helps")
                        .font(.custom("AvenirNext-Regular", size: 10))
                        .foregroundColor(Color(red: 0.40, green: 0.48, blue: 0.42))
                }
            }
        }
        .frame(height: cardHeight)
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

    var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("History")
                    .font(.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundColor(Color(red: 0.18, green: 0.24, blue: 0.20))
                Spacer()
                HStack(spacing: 10) {
                    if let undoItem {
                        Button("Undo") {
                            handleUndo(undoItem)
                        }
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                        .foregroundColor(Color(red: 0.20, green: 0.45, blue: 0.32))
                    }
                    if !history.isEmpty {
                        Button("Clear") {
                            let previous = history
                            history.removeAll()
                            scheduleUndo(UndoItem(message: "History cleared", action: .clear(entries: previous)))
                        }
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundColor(Color(red: 0.35, green: 0.48, blue: 0.40))
                    }
                }
            }

            if history.isEmpty {
                Text("No recent results yet.")
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(Color(red: 0.45, green: 0.52, blue: 0.46))
            } else {
                List {
                    ForEach(history) { entry in
                        HStack(alignment: .center, spacing: 10) {
                            if let thumbnail = entry.thumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.displayName)
                                    .font(.custom("AvenirNext-Medium", size: 12))
                                    .foregroundColor(Color(red: 0.16, green: 0.20, blue: 0.17))
                                if let secondary = entry.secondaryName {
                                    Text(secondary)
                                        .font(.custom("AvenirNext-Regular", size: 10))
                                        .foregroundColor(Color(red: 0.42, green: 0.50, blue: 0.44))
                                }
                            }
                            Spacer()
                            Text(String(format: "%.0f%%", min(max(entry.confidence, 0), 1) * 100))
                                .font(.custom("AvenirNext-DemiBold", size: 11))
                                .foregroundColor(Color(red: 0.18, green: 0.40, blue: 0.28))
                        }
                        .frame(minHeight: 52)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                let index = history.firstIndex { $0.id == entry.id } ?? 0
                                history.removeAll { $0.id == entry.id }
                                scheduleUndo(UndoItem(message: "Item deleted", action: .delete(entry: entry, index: index)))
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: min(CGFloat(history.count) * 64, 240))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

private struct HistoryEntry: Identifiable {
    let id = UUID()
    let thumbnail: UIImage?
    let displayName: String
    let secondaryName: String?
    let confidence: Float
    let timestamp = Date()
}

private struct UndoItem: Identifiable {
    let id = UUID()
    let message: String
    let action: UndoAction
}

private enum UndoAction {
    case delete(entry: HistoryEntry, index: Int)
    case clear(entries: [HistoryEntry])
}

private struct UndoBanner: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.custom("AvenirNext-Medium", size: 12))
                .foregroundColor(.white)
            Spacer()
            Button("Undo") {
                onUndo()
            }
            .font(.custom("AvenirNext-DemiBold", size: 12))
            .foregroundColor(Color(red: 0.90, green: 0.97, blue: 0.90))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(red: 0.12, green: 0.24, blue: 0.18).opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 6)
    }
}

private struct TipsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Better results")
                .font(.custom("AvenirNext-DemiBold", size: 18))
                .foregroundColor(Color(red: 0.18, green: 0.24, blue: 0.20))

            Text("Use a leaf close-up, sharp focus, and good light. If possible, capture the flower and the whole plant for more accurate results.")
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(Color(red: 0.35, green: 0.42, blue: 0.36))

            HStack(spacing: 10) {
                tipPill(icon: "leaf", text: "Leaf close-up")
                tipPill(icon: "camera.macro", text: "Sharp focus")
                tipPill(icon: "sun.max", text: "Good light")
            }

            Spacer()
        }
        .padding(20)
    }

    private func tipPill(icon: String, text: String) -> some View {
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
