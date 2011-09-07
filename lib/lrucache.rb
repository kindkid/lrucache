require "lrucache/version"
require "priority_queue"

# Not thread-safe!
class LRUCache

  attr_reader :default, :max_size, :ttl

  def initialize(opts={})
    @max_size = Integer(opts[:max_size] || 100)
    @default = opts[:default]
    @ttl = Float(opts[:ttl] || 0)
    raise "max_size must be greater than zero" unless @max_size > 0
    raise "ttl must be positive or zero" unless @ttl >= 0
    @pqueue = PriorityQueue.new
    @data = {}
    @counter = 0
  end

  def clear
    @data.clear
    @pqueue.delete_min until @pqueue.empty?
    @counter = 0 #might as well
  end

  def include?(key)
    datum = @data[key]
    return false if datum.nil?
    value, expires = datum
    if expires.nil? || expires > Time.now # no expiration, or not expired
      access(key)
      true
    else # expired
      delete(key)
      false
    end
  end

  def store(key, value, ttl=nil)
    evict_lru! unless @data.include?(key) || @data.size < @max_size
    ttl ||= @ttl
    expires =
      if ttl.is_a?(Time)
        ttl
      else
        ttl = Float(ttl)
        (ttl > 0) ? (Time.now + ttl) : nil
      end
    @data[key] = [value, expires]
    access(key)
  end

  alias :[]= :store

  def fetch(key, ttl=nil)
    datum = @data[key]
    unless datum.nil?
      value, expires = datum
      if expires.nil? || expires > Time.now # no expiration, or not expired
        access(key)
        return value
      else # expired
        delete(key)
      end
    end
    if block_given?
      value = yield
      store(key, value, ttl)
      value
    else
      @default
    end
  end

  alias :[] :fetch

  def empty?
    size == 0
  end

  def size
    @data.size
  end

  def keys
    @data.keys
  end

  def delete(key)
    @pqueue.delete(key)
    @data.delete(key)
  end

  private

  def evict_lru!
    key, priority = @pqueue.delete_min
    @data.delete(key) unless priority.nil?
  end

  def access(key)
    @pqueue.change_priority(key, @counter += 1)
  end

end
