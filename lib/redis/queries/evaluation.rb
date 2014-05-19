class Redis
  module Queries
    
    # Evaluation of expression trees.
    #
    module Evaluation
      
      # Optimizes the expression and materializes it into bitmap 'dest'.
      #
      def evaluate(dest)
        optimize!
        materialize(dest)
      end
    end
  end
end