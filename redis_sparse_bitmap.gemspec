Gem::Specification.new do |s|
  s.name        = 'redis_sparse_bitmap'
  s.version     = '0.0.1'
  s.date        = '2015-05-16'
  s.summary     = "Redis sparse bitmaps"
  s.description = "Redis sparse bitmaps"
  s.authors     = ["Martin Bilski"]
  s.email       = 'gyamtso@gmail.com'
  s.homepage    =
    'http://github.com/bilus/redis_sparse_bitmap'
  s.license       = 'MIT'

  s.files = Dir['README.md', 'MIT-LICENSE', 'lib/**/*', 'spec/**/*']
  s.has_rdoc = false
  
  s.add_dependency 'redis'
  s.add_dependency 'hiredis'
  
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'awesome_print'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'pry-byebug'

  s.require_path = 'lib'
end