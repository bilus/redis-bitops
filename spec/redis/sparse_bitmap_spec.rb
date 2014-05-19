require 'spec_helper'

describe Redis::SparseBitmap, redis_cleanup: true, redis_key_prefix: "rsb:" do
  it_should_behave_like "a bitmap", :sparse_bitmap

  describe "#[]" do
    it "handles bits arround chunk boundary"
  end
  
  describe "#bitcount" do
  end
  
  describe "#operator |" do 
  end
  
  describe "#operator ~" do
  end
  
  describe "#operator ^" do
  end
  
  describe "#delete!" do
  end
  
  describe "#<<" do

  end
end

describe "Redis#sparse_bitmap" do
  it_should_behave_like "a bitmap factory method", :sparse_bitmap, Redis::SparseBitmap
end
