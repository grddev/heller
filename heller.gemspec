# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'heller'
  s.version     = '0.1.0'
  s.platform    = 'java'
  s.authors     = ['Mathias Söderberg']
  s.email       = ['mathias.soederberg@gmail.com']
  s.homepage    = 'http://github.com/mthssdrbrg/heller'
  s.summary     = %q{JRuby wrapper for Kafka}
  s.description = %q{Attempts to make Kafka's Java API fit a bit better with Ruby}

  s.rubyforge_project = 'heller'
  
  s.add_dependency 'kafka-jars', '~> 0.8.0.pre0'

  s.files         = Dir['lib/**/*']
  s.require_paths = %w(lib)
end
