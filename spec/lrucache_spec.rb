describe LRUCache do
  describe ".new" do

    it "should default :max_size to 100" do
      LRUCache.new.max_size.should == 100
    end
    it "should accept a :max_size parameter" do
      LRUCache.new(:max_size => 7).max_size.should == 7
    end
    it "should raise an exception if :max_size parameter can't be converted to an integer" do
      expect { LRUCache.new(:max_size => "moocow") }.to raise_exception
    end
    it "should raise an exception if :max_size parameter is converted to a negative integer" do
      expect { LRUCache.new(:max_size => -1) }.to raise_exception
    end

    it "should default :default to nil" do
      LRUCache.new.default.should be_nil
    end
    it "should accept a :default parameter" do
      default = double(:default)
      LRUCache.new(:default => default).default.should == default
    end

    it "should default :ttl to 0 (no expiration)" do
      LRUCache.new.ttl.should == 0
    end
    it "should accept a :ttl parameter" do
      LRUCache.new(:ttl => 98.6).ttl.should == 98.6
    end
    it "should raise an exception if :ttl parameter can't be converted to a float" do
      expect { LRUCache.new(:ttl => "moocow") }.to raise_exception
    end
    it "should raise an exception if :ttl parameter is converted to a negative float" do
      expect { LRUCache.new(:ttl => -1) }.to raise_exception
    end

    it "should initially be empty" do
      LRUCache.new.should be_empty
    end
  end

  describe ".clear" do
    it "should empty the hash and the priority queue" do
      c = LRUCache.new
      10.times { c[rand(2**16)] = :x }
      c.should_not be_empty
      c.instance_variable_get(:@data).should_not be_empty
      c.instance_variable_get(:@pqueue).should_not be_empty

      c.clear

      c.should be_empty
      c.instance_variable_get(:@data).should be_empty
      c.instance_variable_get(:@pqueue).should be_empty
    end

    it "should not call the eviction handler" do
      c = LRUCache.new(:eviction_handler => lambda { raise 'test failed' })
      c[:a] = 'a'
      expect { c.clear }.to_not raise_exception
    end
  end

  describe ".include?(key)" do
    before(:each) { @cache = LRUCache.new }
    context "when the key is not present" do
      it "should return false" do
        @cache.include?(:a).should be_false
      end
      it "should not affect priorities" do
        @cache.should_not_receive(:access)
        @cache.include?(:a)
      end
    end
    context "when the key is present, but the value has expired" do
      before(:each) do
        now = Time.now
        Timecop.freeze(now) { @cache.store(:a, 'a', now + 10) }
        Timecop.freeze(now + 20)
      end
      after(:each) do
        Timecop.return
      end
      it "should return false" do
        @cache.include?(:a).should be_false
      end
      it "should delete the key" do
        @cache.should_receive(:delete).with(:a)
        @cache.include?(:a)
      end
      it "should not affect priorities" do
        @cache.should_not_receive(:access)
        @cache.include?(:a)
      end
    end
    context "when the key is present, and the value has no expiration" do
      before(:each) do
        @cache.store(:a, 'a', nil)
      end
      it "should return true" do
        @cache.include?(:a).should be_true
      end
      it "should update the key's access stamp" do
        @cache.should_receive(:access).with(:a)
        @cache.include?(:a)
      end
    end
    context "when the key is present, and the value has not yet expired" do
      before(:each) do
        now = Time.now
        Timecop.freeze(now)
        @cache.store(:a, 'a', now + 10)
      end
      after(:each) do
        Timecop.return
      end
      it "should return true" do
        @cache.include?(:a).should be_true
      end
      it "should update the key's access stamp" do
        @cache.should_receive(:access).with(:a)
        @cache.include?(:a)
      end
    end
  end

  describe ".store(key, value, ttl=nil)" do
    context "regarding evictions" do
      before(:each) do
        @cache = LRUCache.new(:max_size => 2)
      end
      context "when the cache is not full" do
        context "and the key is not present" do
          it "should not evict an entry" do
            @cache.should_not_receive(:evict_lru!)
            @cache.store(:a, 'a')
          end
          it "should store the value" do
            @cache.store(:a, 'a')
            @cache.fetch(:a).should == 'a'
          end
          it "should update the key's access stamp" do
            @cache.should_receive(:access).with(:a)
            @cache.store(:a, 'a')
          end
        end
        context "and the key is present" do
          it "should not evict an entry" do
            @cache.should_not_receive(:evict_lru!)
            @cache.store(:a, 'a')
          end
          it "should store the value" do
            @cache.store(:a, 'a')
            @cache.fetch(:a).should == 'a'
          end
          it "should update the key's access stamp" do
            @cache.should_receive(:access).with(:a)
            @cache.store(:a, 'a')
          end
        end
      end
      context "when the cache is full" do
        before(:each) do
          @cache = LRUCache.new(
            :max_size => 2,
            :eviction_handler => lambda {|value| value << ' evicted' })
          @cache[:b] = @b = 'b'
          @cache[:c] = @c = 'c'
          @lru = :b
        end
        context "and the key is not present" do
          it "should evict the least-recently used entry from the cache" do
            @cache.keys.should include(@lru)
            @cache.store(:a, 'a')
            @cache.keys.should_not include(@lru)
          end
          it "should store the value" do
            @cache.store(:a, 'a')
            @cache.fetch(:a).should == 'a'
          end
          it "should update the key's access stamp" do
            @cache.should_receive(:access).with(:a)
            @cache.store(:a, 'a')
          end
          it "should call the eviction handler" do
            @cache.store(:a, 'a')
            @b.should == 'b evicted'
          end
        end
        context "and the key is present" do
          it "should not evict an entry" do
            @cache.should_not_receive(:evict_lru!)
            @cache.store(:c, 'c')
          end
          it "should store the value" do
            @cache.store(:c, 'c')
            @cache.fetch(:c).should == 'c'
          end
          it "should update the key's access stamp" do
            @cache.should_receive(:access).with(:c)
            @cache.store(:c, 'c')
          end
        end
      end
    end
    context "when ttl is not given and the cache's default ttl is zero" do
      it "should set the entry with no expiration time" do
        c = LRUCache.new(:ttl => 0)
        c.store(:a,'a')
        stored = c.instance_variable_get(:@data)[:a]
        stored.value.should == 'a'
        stored.expiration.should == nil
      end
    end
    context "when ttl is not given and the cache's default ttl is greater than zero" do
      it "should set the entry to expire that many seconds in the future" do
        c = LRUCache.new(:ttl => 1)
        now = Time.now
        Timecop.freeze(now) { c.store(:a,'a') }
        stored = c.instance_variable_get(:@data)[:a]
        stored.value.should == 'a'
        stored.expiration.to_f.should == (now + 1).to_f
      end
    end
    context "when ttl is a Time" do
      it "should set the entry to expire at the given time" do
        c = LRUCache.new
        ttl = Time.now + 246
        c.store(:a, 'a', ttl)
        stored = c.instance_variable_get(:@data)[:a]
        stored.value.should == 'a'
        stored.expiration.should == ttl
      end
    end
    context "when ttl can be parsed as a float" do
      it "should set the entry to expire that many seconds in the future" do
        c = LRUCache.new
        now = Time.now
        Timecop.freeze(now) { c.store(:a, 'a', "98.6") }
        stored = c.instance_variable_get(:@data)[:a]
        stored.value.should == 'a'
        stored.expiration.to_f.should == (now + 98.6).to_f
      end
    end
    context "when ttl cannot be parsed as a float" do
      it "should raise an exception" do
        c = LRUCache.new
        expect { c.store(:a, 'a', "moocow") }.to raise_exception
      end
    end
  end

  describe ".fetch(key, ttl=nil)" do
    context "when no block is given" do
      context "and the key does not exist" do
        before(:each) do
          @default = double(:default)
          @cache = LRUCache.new(:default => @default)
        end
        it "should return the default value" do
          @cache.fetch(:a).should == @default
        end
        it "should not affect the priorities" do
          @cache.should_not_receive(:access)
          @cache.fetch(:a)
        end
      end
      context "and the key has been evicted" do
        before(:each) do
          @cache = LRUCache.new(:max_size => 2)
          @cache[:a] = 'a'
          @cache[:b] = 'b'
          @cache[:c] = 'c'
        end
        it "should return the default value" do
          @cache.fetch(:a).should == @default
        end
        it "should not affect the priorities" do
          @cache.should_not_receive(:access)
          @cache.fetch(:a)
        end
      end
      context "and the key has expired" do
        before(:each) do
          @cache = LRUCache.new(:ttl => 10)
          now = Time.now
          Timecop.freeze(now) { @cache[:a] = 'a' }
          Timecop.freeze(now + 20)
        end
        after(:each) do
          Timecop.return
        end
        it "should return the default value" do
          @cache.fetch(:a).should == @default
        end
        it "should not affect the priorities" do
          @cache.should_not_receive(:access)
          @cache.fetch(:a)
        end
        it "should delete the key" do
          @cache.should_receive(:delete).with(:a)
          @cache.fetch(:a)
        end
      end
      context "and the key is present and un-expired" do
        before(:each) do
          @cache = LRUCache.new(:ttl => nil)
          @cache[:a] = 'a'
        end
        it "should return the cached value" do
          @cache.fetch(:a).should == 'a'
        end
        it "should update the key's access stamp" do
          @cache.should_receive(:access).with(:a)
          @cache.fetch(:a)
        end
      end
    end
    context "when a block is given" do
      context "and the key does not exist" do
        it "should call the block and store and return the result" do
          c = LRUCache.new
          ttl = double(:ttl)
          result = double(:result)
          c.should_receive(:store).with(:a, result, ttl).and_return(result)
          c.fetch(:a, ttl){ result }.should == result
        end
      end
      context "and the key has been evicted" do
        it "should call the block and store and return the result" do
          c = LRUCache.new
          c[:a] = 'a'
          c.send(:evict_lru!)
          ttl = double(:ttl)
          result = double(:result)
          c.should_receive(:store).with(:a, result, ttl).and_return(result)
          c.fetch(:a, ttl){ result }.should == result
        end
      end
      context "and the key has expired" do
        it "should call the block and store and return the result" do
          c = LRUCache.new
          now = Time.now
          Timecop.freeze(now) { c.store(:a, 'a', now + 10) }
          Timecop.freeze(now + 20) do
            ttl = double(:ttl)
            result = double(:result)
            c.should_receive(:store).with(:a, result, ttl).and_return(result)
            c.fetch(:a, ttl){ result }.should == result
          end
        end
      end
      context 'and the key has "soft"-expired' do
        before(:each) do
          @c = LRUCache.new
          @c.store(:a, 'a', :ttl => 10_000, :soft_ttl => Time.now - 60, :retry_delay => 10)
          @args = {:ttl => 10_000, :soft_ttl => 60, :retry_delay => 10}
        end
        context "and the block raises a runtime exception" do
          it "should continue to return the old value" do
            @c.should_not_receive(:store)
            @c.fetch(:a, @args) { raise "no!" }.should == 'a'
          end
          it "should extend the soft-expiration by retry_delay" do
            Timecop.freeze(Time.now) do
              data = @c.instance_variable_get(:@data)
              original_soft_expiration = data[:a].soft_expiration
              @c.should_not_receive(:store)
              @c.fetch(:a, @args) { raise "no!" }
              data = @c.instance_variable_get(:@data)
              data[:a].soft_expiration.should == Time.now + @args[:retry_delay]
            end
          end
        end
        context "and the block raises a fatal exception" do
          it "should allow the exception through" do
            expect {
              @c.fetch(:a, @args) { raise(NoMemoryError,"panic!") }
            }.to raise_exception(NoMemoryError)
          end
        end
        context "and the block does not raise an exception" do
          it "should call the block and store and return the result" do
            result = double(:result)
            @c.should_receive(:store).with(:a, result, @args).and_return(result)
            @c.fetch(:a, @args) { result }.should == result
          end
        end
      end
      context "and the key is present and un-expired" do
        it "should return the cached value without calling the block" do
          c = LRUCache.new(:ttl => nil)
          c[:a] = 'a'
          c.fetch(:a) { raise 'fail' }.should == 'a'
        end
      end
    end
  end

  describe ".empty?" do
    it "should return true if and only if size is zero" do
      c = LRUCache.new
      c.empty?.should be_true
      c[:a] = 'a'
      c.empty?.should be_false
      c.clear
      c.empty?.should be_true
    end
  end

  describe ".size and .keys" do
    it "should return a count / list of entries in the cache" do
      c = LRUCache.new(:max_size => 10)
      (1..10).each do |i|
        c.size.should == i-1
        c[i] = :x
        c.size.should == i
        c.keys.sort.should == (1..i).to_a
      end
      (1..3).each do |i|
        c.delete(i)
        c.size.should == 10 - i
        c.keys.sort.should == ((i+1)..10).to_a
      end
      (1..3).each do |i|
        c[i] = :x
        c.size.should == 7+i
        c.keys.sort.should == (1..i).to_a + (4..10).to_a
      end
      (1..10).each do |i|
        c[i] = :x
        c.size.should == 10
        c.keys.sort.should == (1..10).to_a
      end
      c.clear
      c.size.should == 0
      c.keys.should == []
    end
    it "may include expired entries" do
      c = LRUCache.new(:ttl => 10, :max_size => 100)
      now = Time.now
      (0..19).each do |i|
        Timecop.freeze(now + i) do
          c[i] = :x
          c.size.should == i+1
          c.keys.sort.should == (0..i).to_a
        end
      end
      Timecop.freeze(now + 20) do
        c.size.should == 20
        (0..19).each do |i|
          c.include?(i)
        end
        c.size.should == 9
        c.keys.sort.should == (11..19).to_a
      end
    end
    it "should always return a value less than or equal to the cache's max_size" do
      c = LRUCache.new(:max_size => 7)
      (1..100).each do |i|
        c[i] = :x
        c.size.should <= 7
      end
    end
  end


  describe ".delete(key)" do
    it "should remove the key from the internal hash and priority queue" do
      c = LRUCache.new
      c[:a] = 'a'
      c.instance_variable_get(:@data).should include(:a)
      c.instance_variable_get(:@pqueue).should include([:a,1])
      c.delete(:a)
      c.instance_variable_get(:@data).should_not include(:a)
      c.instance_variable_get(:@pqueue).should_not include([:a,1])
    end

    it "should return the value associated with the key" do
      c = LRUCache.new
      c[:a] = 'a'
      c.delete(:a).should == 'a'
      c.delete(:a).should be_nil
      c.delete(:b).should be_nil
    end

    it "should not call the eviction handler" do
      c = LRUCache.new(:eviction_handler => lambda { raise 'test failed' })
      c[:a] = 'a'
      expect { c.delete(:a) }.to_not raise_exception
    end
  end

  describe ".evict_lru!" do
    it "should find the least-recently used entry, and delete it" do
      c = LRUCache.new
      c[1] = 'a'
      c[2] = 'b'
      c[3] = 'c'
      c[4] = 'd'
      c[:dne1].should be_nil # Doesn't affect LRU.
      c[2].should == 'b'
      c[1].should == 'a'
      c[3].should == 'c'
      c[4].should == 'd'
      c[:dne2].should be_nil # Doesn't affect LRU.
      c.keys.sort.should == [1,2,3,4]
      c.send(:evict_lru!)
      c.keys.sort.should == [1,3,4]
      c.send(:evict_lru!)
      c.keys.sort.should == [3,4]
      c.send(:evict_lru!)
      c.keys.sort.should == [4]
      c.send(:evict_lru!)
      c.keys.should == []
      c.send(:evict_lru!)
      c.keys.should == []
    end
    it "should leave the internal hash the same size as the priority queue" do
      c = LRUCache.new
      expected_size = 0
      counter = 0
      100.times do
        if rand < 0.8
          c[counter += 1] = :x
          expected_size += 1
        else
          c.send(:evict_lru!)
          expected_size -= 1
        end
        expected_size = [expected_size,0].max
        c.instance_variable_get(:@data).size.should == expected_size
        c.instance_variable_get(:@pqueue).count.should == expected_size
      end
    end
  end
end
