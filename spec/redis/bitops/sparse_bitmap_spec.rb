require 'spec_helper'

describe Redis::Bitops::SparseBitmap, redis_cleanup: true, redis_key_prefix: "rsb:" do
  it_should_behave_like "a bitmap", :sparse_bitmap

  let(:redis) { Redis.new }
  let(:bytes_per_chunk) { 4 }
  let(:bits_per_chunk) { bytes_per_chunk * 8 }
  let(:a) { redis.sparse_bitmap("rsb:a", bytes_per_chunk) }
  let(:b) { redis.sparse_bitmap("rsb:b", bytes_per_chunk) }
  let(:c) { redis.sparse_bitmap("rsb:c", bytes_per_chunk) }
  let(:empty) { redis.sparse_bitmap("rsb:empty", bytes_per_chunk) }
  let(:result) { redis.sparse_bitmap("rsb:output", bytes_per_chunk) }

  describe "edge cases" do
    before do
      a[0] = true
      a[bits_per_chunk - 1] = true
      a[bits_per_chunk] = true
      a[2 * bits_per_chunk - 1] = true
      a[2 * bits_per_chunk] = true

      b[0] = true
      b[bits_per_chunk] = true
      b[2 * bits_per_chunk - 1] = true
    end

    describe "#[]" do
      it "handles bits arround chunk boundaries" do
        a.chunk_keys.should have(3).items
        set_bits = 
          (0..(3 * bits_per_chunk)).inject([]) { |acc, i|
            acc << i if a[i]
            acc
          }
        set_bits.should match_array([
          0, 
          bits_per_chunk - 1, 
          bits_per_chunk, 
          2 * bits_per_chunk - 1,
          2 * bits_per_chunk])
      end
    end

    describe "#bitcount" do
      it "handles bits around chunk boundaries" do
        a.bitcount.should == 5
      end
    end

    describe "#operator |" do
      it "handles bits around chunk boundaries" do
        result << (a | b)
        result.bitcount.should == 5
      end

      it "handles empty bitmaps" do
        result << (empty | empty)
        result.bitcount.should == 0
      end
    end

    describe "#operator &" do
      it "handles bits around chunk boundaries" do
        result << (a & b)
        result.bitcount.should == 3
      end

      it "handles empty bitmaps" do
        result << (empty & empty)
        result.bitcount.should == 0
      end
    end

    describe "#operator ~" do
      it "handles bits around chunk boundaries" do
        result << (~(a & b))
        result[0].should be_false
        result[1].should be_true
        result[bits_per_chunk - 1].should be_true
        result[bits_per_chunk].should be_false
        result[bits_per_chunk + 1].should be_true
        result[2 * bits_per_chunk - 2].should be_true
        result[2 * bits_per_chunk - 1].should be_false
        result[2 * bits_per_chunk].should be_true
      end
    end

    describe "#operator ^" do
      it "handles bits around chunk boundaries" do
        result << (a ^ b)
        result.bitcount.should == 2
      end

      it "handles empty bitmaps" do
        result << (empty ^ empty)
        result.bitcount.should == 0
      end
    end

    describe "#copy_to" do
      it "overrides all chunks in the target bitmap" do
        # Fix expression with bits set using [] after evaluation doesn't materialize the newly set bits.
        result[4*bits_per_chunk + 1] = true
        a.copy_to(result)
        result.bitcount.should == a.bitcount
        result[4*bits_per_chunk + 1].should be_false
      end
    end
  end
end

describe "Redis#sparse_bitmap" do
  it_should_behave_like "a bitmap factory method", :sparse_bitmap, Redis::Bitops::SparseBitmap
end
