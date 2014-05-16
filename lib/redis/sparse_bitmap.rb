require 'redis'
require 'redis/queries/materialization_helpers'
require 'redis/queries/tree_building_helpers'
require 'redis/queries/binary_operator'
require 'redis/queries/unary_operator'

class Redis
  class SparseBitmap
    
    include Queries
    include TreeBuildingHelpers
    
    def initialize(root_key, redis)
      @redis = redis
      @root_key = root_key
    end
    
    def << (query)
      query.materialize(self)
    end
    
    def [] (pos)
      i2b(@redis.getbit(key(pos), pos))
    end
    
    def []= (pos, b)
      @redis.setbit(key(pos), pos, b2i(b))
    end
    
    def bitcount
      @redis.bitcount(@root_key)
    end
    
    def delete!
      @redis.del(@root_key)
    end
        
    def bitop(op, *bms, dest_bitmap)
      @redis.bitop(op, dest_bitmap.root_key, self.root_key, *bms.map(&:root_key))
      dest_bitmap
    end
    
    def root_key
      @root_key
    end
    
    def redis
      @redis
    end
    
    protected
    
    def key(pos)
      @root_key
    end
    
    def b2i(b)
      b ? 1 : 0
    end
    
    def i2b(i)
      i.to_i != 0 ? true : false
    end
  end
end