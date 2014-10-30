Pod::Spec.new do |s|
	s.name         = "libhypem"
	s.version      = "0.0.1"
	s.summary      = "libhypem is a Cocoa {iOS Library, OS X Framework} for Hype Machine."
	s.description  = <<-DESC
	The Cocoa {library, framework} for adding Hype Machine to your iOS/Mac app.
	DESC
	s.homepage     = "https://github.com/zshannon/libhypem"
	s.license      = { :type => 'MIT', :file => 'LICENSE' }
	s.author       = { "Zane Shannon" => "zane@smileslaughs.com" }
	s.social_media_url   = "http://twitter.com/zaneshannon"
	s.ios.deployment_target = '6.0'
	s.osx.deployment_target = '10.8'
	s.source       = { :git => "https://github.com/zshannon/libhypem.git", :tag => s.version }
	s.source_files  = 'libhypem/*.{h,m}'
	s.public_header_files = 'libhypem/*.h'
	s.requires_arc = true
end