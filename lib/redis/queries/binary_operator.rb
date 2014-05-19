require 'securerandom'

class Redis
  module Queries
    
    # Binary bitwise operator.
    #
    class BinaryOperator
      include MaterializationHelpers
      include TreeBuildingHelpers
     
      # Creates a bitwise operator 'op' with left-hand operand, 'lhs', and right-hand operand, 'rhs'.
      #
      def initialize(op, lhs, rhs)
        @args = [lhs, rhs]
        @op = op
      end
      
      # Runs the expression tree against the redis database, saving the results
      # in bitmap 'dest'.
      #
      def materialize(dest)
        # Resolve lhs and rhs operand, using 'dest' to store intermediate result so
        # a maximum of one temporary Bitmap has to be created.
        # Then apply the bitwise operator storing the final result in 'dest'.
        redis = dest.redis
        intermediate = dest
        
        lhs, *other_args = @args
        temp_intermediates = []
        
        # Side-effects: if a temp intermediate bitmap is created, it's added to 'temp_intermediates'.
        lhs_operand, intermediate = resolve_operand(lhs, redis, intermediate, temp_intermediates) # Side-effect possible. 
        other_operands, *_ = other_args.inject([[], intermediate]) do |(operands, intermediate), arg|
          operand, intermediate = resolve_operand(arg, redis, intermediate, temp_intermediates) # Side-effect possible.
          [operands << operand, intermediate]
        end
        
        lhs_operand.bitop(@op, *other_operands, dest)
      ensure
        temp_intermediates.each(&:delete!)
      end
      
      # Recursively optimizes the expression tree by combining operands for neighboring identical
      # operators, so for instance a & b & c ultimately becomes BITOP :and dest a b c as opposed 
      # to running two separate BITOP commands.
      #
      def optimize!(parent_op = nil)
        @args.map! { |arg| arg.respond_to?(:optimize!) ? arg.optimize!(@op) : arg }.flatten!
        if parent_op == @op
          @args
        else
          self
        end
      end
    end
  end
end