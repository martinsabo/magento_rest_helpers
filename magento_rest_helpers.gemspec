# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'magento_rest_helpers/version'

Gem::Specification.new do |spec|
  spec.name          = "magento_rest_helpers"
  spec.version       = MagentoRestHelpers::VERSION
  spec.authors       = ["Martin Sabo"]
  spec.email         = ["martin.sabo@pymutan.com"]
  spec.description   = %q{Standard integration/export utilities related to everyday Magento routine.}
  spec.summary       = %q{Collection of helpers using data from magento rest api for export to 3rd party services.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "oauth"
  spec.add_dependency "rest_client"
  spec.add_dependency "nokogiri"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "sinatra"

end