require 'securerandom'

class Redis
  module Queries
    class BinaryOperator
      include MaterializationHelpers
      include TreeBuildingHelpers
      
      def initialize(op, lhs, rhs)
        @args = [lhs, rhs]
        @op = op
      end
      
      def materialize(dest)
        # Resolve lhs and rhs operand, using 'dest' to store intermediate result so
        # a maximum of one temporary Bitmap has to be created.
        # Then apply the bitwise operator storing the final result in 'dest'.
        redis = dest.redis
        intermediate = dest
        
        lhs, *other_args = @args
        temp_intermediates = []
        
        lhs_operand, intermediate = resolve_operand(lhs, redis, intermediate, temp_intermediates)
        
        other_operands, *_ = other_args.inject([[], intermediate]) do |(operands, intermediate), arg|
          operand, intermediate = resolve_operand(arg, redis, intermediate, temp_intermediates)
          [operands << operand, intermediate]
        end
        lhs_operand.bitop(@op, *other_operands, dest)
      ensure
        temp_intermediates.each(&:delete!)
      end
      
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