require 'forwardable'

class Redis
  module Queries
    module LazyEvaluation
      extend Forwardable
      
      def_delegators :dest, :bitcount, :[], :[]=, :<<, :delete!, :root_key
      
      def dest
        if @dest.nil?
          @dest = temp_bitmap(redis)
          optimize!
          materialize(@dest)
        end
        @dest
      end
      
      def redis
        raise "Override in the class using the module to return the redis connection."
      end
    end
  end
end