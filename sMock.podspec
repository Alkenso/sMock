Pod::Spec.new do |spec|
  spec.name         = "sMock"
  spec.version      = "1.1.0"
  spec.summary      = "Swift mock-helping library written with gMock (C++) library approach in mind"
  spec.description  = <<-DESC
                   Swift mock-helping library written with gMock (C++) library approach in mind;
                   uses XCTestExpectations inside, that makes sMock not only mocking library, but also library that allows easy unit-test coverage of mocked objects expected behavior;
                   lightweight and zero-dependecy;
                   works out-of-the-box without need of generators, tools, etc;
                   required minimum of additional code to prepare mocks.
                   DESC
  spec.homepage     = "https://github.com/Alkenso/sMock"
  spec.license      = "MIT"
  spec.author             = { "Vladimir Alkenso" => "alkensox@gmail.com" }
  spec.source       = { :git => "https://github.com/spin-org/sMock.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/sMock/**/*.swift"
  spec.swift_versions = '5.0'

  spec.platform = :ios, '11.0'
  spec.framework = 'XCTest'
end
