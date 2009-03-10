# depends on: module.rb class.rb

# class << MAIN
#   def include(*mods)
#     Object.include(*mods)
#   end

#   def public(*methods)
#     Object.public(*methods)
#   end

#   def private(*methods)
#     Object.private(*methods)
#   end

#   def protected(*methods)
#     Object.protected(*methods)
#   end

#   def add_method(name, obj)
#     Object.add_method(name, obj)
#   end

#   def alias_method(new_name, current_name)
#     Object.__send__ :alias_method, new_name, current_name
#   end

#   def __const_set__(name, obj)
#     Object.__const_set__(name, obj)
#   end
# end

# def self.to_s
#   "main"
# end

# class NilClass
#   alias_method :|, :^

#   def call(*a)
#     raise LocalJumpError, "not callable"
#   end
# end

# NIL = nil

# class TrueClass
#   alias_method :inspect, :to_s
# end

# TRUE = true

# class FalseClass
#   alias_method :|, :^
#   alias_method :inspect, :to_s
# end

# FALSE = false

# Undefined = Object.new

##
# This is used to prevent recursively traversing an object graph.

# TODO: RecursionGuard: Since we don't currently have a thread class,
#       I made the thread local stack a single global...
module RecursionGuard
  # TODO move this module to a Gemstone file/directory since it
  #  has been changed to use Gemstone identity Set .

  STACK = IdentitySet.new # Gemstone single thread hack
  def self.inspecting?(obj)
    stack._includes(obj)
  end

  def self.inspect(obj, &block)
    stack << obj
    begin
      yield
    ensure
      stack._remove(obj)
    end
  end

  def self.stack
#    stack = Thread.current[:inspecting] ||= Set.new
    STACK  # Gemstone single thread hack
  end
end

#  Do not use Rubinius implementation of metaclass .
#  any non-Singleton object for which it is invoked
#  will have a singleton class added, which is very inefficient.
#
#  class Object
#    # Rubinius uses metaclass() in several files
#    def metaclass
#      class << self;self;end
#    end
#    alias_method :__metaclass__, :metaclass
#  end
