# Offline PlantID

SwiftUI + iOS 15+ offline plant classifier using the Nature Explorer plants model.

## What you need
- macOS with Xcode 14+ installed
- An iPhone or iOS simulator
- This repo checked out locally

## Quick start
1) Open `Offline PlantID.xcodeproj` in Xcode.
2) When prompted, resolve Swift package dependencies.
3) Select a device/simulator and run.

## Model + labels (already included)
These files are bundled as app resources via `project.yml`:
- `inat_models/inat_plant.tflite`
- `inat_models/aiy_plants_V1_labelmap.csv`

## TensorFlow Lite Swift package
The project uses Swift Package Manager to pull:
- Repo: https://github.com/tensorflow/tensorflow
- Product: `TensorFlowLiteSwift`

If Xcode prompts you to resolve packages, accept the defaults.

## Regenerate the project (if needed)
If you modify `project.yml`, regenerate the Xcode project:

```sh
xcodegen
```

## Troubleshooting
- If the model fails to load, confirm the resource filenames in `Sources/ModelDataHandler.swift`.
- If you see empty predictions, confirm you picked a clear plant photo and try again.
