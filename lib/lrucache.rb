require "lrucache/version"
require "priority_queue"

# Not thread-safe!
class LRUCache

  attr_reader :default, :max_size

  def initialize(opts={})
    @max_size = (opts[:max_size] || 100).to_i
    @default = opts[:default]
    @expires = (opts[:expires] || 0).to_f
    raise "max_size must be greather than zero" unless @max_size > 0
    @pqueue = PriorityQueue.new
    @data = {}
    @counter = 0
  end

  def clear
    @data.clear
    @pqueue.delete_min until @pqueue.empty?
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

  def store(key, value, expires=nil)
    expire_lru! unless @data.include?(key) || @data.size < @max_size
    expiration =
      if expires.nil?
        (@expires > 0) ? (Time.now + @expires) : nil
      elsif expires.is_a?(Time)
        expires
      else
        expires = expires.to_f
        (expires > 0) ? (Time.now + expires) : nil
      end
    @data[key] = [value, expiration]
    access(key)
  end

  alias :[]= :store

  def fetch(key)
    datum = @data[key]
    return @default if datum.nil?
    value, expires = datum
    if expires.nil? || expires > Time.now # no expiration, or not expired
      access(key)
      value
    else # expired
      delete(key)
      @default
    end
  end

  alias :[] :fetch

  def size
    @data.size
  end

  def keys
    @data.keys
  end

  def delete(key)
    @data.delete(key)
    @pqueue.delete(key)
  end

  private

  def expire_lru!
    key, priority = @pqueue.delete_min
    @data.delete(key) unless priority.nil?
  end

  def access(key)
    @pqueue.change_priority(key, @counter += 1)
  end

end
