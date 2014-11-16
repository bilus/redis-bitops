require 'forwardable'

class Redis
  module Bitops
    module Queries

      # Support for materializing expressions when one of the supported bitmap methods is called.
      #
      # Example
      #
      #   a = $redis.sparse_bitmap("a")
      #   b = $redis.sparse_bitmap("b")
      #   a[0] = true
      #   result = a | b
      #   puts result[0] => true
      #
      module LazyEvaluation
        extend Forwardable

        def_delegators :dest, :bitcount, :[], :[]=, :<<, :delete!, :root_key

        def dest
          if @dest.nil?
            @dest = temp_bitmap
            do_evaluate(@dest)
          end
          @dest
        end

        # Optimizes the expression and materializes it into bitmap 'dest'.
        #
        def evaluate(dest_bitmap)
          if @dest
            @dest.copy_to(dest_bitmap)
          else
            do_evaluate(dest_bitmap)
          end
        end

        protected def do_evaluate(dest_bitmap)
          optimize!
          materialize(dest_bitmap)
        end
      end
    end
  end
end
