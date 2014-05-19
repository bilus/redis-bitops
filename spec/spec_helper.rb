$: << "../../lib"

require 'redis/bitops'

require_relative './support/bitmap_examples'

require 'pry'
require 'awesome_print'

RSpec.configure do |config|
  config.after(:each, redis_cleanup: true) do
    key_prefix = example.metadata[:redis_key_prefix] or raise "Specify the key prefix using RSpec metadata (e.g. redis_key_prefix: 'rsb:')."
    keys = redis.keys("#{key_prefix}*")
    redis.del(*keys) unless keys.empty?
  end
end