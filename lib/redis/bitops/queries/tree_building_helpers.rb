class Redis
  module Bitops
    module Queries
      # Helpers for expression tree building.
      #
      # Add new logical operators here as/if they become supported by Redis' BITOP command.
      #
      module TreeBuildingHelpers

        # Logical AND operator.
        #
        def & (rhs)
          BinaryOperator.new(:and, self, rhs)
        end

        # Logical OR operator.
        #
        def | (rhs)
          BinaryOperator.new(:or, self, rhs)
        end

        # Logical XOR operator.
        #
        def ^ (rhs)
          BinaryOperator.new(:xor, self, rhs)
        end

        # Logical NOT operator.
        #
        # IMPORTANT: It inverts bits padding with zeroes till the nearest byte boundary.
        # It means that setting the left-most bit to 1 and inverting will result in 01111111 not 0.
        #
        # Corresponding Redis commands:
        #
        # SETBIT "a" 0 1
        # BITOP NOT "b" "a"
        # BITCOUNT "b"
        # => (integer) 7
        #
        def ~
          UnaryOperator.new(:not, self)
        end
      end
    end
  end
end
