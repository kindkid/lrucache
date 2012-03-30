class LRUCache::PriorityQueue
  include Enumerable
  
  class Node # :nodoc:
    attr_accessor :parent, :child, :left, :right, :priority, :value, :degree, :marked

    def initialize(value, priority)
      @value = value
      @priority = priority
      @degree = 0
      @marked = false
      @right = self
      @left = self
    end
  end

  def initialize
    @root = nil
    @size = 0
    @nodes_by_value = {}
    @nodes_by_priority = {}
  end
  
  # Complexity: O(1)
  def size
    @size
  end

  # Complexity: O(1)
  def empty?
    @root.nil?
  end
  
  # Complexity: O(1)
  def clear
    @root = nil
    @size = 0
    @nodes_by_value = {}
    @nodes_by_priority = {}
    self
  end

  # Complexity: O(1)
  def include?(value)
    @nodes_by_value.include?(value)
  end
  
  # Complexity: O(n log n)
  def each
    @nodes_by_priority.sort_by{|priority,node| priority}.reverse.each do |priority, node|
      yield node.value
    end
  end

  # Returns self.
  # Complexity: O(1)
  def set(value, priority)
    node = @nodes_by_value[value]
    if node.nil?
      node = Node.new(value, priority)
      if @root
        node.right = @root
        node.left = @root.left
        node.left.right = node
        @root.left = node
        @root = node if priority < @root.priority
      else
        @root = node
      end
      @size += 1
      @nodes_by_priority[priority] = node
      @nodes_by_value[value] = node
    else
      change_priority(node, priority)
    end
    self
  end
  
  # Returns: [value, priority], or nil.
  # Complexity: Amortized O(1)
  def pop
    return nil unless @root
    popped = @root
    if @size == 1
      clear
      return [popped.value, popped.priority]
    end

    raise("Popped node was missing") unless popped == @nodes_by_value.delete(popped.value)
    raise("Popped node was missing") unless popped == @nodes_by_priority.delete(popped.priority)

    # Merge the popped's children into root node
    if @root.child
      @root.child.parent = nil
      
      # get rid of parent
      sibling = @root.child.right
      until sibling == @root.child
        sibling.parent = nil
        sibling = sibling.right
      end
      
      # Merge the children into the root. If @root is the only root node, make its child the @root node
      if @root.right == @root
        @root = @root.child
      else
        next_left, next_right = @root.left, @root.right
        current_child = @root.child
        @root.right.left = current_child
        @root.left.right = current_child.right
        current_child.right.left = next_left
        current_child.right = next_right
        @root = @root.right
      end
    else
      @root.left.right = @root.right
      @root.right.left = @root.left
      @root = @root.right
    end
    consolidate

    @size -= 1
    [popped.value, popped.priority]
  end
  
  # Returns priority, or nil.
  # Complexity: Amortized O(log n)
  def delete(value)
    node = @nodes_by_value[value]
    if node.nil?
      nil
    else
      priority = node.priority
      pop if change_priority(node, nil, true)
      priority
    end
  end
  
  private

  def change_priority(node, new_priority, delete=false)
    old_priority = node.priority
    return if new_priority == old_priority
    unless (delete || new_priority > old_priority)
      raise "Don't go breaking my heap!"
    end
    unless node == @nodes_by_priority.delete(old_priority)
      raise "Node was missing!"
    end
    node.priority = new_priority
    @nodes_by_priority[new_priority] = node
    parent = node.parent
    if parent
      # if heap property is violated
      if delete || new_priority < parent.priority
        cut(node, parent)
        cascading_cut(parent)
      end
    end
    if delete || node.priority < @root.priority
      @root = node
    end
  end
  
  # make node a child of a parent node
  def link_nodes(child, parent)
    # link the child's siblings
    child.left.right = child.right
    child.right.left = child.left

    child.parent = parent
    
    # if parent doesn't have children, make new child its only child
    if parent.child.nil?
      parent.child = child.right = child.left = child
    else # otherwise insert new child into parent's children list
      current_child = parent.child
      child.left = current_child
      child.right = current_child.right
      current_child.right.left = child
      current_child.right = child
    end
    parent.degree += 1
    child.marked = false
  end
  
  # Makes sure the structure does not contain nodes in the root list with equal degrees
  def consolidate
    roots = []
    root = @root
    min = root
    # find the nodes in the list
    loop do
      roots << root
      root = root.right
      break if root == @root
    end
    degrees = []
    roots.each do |root|
      min = root if root.priority < min.priority
      # check if we need to merge
      if degrees[root.degree].nil?  # no other node with the same degree
        degrees[root.degree] = root
        next
      else  # there is another node with the same degree, consolidate them
        degree = root.degree
        until degrees[degree].nil? do
          other_root_with_degree = degrees[degree]
          if root.priority < other_root_with_degree.priority  # determine which node is the parent, which one is the child
            smaller, larger = root, other_root_with_degree
          else
            smaller, larger = other_root_with_degree, root
          end
          link_nodes(larger, smaller)
          degrees[degree] = nil
          root = smaller
          degree += 1
        end
        degrees[degree] = root
        min = root if min.priority == root.priority # this fixes a bug with duplicate keys not being in the right order
      end
    end
    @root = min
  end
  
  def cascading_cut(node)
    p = node.parent
    if p
      if node.marked
        cut(node, p)
        cascading_cut(p)
      else
        node.marked = true
      end
    end
  end
  
  # remove x from y's children and add x to the root list
  def cut(x, y)
    x.left.right = x.right
    x.right.left = x.left
    y.degree -= 1
    if (y.degree == 0)
      y.child = nil
    elsif (y.child == x)
      y.child = x.right
    end
    x.right = @root
    x.left = @root.left
    @root.left = x
    x.left.right = x
    x.parent = nil
    x.marked = false
  end
  
end