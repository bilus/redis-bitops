require 'forwardable'

class Redis
  module Queries
    module LazyEvaluation
      extend Forwardable
      
      def_delegators :dest, :bitcount, :[], :[]=, :<<, :delete!, :root_key
      
      def dest
        if @dest.nil?
          @dest = temp_bitmap
          optimize!
          materialize(@dest)
        end
        @dest
      end
    end
  end
end