# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'banana_peels/version'

Gem::Specification.new do |spec|
  spec.name          = "banana_peels"
  spec.version       = BananaPeels::VERSION
  spec.authors       = ["Steven Bull"]
  spec.email         = ["steven@thebulls.us"]
  spec.description   = "Interface for using MailChimp as a template repository for transactional emails. MailChimp campaigns define email content, using merge tags as placeholders for injectable content pieces."
  spec.summary       = "Interface for using MailChimp as a template repository for transactional emails."
  spec.homepage      = "https://github.com/sbull/banana_peels"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency "bundler", "~> 1.3"

  spec.add_runtime_dependency('mailchimp-api', '~> 2.0')
end
