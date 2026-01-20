# Offline PlantID (SwiftUI + iOS 15+)

This repo already contains a generated Xcode project and all required resources. Use this guide if you want to rebuild the project or understand how it is wired.

## Build from the existing project
1) Run `pod install` in the repo root.
2) Open `Offline PlantID.xcworkspace` in Xcode.
3) Run on a device or simulator.

## Project layout
- `Sources/`: SwiftUI app code
- `inat_models/`: TFLite model + labels
- `project.yml`: XcodeGen project definition

## Rebuild the Xcode project (optional)
If you change `project.yml`, regenerate the project with XcodeGen:

```sh
xcodegen
```

## CocoaPods dependency
This project uses CocoaPods for TensorFlow Lite. If you modify the `Podfile`, rerun:

```sh
pod install
```

## Model + labels
These files must be included in the app bundle:
- `inat_models/aiy_plants_V1_labelmap.csv`
- `inat_models/inat_plant.tflite`

## Run
Build and run on a device or simulator. Tap "Pick Photo" and you should see the top-5 predictions.

If results look wrong, check model input normalization in `Sources/ImagePreprocessor.swift`.
