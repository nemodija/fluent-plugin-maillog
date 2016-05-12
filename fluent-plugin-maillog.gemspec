# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-maillog"
  spec.version       = "0.0.1"
  spec.authors       = ["nemonium"]
  spec.email         = ["kenichiro.nemoto@gmail.com"]
  spec.summary       = %q{Summarizing maillog.}
  spec.description   = %q{Summarizing maillog.}
  spec.homepage      = "https://github.com/nemonium/fluent-plugin-maillog"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "10.4.2"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "timecop"
  spec.add_runtime_dependency "fluentd"
end
