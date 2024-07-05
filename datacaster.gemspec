require_relative 'lib/datacaster/version'

Gem::Specification.new do |spec|
  spec.name          = 'datacaster'
  spec.version       = Datacaster::VERSION
  spec.authors       = ['Eugene Zolotarev']
  spec.email         = ['eugzol@gmail.com']

  spec.summary       = %q{Run-time type checker and transformer for Ruby}
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.1')

  spec.metadata['source_code_uri'] = 'https://github.com/EugZol/datacaster'
  spec.homepage    = 'https://github.com/EugZol/datacaster'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'activemodel', '>= 5.2'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'i18n', '~> 1.14'
  spec.add_development_dependency 'dry-monads', '>= 1.3', '< 1.4'

  spec.add_runtime_dependency 'zeitwerk', '>= 2', '< 3'
end
