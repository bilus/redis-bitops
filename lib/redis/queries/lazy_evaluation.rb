require 'forwardable'

class Redis
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
          evaluate(@dest)
        end
        @dest
      end
    end
  end
end