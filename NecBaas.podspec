Pod::Spec.new do |s|
  s.name         = "NecBaas"
  s.version      = "7.5.0"
  s.summary      = "NEC Mobile Backend Platform iOS SDK"
  s.description  = <<-DESC
    NEC Mobile Backend Platform iOS SDK.
                   DESC
  s.homepage     = "https://github.com/nec-baas/baas-client-ios"
  s.license      = { :type => "BSD", :file => "LICENSE" }
  s.author       = "NEC Corporation"
  s.platform     = :ios
  # s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/nec-baas/baas-client-ios.git", :tag => "#{s.version}" }

  s.source_files  = "nebulaIosSdk/**/*.{h,m}"
  s.public_header_files = "nebulaIosSdk/Headers/*.h"
end
