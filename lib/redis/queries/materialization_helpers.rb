class Redis
  module Queries
    module MaterializationHelpers
      def resolve_operand(o, result)
        if o.respond_to?(:materialize)
          o.materialize(result)
          [result, true]
        else
          [o, false]
        end
      end
      
      def temp_bitmap(redis)
        SparseBitmap.new(unique_key, redis)
      end
      
      def unique_key
        "redis_sparse_bitmap:#{SecureRandom.hex(20)}"
      end
    end
  end
end