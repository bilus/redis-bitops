shared_examples_for "a bitmap" do |creation_method|
  let(:redis) { Redis.new }
  let(:a) { redis.send(creation_method, "rsb:a") }
  let(:b) { redis.send(creation_method, "rsb:b") }
  let(:c) { redis.send(creation_method, "rsb:c") }
  let(:result) { redis.send(creation_method, "rsb:output") }

  describe "#[]" do
    it "sets individual bits" do
      b[0] = true
      b[99] = true
      b[0].should be_true
      b[99].should be_true
    end

    it "resizes the bitmap as necessary" do
      expect { b[10_000_000] = 1 }.to_not raise_error
      b[10_000_000].should be_true
    end

    it "doesn't zeroes unset bits" do
      max_bit_pos = 5_000
      approx_percent_bits_set = 0.2

      # TODO: There are definitely faster ways to generate the data.
      Inf = 1.0/0.0 unless Kernel.const_defined? "Inf"
      set = Set.new((0..Inf).lazy.map {|i| (rand * max_bit_pos).to_i}.take(approx_percent_bits_set * max_bit_pos))

      set.each do |pos|
        b[pos] = true
      end

      set.each do |pos|
        b[pos].should be_true
      end

      (0..Inf).lazy.take(max_bit_pos).each do |pos|
        b[pos].should eq set.include?(pos)
      end
    end
  end

  describe "#bitcount" do
    it "returns the number of set bits" do
      b.bitcount.should == 0
      b[1] = true
      b[2] = true
      b[100] = true
      b.bitcount.should == 3
    end
  end

  describe "#operator &" do
    it "returns a result query that can be materialized" do
      a[0] = true
      a[1] = true
      a[2] = true
      a[100] = true
      a[110] = true

      b[0] = true
      b[100] = true

      q = a & b

      result << q
      result.bitcount.should == 2
    end

    it "allows operator nesting" do
      a[0] = true
      a[1] = true
      a[2] = true
      a[100] = true
      a[110] = true

      b[0] = true
      b[100] = true

      c[0] = true

      q = a & b & (c & a)

      result << q
      result.bitcount.should == 1
    end
  end

  describe "#operator |" do
    it "returns a result query that can be materialized" do
      a[0] = true
      a[1] = true
      a[2] = true
      a[100] = true

      b[0] = true
      b[100] = true
      b[110] = true

      q = a | b

      result << q
      result.bitcount.should == 5
    end

    it "allows operator nesting" do
      a[0] = true
      a[1] = true
      a[2] = true
      a[100] = true
      a[110] = true

      b[0] = true
      b[100] = true

      c[0] = true

      q = a | b | (c | a)

      result << q
      result.bitcount.should == 5
    end
  end

  describe "#operator ~" do
    it "returns a result query that can be materialized" do
      a[0] = true
      a[1] = true
      a[2] = true
      a[100] = true

      q = ~a

      result << q
      result[0].should be_false
      result[1].should be_false
      result[2].should be_false
      result[3].should be_true
      result[99].should be_true
      result[100].should be_false
    end

    it "allows operator nesting" do
      a[0] = true
      a[1] = true
      a[2] = true
      a[100] = true
      a[110] = true

      b[0] = true
      b[100] = true

      c[0] = true

      q = ~a | b & c

      result << q
      result[0].should be_true
      result[1].should be_false
      result[2].should be_false
      result[3].should be_true
      result[99].should be_true
      result[100].should be_false
      result[109].should be_true
      result[110].should be_false
      result[111].should be_true
    end

    # Commented out because this is how redis BITOP NOT works:
    # it pads the results to the full byte thus messing up with
    # the operation.

    # it "returns result with the correct bitcount" do
    #   pending
    #   a[0] = true
    #   a[1] = true
    #   a[2] = true
    #   a[100] = true
    #
    #   q = ~a
    #
    #   result << q
    #   result.bitcount.should == 96
    # end
  end

  describe "#operator ^" do
    it "returns a result query that can be materialized" do
      a[0] = true
      a[1] = true
      a[2] = true
      a[100] = true

      b[0] = true
      b[100] = true
      b[110] = true

      q = a ^ b

      result << q
      result.bitcount.should == 3
    end

    it "allows operator nesting" do
      a[0] = true
      a[1] = true
      a[2] = true
      a[100] = true
      a[110] = true

      b[0] = true
      b[100] = true

      c[0] = true

      q = a ^ (b ^ c)

      result << q
      result.bitcount.should == 4
    end
  end

  describe "#delete!" do
    it "removes all bitmap's keys" do
      a[0] = true
      a[10_000] = true
      a.delete!
      redis.keys("rsb:*").should be_empty
    end

    it "effectively sets all bitmap's keys to zero" do
      a[0] = true
      a[10_000] = true
      a.delete!
      a[0].should be_false
      a[10_000].should be_false
      b[0] = true
      result << (a & b)
      result.bitcount.should == 0
    end
  end

  describe "#<<" do
    before do
      a[0] = true
      a[1] = true
      a[2] = true
      a[3] = true

      b[0] = true
      b[1] = true
      b[2] = true

      c[0] = true
      c[1] = true
    end

    after do
      @temp.delete! if @temp
    end

    it "materializes an arbitrarily-complicated expression" do
      result << (a & (a & b) | c & b & a)
      result.bitcount.should == 3
    end

    it "is lazy-invoked when expression is evaluated" do
      result = (a & (a & b) | c & b & a)
      result.should be_a Redis::Bitops::Queries::BinaryOperator
      @temp = result
      result.bitcount.should == 3
    end

    it "takes into account modifications made to the result" do
      output = (a & (a & b) | c & b & a)
      output[100] = true
      @temp = output
      result << output
      result.bitcount.should == 4
    end
  end

  describe "#copy_to" do
    it "overrides the target bitmap" do
      # Fix expression with bits set using [] after evaluation doesn't materialize the newly set bits.
      result[1000] = true
      a[0] = true
      a[1] = true
      a.copy_to(result)
      result.bitcount.should == a.bitcount
      result[1000].should be_false
    end
  end
end

shared_examples_for "a bitmap factory method"  do |creation_method, bitmap_class|
  let(:redis) { Redis.new }

  after do
    @bitmap.delete! if @bitmap
  end

  it "creates a new bitmap" do
    @bitmap = redis.send(creation_method, "rsb:xxx")
    @bitmap.should be_a bitmap_class
  end

  it "doesn't add keys until the bitmap is modified" do
    @bitmap = redis.send(creation_method, "rsb:xxx")
    expect { @bitmap }.to_not change { redis.keys.size }
    expect { @bitmap[1] = true }.to change { redis.keys.size }
  end
end
