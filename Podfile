platform :ios, '15.0'

use_frameworks!

# CocoaPods analytics sends network stats. Keep it off for faster builds.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

target 'Offline PlantID' do
  pod 'TensorFlowLiteSwift'
end

post_install do |installer|
  model_file = installer.sandbox.root + 'TensorFlowLiteSwift/tensorflow/lite/swift/Sources/Model.swift'
  next unless File.exist?(model_file)

  File.chmod(0644, model_file) unless File.writable?(model_file)
  contents = File.read(model_file)
  patched = contents.gsub(
    'self.cModel = modelData.withUnsafeBytes { TfLiteModelCreate($0, modelData.count) }',
    <<~'SWIFT'.strip
      self.cModel = modelData.withUnsafeBytes { buffer -> CModel? in
        guard let base = buffer.baseAddress else { return nil }
        return TfLiteModelCreate(base, modelData.count)
      }
    SWIFT
  )

  File.write(model_file, patched) if patched != contents
end
