Gem::Specification.new do |s|
  s.name        = 'redis-bitops'
  s.version     = '0.2.1'
  s.summary     = "Bitmap and sparse bitmap operations for Redis."
  s.description = "Optimized operations on Redis bitmaps using built-in Ruby operators. Supports sparse bitmaps to preserve storage."
  s.authors     = ["Martin Bilski"]
  s.email       = 'gyamtso@gmail.com'
  s.homepage    =
    'http://github.com/bilus/redis-bitops'
  s.license       = 'MIT'

  s.files = Dir['README.md', 'MIT-LICENSE', 'lib/**/*', 'spec/**/*']

  s.add_dependency 'redis'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'awesome_print'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'pry-byebug'

  s.require_path = 'lib'
end
