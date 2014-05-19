class Redis
  module Queries

    # A unary bitwise operator. Currently only NOT is supported by redis.
    #
    class UnaryOperator
      include MaterializationHelpers
      include TreeBuildingHelpers
        
      # Create a new bitwise operator 'op' with one argument 'arg'.
      #
      def initialize(op, arg)
        @op = op
        @arg = arg
      end
      
      # Runs the expression tree against the redis database, saving the results
      # in bitmap 'dest'.
      #
      def materialize(dest)
        temp_intermediates = []
        result, = resolve_operand(@arg, dest.redis, dest, temp_intermediates)
        result.bitop(@op, dest)
      ensure
        temp_intermediates.each(&:delete!)
      end
      
      # Optimizes the expression tree by combining operands for neighboring identical operators.
      # Because NOT operator in Redis can only accept one operand, no optimization is made
      # for the operand but the children are optimized recursively.
      #
      def optimize!(parent_op = nil)
        @arg.optimize!(@op) if @arg.respond_to?(:optimize!)
        self
      end
    end
  end
end