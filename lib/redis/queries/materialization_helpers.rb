class Redis
  module Queries
    
    # Helpers for materialization, i.e. running a BITOP command or, possibly, another command
    # and saving its results to a Redis database in 'intermediate'.
    #
    module MaterializationHelpers
      
      # Materializes the operand 'o' saving the result in 'redis'.
      # If the operand can be materialized, it does so storing the result in 'intermediate'
      # unless the latter is nil. In that case, a temp intermediate bitmap is created to hold 
      # the result (and the bitmap is added to 'temp_intermediates').
      #
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
      
      # Creates a temp bitmap in 'redis'.
      #
      def temp_bitmap(redis)
        SparseBitmap.new(unique_key, redis)
      end
      
      # Generates a random unique key. 
      # TODO: The key _should_ be unique and not repeat in the 
      # database but this isn't guaranteed but considering the intended
      # usage to create temporary intermediate bitmaps while materializing
      # queries, it should be sufficient.
      #
      def unique_key
        "redis_sparse_bitmap:#{SecureRandom.hex(20)}"
      end
    end
  end
end