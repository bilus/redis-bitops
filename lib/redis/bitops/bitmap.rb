class Redis
  module Bitops

    # A sparse bitmap using multiple key to store its data to save memory.
    #
    # Note: When adding new public methods, revise the LazyEvaluation module.
    #
    class Bitmap

      include Queries
      include TreeBuildingHelpers # See for a list of supported operators.

      # Creates a new regular Redis bitmap stored in 'redis' under 'root_key'.
      #
      def initialize(root_key, redis)
        @redis = redis
        @root_key = root_key
      end

      # Saves the result of the query in the bitmap.
      #
      def << (query)
        query.evaluate(self)
      end

      # Reads bit at position 'pos' returning a boolean.
      #
      def [] (pos)
        i2b(@redis.getbit(key(pos), offset(pos)))
      end

      # Sets bit at position 'pos' to 1 or 0 based on the boolean 'b'.
      #
      def []= (pos, b)
        @redis.setbit(key(pos), offset(pos), b2i(b))
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

      # Returns lambda creating Bitmap objects using @redis as the connection.
      #
      def bitmap_factory
        lambda { |key| @redis.bitmap(key) }
      end

      # Copy this bitmap to 'dest' bitmap.
      #
      def copy_to(dest)
        copy(root_key, dest.root_key)
      end

      protected

      def key(pos)
        @root_key
      end

      def offset(pos)
        pos
      end

      def b2i(b)
        b ? 1 : 0
      end

      def i2b(i)
        i.to_i != 0 ? true : false
      end

      COPY_SCRIPT =
        <<-EOS
          redis.call("DEL", KEYS[2])
          if redis.call("EXISTS", KEYS[1]) == 1 then
            local val = redis.call("DUMP", KEYS[1])
            redis.call("RESTORE", KEYS[2], 0, val)
          end
        EOS
      def copy(source_key, dest_key)
        @redis.eval(COPY_SCRIPT, [source_key, dest_key])
      end
    end
  end
end
