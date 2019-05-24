Pod::Spec.new do |s|
s.name             = 'HXDOCRPlugin'
s.version          = '0.1.0'
s.summary          = '身份证识别插件.'
s.homepage         = 'https://github.com/ZJKCode/HXDOCRPlugin'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'zhangjikuan' => 'k721684713@163.com' }
s.source           = { :git => 'https://github.com/ZJKCode/HXDOCRPlugin.git',:tag => s.version.to_s }
s.ios.deployment_target = '8.0'
s.resource    = 'HXDOCRPlugin/*.bundle'
s.xcconfig  = { 'OTHER_LDFLAGS' => '-lz','CLANG_CXX_LIBRARY' => 'compiler-default' }
s.requires_arc = true
s.libraries = 'c++.1','z','c++abi'
s.public_header_files = 'HXDOCRPlugin/HXDOCRPlugin.h','HXDOCRPlugin/core/*.h'
s.source_files = 'HXDOCRPlugin/HXDOCRPlugin.h','HXDOCRPlugin/core/**/*'
s.vendored_frameworks = 'HXDOCRPlugin/3rd/TesseractOCR.framework','HXDOCRPlugin/3rd/opencv2.framework'
s.frameworks = 'Foundation','UIKit', 'AVFoundation'


end

