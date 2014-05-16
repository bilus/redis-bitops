require 'securerandom'

class Redis
  module Queries
    class BinaryOperator
      include MaterializationHelpers
      include TreeBuildingHelpers
      
      def initialize(op, lhs, rhs)
        @lhs = lhs
        @rhs = rhs
        @op = op
      end
            
      def materialize(dest)

        result = dest
        mlhs, dest_used = resolve_operand(@lhs, result)
        temp_result = temp_bitmap(dest.redis) if dest_used
        result = temp_result || dest
        mrhs, = resolve_operand(@rhs, result)
        mlhs.bitop(@op, mrhs, dest)
      ensure
        temp_result.delete! if temp_result
      end
    end
  end
end