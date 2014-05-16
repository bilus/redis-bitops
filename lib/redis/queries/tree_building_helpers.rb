class Redis
  module Queries
    module TreeBuildingHelpers
      def & (rhs)
        BinaryOperator.new(:and, self, rhs)
      end
      
      def | (rhs)
        BinaryOperator.new(:or, self, rhs)
      end
      
      def ^ (rhs)
        BinaryOperator.new(:xor, self, rhs)
      end
      
      def ~
        UnaryOperator.new(:not, self)
      end
    end
  end
end