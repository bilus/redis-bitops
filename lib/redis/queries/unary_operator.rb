class Redis
  module Queries
    class UnaryOperator
      include MaterializationHelpers
      include TreeBuildingHelpers
      
      def initialize(op, bm)
        @op = op
        @bm = bm
      end
      
      def materialize(dest)
        result, = resolve_operand(@bm, dest)
        result.bitop(@op, dest)
      end
    end
  end
end