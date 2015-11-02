Pod::Spec.new do |s|
  s.name             = "SuperMock"
  s.version          = "0.1.0"
  s.summary          = "A very simple yet powerful UI and Unit testing mock framework for API calls. It lives in your app and is completely offline."

  s.description      = <<-DESC
	A very simple yet powerful UI and Unit testing mock framework for API calls. It lives in your app and is completely offline. Setup your mocks at the start rather than on a per test basis. More description TBC.
                       DESC

  s.homepage         = "https://github.com/michaelarmstrong/SuperMock"
  s.license          = 'MIT'
  s.author           = { "Michael Armstrong" => "@ArmstrongAtWork" }
  s.source           = { :git => "https://github.com/michaelarmstrong/SuperMock.git", :tag => s.version.to_s }
   s.social_media_url = 'https://twitter.com/ArmstrongAtWork'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'SuperMock' => ['Pod/Assets/*.png']
  }

end
