lrucache - A simple LRU-cache based on a hash and a priority queue.

Setup
=====
gem install lrucache

Example
=======
    require 'lrucache'
    cache = LRUCache.new(:max_size => 3, :default => 42)
    cache[1] = 'a'
    cache[2] = 'b'
    cache[3] = 'c'
    puts cache[2] # b
    puts cache[1] # a
    puts cache[3] # c
    puts cache[:does_not_exist] # 42, has no effect on LRU.
    cache[4] = 'd' # Out of space! Throws out the least-recently used (2 => 'b').
    puts cache.keys # [1,3,4]


TTL (time-to-live)
==================
    cache = LRUCache.new(:ttl => 1.hour)
    cache.store("banana", "yellow")
    cache.store("monkey", "banana", Time.now + 3.days)
    # or ...
    cache.store("monkey", "banana", 3.days)

    # Three minutes later ...
    cache.fetch("banana") # "yellow"
    cache.fetch("monkey") # "banana"

    # Three hours later ...
    cache.fetch("banana") # nil
    cache.fetch("monkey") # "banana"
    
    # Three days later ...
    cache.fetch("banana") # nil
    cache.fetch("monkey") # nil