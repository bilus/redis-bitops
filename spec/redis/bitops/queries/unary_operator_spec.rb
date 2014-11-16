require 'spec_helper'

describe Redis::Bitops::Queries::UnaryOperator do
  let(:a) { double("a") }
  let(:b) { double("b") }
  let(:c) { double("c") }
  let(:d) { double("d") }
  let(:e) { double("e") }

  let(:redis) { double("redis", del: nil) }
  let(:result) { double("result", redis: redis) }

  it "optimizes the expression tree" do
    a.should_receive(:bitop).with(:and, result, d, e, result)
    b.should_receive(:bitop).with(:or, c, result)
    result.should_receive(:bitop).with(:not, result)
    expr =
      Redis::Bitops::Queries::UnaryOperator.new(:not,
        Redis::Bitops::Queries::BinaryOperator.new(:and,
          a,
          Redis::Bitops::Queries::BinaryOperator.new(:and,
            Redis::Bitops::Queries::BinaryOperator.new(:or, b, c),
            Redis::Bitops::Queries::BinaryOperator.new(:and, d, e))))
    expr.optimize!
    expr.materialize(result)
  end
end
