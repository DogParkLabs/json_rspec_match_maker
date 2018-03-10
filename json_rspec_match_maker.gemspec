
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'json_rspec_match_maker/version'

Gem::Specification.new do |spec|
  spec.name          = 'json_rspec_match_maker'
  spec.version       = JsonRspecMatchMaker::VERSION
  spec.authors       = ['Patrick McGee']
  spec.email         = ['patmcgee@dogparklabs.com']

  spec.summary       = 'Utility class for building JSON RSpec matchers.'
  spec.homepage      = 'http://www.github.com/dogparklabs/json_rspec_match_maker'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(spec)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.7.0'
  spec.add_development_dependency 'rubocop', '~> 0.52.1'
  spec.add_development_dependency 'yard', '~> 0.9.12'
  spec.add_development_dependency 'yardstick', '~> 0.9.9'
  spec.add_development_dependency 'pry'
end
