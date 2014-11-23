class Redis
  module Bitops
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
        def resolve_operand(o, intermediate, temp_intermediates)
          if o.respond_to?(:materialize)
            if intermediate.nil?
              new_intermediate = temp_bitmap
              temp_intermediates << new_intermediate
            end
            intermediate ||= new_intermediate
            o.materialize(intermediate)
            [intermediate, nil]
          else
            [o, intermediate]
          end
        end

        # Creates a temp bitmap.
        #
        def temp_bitmap
          bitmap = bitmap_factory.call(unique_key)
          bitmap
        end

        # Generates a random unique key.
        #
        # TODO: The key _should_ be unique and not repeat in the
        # database but this isn't guaranteed. Considering the intended usage though
        # (creation of temporary intermediate bitmaps while materializing
        # queries), it should be sufficient.
        #
        def unique_key
          "redis:bitops:#{SecureRandom.hex(20)}"
        end

        def bitmap_factory
          raise "Override in the class using the module to return the bitmap factory."
        end
      end
    end
  end
end
