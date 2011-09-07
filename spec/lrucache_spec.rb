describe LRUCache do
  it "should never exceed its max_size" do
    c = LRUCache.new(:max_size => 7)
    (1..100).each do |i|
      c[i] = rand(2**16)
      c.size.should <= 7
    end
    c.size.should == 7
  end

  it "should expire the eldest entries first" do
    c = LRUCache.new(:max_size => 3)
    c[1] = 'a'
    c[2] = 'b'
    c[3] = 'c'
    c[2].should == 'b'
    c[1].should == 'a'
    c[3].should == 'c'
    c[4] = 'd' # Out of space! Throws out the least-recently used (2 => 'b').
    c.keys.sort.should == [1,3,4]
    c[5] = 'e'
    c.keys.sort.should == [3,4,5]
    c[1] = 'a'
    c.keys.sort.should == [1,4,5]
  end

  it "should return the default value for expired and non-existent entries" do
    default = double(:default)
    c = LRUCache.new(:max_size => 3, :default => default)
    c[:a].should == default
    c[:a] = 'a'
    c[:a].should == 'a'
    c[:b] = 'b'
    c[:c] = 'c'
    c[:d] = 'd'
    c[:a].should == default
  end

  it "should honor TTL" do
    c = LRUCache.new(:expires => 20)
    now = Time.now
    Timecop.freeze(now) do
      c.store(:a, 'a')
      c.store(:b, 'b', now + 50)
      c.store(:c, 'c', 50)
      c[:a].should == 'a'
      c[:b].should == 'b'
      c[:c].should == 'c'
      c.size.should == 3
    end
    Timecop.freeze(now + 19) do
      c[:a].should == 'a'
      c[:b].should == 'b'
      c[:c].should == 'c'
      c.size.should == 3
    end
    Timecop.freeze(now + 49) do
      c[:a].should be_nil
      c[:b].should == 'b'
      c[:c].should == 'c'
      c.size.should == 2
    end
    Timecop.freeze(now + 50) do
      c[:a].should be_nil
      c[:b].should be_nil
      c[:c].should be_nil
      c.size.should == 0
    end
    c[:a].should be_nil
    c[:b].should be_nil
    c[:c].should be_nil
    c.size.should == 0
  end

  it "should have a default max_size of 100" do
    LRUCache.new.max_size.should == 100
    LRUCache.new(:max_size => 82).max_size.should == 82
  end

  it "can be cleared" do
    c = LRUCache.new
    (1..100).each {|i| c[i] = rand(2**16)}
    c.size.should == 100
    c.clear
    c.size.should == 0
    c.keys.should == []
  end

  describe ".include?(key)" do
    it "affects the access time of the key" do
      c = LRUCache.new(:max_size => 3)
      c[1] = 'a'
      c[2] = 'b'
      c[3] = 'c'
      c.include?(1).should be_true
      c[4] = 'd'
      c[5] = 'e'
      c.include?(1).should be_true
      c.include?(2).should be_false
    end
  end
end