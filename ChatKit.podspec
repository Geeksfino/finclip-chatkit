Pod::Spec.new do |s|
  s.name             = "ChatKit"
  s.version      = "0.4.1"
  s.summary          = "Finclip conversational AI SDK for iOS."
  s.description      = <<-DESC
  ChatKit bundles the Finclip NeuronKit orchestration layer with ConvoUI components,
  enabling product teams to add agentic chat experiences to their applications.
  DESC
  s.homepage         = "https://github.com/Geeksfino/finclip-chatkit"
  s.license          = { :type => "Commercial", :file => "LICENSE" }
  s.author           = { "Finclip" => "support@finclip.com" }
  s.source           = {
    :http => "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.4.1/ChatKit.xcframework.zip"
  }
  s.vendored_frameworks = "ChatKit.xcframework"
  s.platform         = :ios, "15.0"
  s.swift_version    = "6.0"
end
