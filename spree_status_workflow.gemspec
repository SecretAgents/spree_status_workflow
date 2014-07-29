# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_status_workflow'
  s.version     = '1.0.4'
  s.summary     = 'New status workflow in spree'
  s.required_ruby_version = '>= 1.8.7'

  s.author            = 'Rigor'
  s.email             = 'in@isfb.ru'

  #s.files         = `git ls-files`.split("\n")
  s.files        = Dir['lib/**/*', 'app/**/*', 'db/**/*', 'config/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '>= 1.1.3'
end
