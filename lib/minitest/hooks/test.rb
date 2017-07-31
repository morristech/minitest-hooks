require 'minitest'

# Add support for around and before_all/after_all/around_all hooks to
# minitest spec classes.
module Minitest::Hooks
  # Add the class methods to the class. Also, include an additional
  # module in the class that before(:all) and after(:all) methods
  # work on a class that directly includes this module.
  def self.included(mod)
    super
    mod.instance_exec do
      extend(Minitest::Hooks::ClassMethods)
    end
  end

  # Empty method, necessary so that super calls in spec subclasses work.
  def before_all
  end

  # Empty method, necessary so that super calls in spec subclasses work.
  def after_all
  end

  # Method that just yields, so that super calls in spec subclasses work.
  def around_all
    yield
  end

  # Method that just yields, so that super calls in spec subclasses work.
  def around
    yield
  end

  # Run around hook inside, since time_it is run around every spec.
  def time_it
    super do
      around do
        yield
      end
    end
  end
end

module Minitest::Hooks::ClassMethods
  # Object used to get an empty new instance, as new by default will return
  # a dup of the singleton instance.
  NEW = Object.new.freeze

  # Unless name is NEW, return a dup singleton instance.
  def new(name)
    if name.equal?(NEW)
      return super
    end

    instance = @instance.dup
    instance.name = name
    instance.failures = []
    instance
  end

  # When running the specs in the class, first create a singleton instance, the singleton is
  # used to implement around_all/before_all/after_all hooks, and each spec will run as a
  # dup of the singleton instance.
  def with_info_handler(reporter, &block)
    @instance = new(NEW)
    inside = false
   
    begin
      @instance.around_all do
        inside = true
        begin
          @instance.capture_exceptions do
            @instance.before_all
          end

          if @instance.failure
            failed = true
            @instance.name = :before_all
            reporter.record @instance
          else
            super(reporter, &block)
          end
        ensure
          @instance.capture_exceptions do
            @instance.after_all
          end
          if @instance.failure && !failed
            failed = true
            @instance.name = :after_all
            reporter.record @instance
          end
          inside = false
        end
      end
    rescue => e
      @instance.capture_exceptions do
        raise e
      end
      @instance.name = :around_all
      reporter.record @instance
    end
  end

  # If type is :all, set the around_all hook, otherwise set the around hook.
  def around(type=nil, &block)
    meth = type == :all ? :around_all : :around
    define_method(meth, &block)
  end

  # If type is :all, set the before_all hook instead of the before hook.
  def before(type=nil, &block)
    if type == :all
     define_method(:before_all) do
        super()
        instance_exec(&block)
      end
      nil
    else
      super
    end
  end

  # If type is :all, set the after_all hook instead of the after hook.
  def after(type=nil, &block)
    if type == :all
     define_method(:after_all) do
        instance_exec(&block)
        super()
      end
      nil
    else
      super
    end
  end
end
