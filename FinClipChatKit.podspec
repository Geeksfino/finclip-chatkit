Pod::Spec.new do |s|
  s.name             = "FinClipChatKit"
  s.version      = "0.9.15"
  s.summary          = "Finclip conversational AI SDK for iOS."
  s.description      = <<-DESC
  ChatKit bundles the Finclip NeuronKit orchestration layer with ConvoUI components,
  enabling product teams to add agentic chat experiences to their applications.
  DESC
  s.homepage         = "https://github.com/Geeksfino/finclip-chatkit"
  s.license          = { :type => "Commercial", :file => "LICENSE" }
  s.author           = { "Finclip" => "support@finclip.com" }
  s.source           = {
    :http => "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.15/FinClipChatKit-bundled-v0.9.15.zip"
  }
    # Bundled XCFrameworks (self-contained CocoaPods distribution)
  s.vendored_frameworks = [
    "FinClipChatKit.xcframework",
    "NeuronKit.xcframework",
    "ConvoUI.xcframework",
    "SandboxSDK.xcframework",
    "convstorelib.xcframework"
  ]
  s.platform         = :ios, "15.0"
  s.swift_version    = "6.0"
end
