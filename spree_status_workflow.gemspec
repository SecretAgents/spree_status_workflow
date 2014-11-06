# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_status_workflow'
  s.version     = '2.0'
  s.summary     = 'Custom status workflow for spree'
  s.required_ruby_version = '>= 2.0.0'

  s.author            = 'Gennady Novoselov'
  s.email             = 'gn@isfb.ru'

  #s.files         = `git ls-files`.split("\n")
  s.files        = Dir['lib/**/*', 'app/**/*', 'db/**/*', 'config/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '>= 2.3'
end