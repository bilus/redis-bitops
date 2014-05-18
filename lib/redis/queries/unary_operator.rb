class Redis
  module Queries
    class UnaryOperator
      include MaterializationHelpers
      include TreeBuildingHelpers
      
      def initialize(op, arg)
        @op = op
        @arg = arg
      end
      
      def optimize!(parent_op = nil)
        @arg.optimize!(@op) if @arg.respond_to?(:optimize!)
        self
      end
      
      def materialize(dest)
        temp_intermediates = []
        result, = resolve_operand(@arg, dest.redis, dest, temp_intermediates)
        result.bitop(@op, dest)
      ensure
        temp_intermediates.each(&:delete!)
      end
    end
  end
end