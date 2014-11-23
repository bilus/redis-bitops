require 'set'

class Redis
  module Bitops

    # A sparse bitmap using multiple key to store its data to save memory.
    #
    # Note: When adding new public methods, revise the LazyEvaluation module.
    #
    class SparseBitmap < Bitmap

      # Creates a new sparse bitmap stored in 'redis' under 'root_key'.
      #
      def initialize(root_key, redis, bytes_per_chunk = nil)
        @bytes_per_chunk = bytes_per_chunk || Redis::Bitops.configuration.default_bytes_per_chunk
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

        all_keys = self.chunk_keys + (operands.map(&:chunk_keys).flatten! || [])
        unique_chunk_numbers = Set.new(chunk_numbers(all_keys))

        maybe_multi(level: :bitmap, watch: all_keys) do
          unique_chunk_numbers.each do |i|
            @redis.bitop(op, result.chunk_key(i), self.chunk_key(i), *operands.map { |o| o.chunk_key(i) })
          end
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

      # Copy this bitmap to 'dest' bitmap.
      #
      def copy_to(dest)

        # Copies all source chunks to destination chunks and deletes remaining destination chunk keys.

        source_keys = self.chunk_keys
        dest_keys = dest.chunk_keys

        maybe_multi(level: :bitmap, watch: source_keys + dest_keys) do
          source_chunks = Set.new(chunk_numbers(source_keys))
          source_chunks.each do |i|
            copy(chunk_key(i), dest.chunk_key(i))
          end
          dest_chunks = Set.new(chunk_numbers(dest_keys))
          (dest_chunks - source_chunks).each do |i|
            @redis.del(dest.chunk_key(i))
          end
        end
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

      # Maybe pipeline/make atomic based on the configuration.
      #
      def maybe_multi(options = {}, &block)
        current_level = options[:level] or raise "Specify the current transaction level."

        if Redis::Bitops.configuration.transaction_level == current_level
          watched_keys = options[:watch]
          @redis.watch(watched_keys) if watched_keys && watched_keys != []
          @redis.multi(&block)
        else
          block.call
        end
      end

    end
  end
end
