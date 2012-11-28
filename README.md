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
    puts cache[:does_not_exist] # 42, has no effect on LRU
    cache[4] = 'd' # Out of space! Throws out the least-recently used (2 => 'b')
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

SOFT_TTL
========
Allows you to have two TTLs when calling fetch with a block.
After the soft-ttl expires, the block is called to refresh the value.
If the block completes normally, the value is replaced and expirations reset.
If the block raises a fatal (non-RuntimeError) exception, it bubbles up. But,
if the block raises a RuntimeError, the cached value is kept and used a little
longer, and the soft-ttl is postponed retry_delay into the future. If the block
is not called successfully before the normal TTL expires, then the cached value
expires and the block is called for a new value, but exceptions are not handled.

    cache = LRUCache.new(:ttl => 1.hour,
                         :soft_ttl => 30.minutes,
                         :retry_delay => 1.minute)
    cache.fetch("banana") { "yellow" } # "yellow"
    cache.fetch("banana") { "george" } # "yellow"

    # 30 minutes later ...
    cache.fetch("banana") { raise "ruckus" } # "yellow"
    cache.fetch("banana") { "george" } # "yellow"

    # 1 more minute later ...
    cache.fetch("banana") { "george" } # "george"
    cache.fetch("banana") { "barney" } # "george"

Eviction Handler
================
Allows you to specify a block that gets called whenever a value gets evicted
from the cache because it is the least recently used.

    cache = LRUCache.new(:max_size => 2,
                         :eviction_handler => lambda { |value| value.shave! })
    cache.store(:yak) { yak }
    cache.store(:dog) { dog }
    cache.store(:cat) { cat } # --> shaves the yak as you would expect!
    cache.delete(:cat)        # --> does not shave the cat
    cache.clear               # --> no shaving involved

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
