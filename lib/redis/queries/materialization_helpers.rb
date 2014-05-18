class Redis
  module Queries
    module MaterializationHelpers
      def resolve_operand(o, redis, intermediate, temp_intermediates)
        if o.respond_to?(:materialize)
          if intermediate.nil?
            new_intermediate = temp_bitmap(redis) 
            temp_intermediates << new_intermediate
          end
          intermediate ||= new_intermediate
          o.materialize(intermediate)
          [intermediate, nil]
        else
          [o, intermediate]
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