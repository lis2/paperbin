# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'paperbin/version'

Gem::Specification.new do |spec|
  spec.name          = "paperbin"
  spec.version       = Paperbin::VERSION
  spec.authors       = ["morhekil","sameera207", "noma4i", "lis2", "halhenke", "gzzengwei"]
  spec.email         = ["kotlarek.krzysztof@gmail.com"]
  spec.description   = %q{Paperbin removes paper_trail versions and move them to filesystem}
  spec.summary       = %q{,Paperbin removes paper_trail versions and move them to filesyste}
  spec.homepage      = "https://github.com/jnsolutions/paperbin"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_runtime_dependency "sidekiq"
  spec.add_runtime_dependency "paper_trail"
  spec.add_runtime_dependency "railties", "~> 3.2"
  spec.add_runtime_dependency "activesupport", "~> 3.2"
  spec.add_runtime_dependency "zippy"
  spec.add_runtime_dependency "zip"
end
