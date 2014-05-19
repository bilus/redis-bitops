require 'redis'
require 'redis/queries/materialization_helpers'
require 'redis/queries/tree_building_helpers'
require 'redis/queries/binary_operator'
require 'redis/queries/unary_operator'

class Redis
  
  # Creates a new sparse bitmap storing data in n chunks to conserve memory.
  #
  def sparse_bitmap(key)
    SparseBitmap.new(key, self)
  end
  
  # A sparse bitmap using multiple key to store its data to save memory.
  #
  class SparseBitmap
    
    include Queries
    include TreeBuildingHelpers # See for a list of supported operators.
    
    # Creates a new sparse bitmap stored in 'redis' under 'root_key'.
    #
    def initialize(root_key, redis)
      @redis = redis
      @root_key = root_key
    end
    
    # Saves the result of the query in the bitmap.
    #
    def =~ (query)
      query.optimize!
      query.materialize(self)
    end
    
    # Reads bit at position 'pos' returning a boolean.
    #
    def [] (pos)
      i2b(@redis.getbit(key(pos), pos))
    end
    
    # Sets bit at position 'pos' to 1 or 0 based on the boolean 'b'.
    #
    def []= (pos, b)
      @redis.setbit(key(pos), pos, b2i(b))
    end
    
    # Returns the number of set bits.
    #
    def bitcount
      @redis.bitcount(@root_key)
    end
    
    # Deletes the bitmap and all its keys.
    #
    def delete!
      @redis.del(@root_key)
    end
     
    # Redis BITOP operator 'op' (one of :and, :or, :xor or :not) on operands
    # (bitmaps). The result is stored in 'result'.
    #
    def bitop(op, *operands, result)
      @redis.bitop(op, result.root_key, self.root_key, *operands.map(&:root_key))
      result
    end

    # The key the bitmap is stored under.
    #
    def root_key
      @root_key
    end
    
    # The redis connection.
    #
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