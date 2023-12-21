# frozen_string_literal: true

require_relative 'lib/ffmpeg/version'

Gem::Specification.new do |s|
  s.name        = 'ffmpeg'
  s.version     = FFMPEG::VERSION
  s.authors     = ['Rackfish AB']
  s.email       = ['support@rackfish.com', 'bikeath1337.com']
  s.homepage    = 'http://github.com/streamio/streamio-ffmpeg'
  s.summary     = 'Wraps ffmpeg to read metadata and transcodes videos.'

  s.files = Dir.glob('lib/**/*') + %w[README.md LICENSE CHANGELOG]

  s.add_dependency('multi_json', '~> 1.8')

  s.add_development_dependency('rspec', '~> 3')
  s.add_development_dependency('rake', '~> 13.1')
  s.add_development_dependency('webrick', '~> 1.8')
end
