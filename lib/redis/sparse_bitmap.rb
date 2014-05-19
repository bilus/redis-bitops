require 'redis'
require 'redis/queries/materialization_helpers'
require 'redis/queries/tree_building_helpers'
require 'redis/queries/lazy_evaluation'
require 'redis/queries/binary_operator'
require 'redis/queries/unary_operator'
require 'redis/bitmap'
require 'set'

class Redis
  
  # Creates a new sparse bitmap storing data in n chunks to conserve memory.
  #
  def sparse_bitmap(key, bytes_per_chunk = nil)
    SparseBitmap.new(key, self, bytes_per_chunk)
  end
  
  # A sparse bitmap using multiple key to store its data to save memory.
  #
  # Note: When adding new public methods, revise the LazyEvaluation module.
  #
  class SparseBitmap < Bitmap
    
    DEFAULT_BYTES_PER_CHUNK = 4096
    
    # Creates a new sparse bitmap stored in 'redis' under 'root_key'.
    #
    def initialize(root_key, redis, bytes_per_chunk = nil)
      @bytes_per_chunk = bytes_per_chunk || DEFAULT_BYTES_PER_CHUNK
      super(root_key, redis)
    end
    
    # Returns the number of set bits.
    #
    def bitcount
      chunk_keys.map { |key| @redis.bitcount(key) }.reduce(:+) || 0
    end
     
    # Deletes the bitmap and all its keys.
    #
    def delete!
      chunk_keys.each do |key|
        @redis.del(key)
      end
      super
    end
     
    # Redis BITOP operator 'op' (one of :and, :or, :xor or :not) on operands
    # (bitmaps). The result is stored in 'result'.
    #
    def bitop(op, *operands, result)
      # TODO: Optimization is possible for AND. We can use an intersection of each operand
      # chunk numbers to minimize the number of database accesses.
      
      unique_chunk_numbers = operands.inject(Set.new(chunk_numbers(self.chunk_keys))) { |set, o| 
        set.merge(chunk_numbers(o.chunk_keys)) 
      }
      unique_chunk_numbers.each do |i|
        @redis.bitop(op, result.chunk_key(i), self.chunk_key(i), *operands.map { |o| o.chunk_key(i) })
      end
      result
    end

    def chunk_keys
      @redis.keys("#{@root_key}:chunk:*")
    end
    
    def chunk_key(i)
      "#{@root_key}:chunk:#{i}"
    end

    # Returns lambda creating SparseBitmap objects using @redis as the connection.
    #
    def bitmap_factory
      lambda { |key| @redis.sparse_bitmap(key, @bytes_per_chunk) }
    end

    protected
    
    def bits_per_chunk
      @bytes_per_chunk * 8
    end
    
    def key(pos)
      chunk_key(chunk_number(pos))
    end
   
    def offset(pos)
      pos.modulo bits_per_chunk
    end
    
    def chunk_number(pos) 
      (pos / bits_per_chunk).to_i
    end

    def chunk_numbers(keys)
      keys.map { |key| key.split(":").last.to_i }
    end
  end
end