$:.unshift File.expand_path(File.dirname(__FILE__))

# Until Trac # 552 is fixed, just code all of the tests in this file.
# Later, after 552 is fixed, we can break them apart a bit.
#
#require 'globals_tests'
#Maglev.abort_transaction  # Pick up any commits during the requires


Maglev.persistent do

  # This class defines a small unit test framework, and it defines many
  # test method pairs.  A single persistence test is broken into two
  # methods: test_NNN() and check_NNN().  The test_NNN methods each setup
  # some persistent test data, and the check_NNN tests that the data was
  # saved. The test_NNN methods are run, in order, in a fresh VM within a
  # Maglev.persistent block (by calling MagLevPersistenceTests#run_tests).
  # The check_NNN methods are then run, in order, in a new VM, so they
  # should see the persistent changes done by the first VM.
  #
  # This file just defines the class.  See the driver script for more
  # details.

  class MagLevPersistenceTests
    #include GlobalsTests

    ########################################
    # Persistence Tests methods
    ########################################
    def test_001
      Maglev::PERSISTENT_ROOT[:hat] = "A New Hat"
    end

    def check_001
      test(Maglev::PERSISTENT_ROOT[:hat], "A New Hat", :check_001)
    end

#  test_002 waiting on track 553
#
#     def test_002
#       # PTestPersistentConstant and PTestTransientConstant are set
#       # below, this method makes sure const_set works correctly in
#       # both transient and persistent modes
#       Maglev.transient do
#         Object.const_set('PTestTransientConstant2', 33)
#       end
#       Maglev.persistent do
#         Object.const_set('PTestPersistentConstant2', 44)
#       end

#       test(PTestPersistentConstant, true, "PTestPersistentConstant")
#       test(PTestPersistentConstant2,  44, "PTestPersistentConstant2")

#       test(PTestTransientConstant,  true, "PTestTransientConstant")
#       test(PTestTransientConstant2,   33, "PTestTransientConstant2")
#     end

#     def check_002
#       test(PTestPersistentConstant, true, "PTestPersistentConstant")
#       test(PTestPersistentConstant2,  44, "PTestPersistentConstant2")

#       test(defined? PTestTransientConstant,  nil, "PTestTransientConstant")
#       test(defined? PTestTransientConstant2,  nil, "PTestTransientConstant2")
#     end

    def test_003
      # Test that a persisted class has its constants, instance variables
      # and class variables saved.
      require 't003'
    end

    def check_003
      test(C003.foo, "foo", "Class variable")
      test(C003.bar, "bar", "Class instance variable")
    end

    def test_004
      require 't004'  # Commits class C004 with methods
      # Now remove the methods
      Maglev.persistent do
        C004.remove_method(:im_one)
        class << C004; remove_method(:cm_one); end
      end
      Maglev.commit_transaction

      c = C004.new

      test(C004.respond_to?(:cm_one), false, 'test_004 a: cm_one not there')
      test(C004.cm_two, :self_cm_two, 'test_004 a: cm_two still here')
      test(C004.cm_three, :self_cm_three, 'test_004 a: cm_three still here')

      test(c.respond_to?(:im_one), false, 'test_004 a: im_one not there')
      test(c.im_two, :im_two, 'test_004 a: im_two still here')
      test(c.im_three, :im_three, 'test_004 a: im_three still here')

#      Maglev.transient do
#        C004.remove_method(:im_three) # raises exception

#         class << C004; remove_method(:cm_three); end
#       end
#       Maglev.commit_transaction # should be no-op, but just testing...

#       test(C004.respond_to?( :cm_one), false, 'test_004 b: cm_one not there')
#       test(C004.cm_two, :self_cm_two, 'test_004 b: cm_two still here')
#       test(C004.respond_to?(:cm_three), 'test_004 b: cm_three still here')

#       test(c.respond_to?(:im_one), false, 'test_004 b: im_one not there')
#       test(c.im_two, :im_two, 'test_004 b: im_two still here')
#       test(c.respond_to?(:im_three), false, 'test_004 b: im_three not there')
    end

    def check_004
      c = C004.new

      test(C004.respond_to?(:cm_one), false, 'test_004 a: cm_one not there')
      test(C004.cm_two, :self_cm_two, 'test_004 a: cm_two still here')
      test(C004.cm_three, :self_cm_three, 'test_004 a: cm_three still here')

      test(c.respond_to?(:im_one), false, 'test_004 a: im_one not there')
      test(c.im_two, :im_two, 'test_004 a: im_two still here')
      test(c.im_three, :im_three, 'test_004 a: im_three still here')
    end

    def test_005
      require 't005'
      check_005  # the checks are valid both in this VM and the next
    end

    def check_005
      employees = Maglev::PERSISTENT_ROOT[:employees]
      test(employees.size, 3, "005: check right number of employees")
      employees.each do |employee|
        test(employee.name.nil?, false,  "Bad name for #{employee}")
        test(employee.salary > 0, true,  "Bad salary for #{employee}")
      end
    end

    ########################################
    # Test Framework Methods
    ########################################
    def initialize
      @failed = []
      @count = 0
    end

    def run_tests
      Maglev.persistent do
        puts "== In Maglev.persistent block..."
        self.methods.grep(/^test_/).sort.each do |m|
          puts "== Running: #{m}"
          send m
        end
        Maglev.commit_transaction
        puts "== Maglev.commit_transaction"
      end
      report
    end

    def run_checks
      self.methods.grep(/^check_/).sort.each do |m|
        puts "== Checking: #{m}"
        send m
      end
      report
    end

    def test(actual, expected, msg)
      @count += 1
      register_failure(msg, expected, actual) unless (expected == actual)
    end

    def report
      num = @failed.size
      puts "=== Ran #{@count} tests.  Failed: #{@failed.size}"
      @failed.each { |f| puts f }
      raise "Failed #{@failed.size} tests" unless @failed.empty?
      true
    end

    def failed_test(msg, expected, actual)
      @count += 1
      register_failure(msg, expected, actual)
    end

    def register_failure(msg, expected, actual)
      @failed << "ERROR: #{msg} Expected: #{expected.inspect} actual: #{actual.inspect}"
      x = @failed
      unless ENV['SIMPLE_NO_PAUSE']  # don't pause if the env says not to...
        nil.pause if defined? RUBY_ENGINE # Keep MRI from trying to pause
      end
    end

  end

  PTestPersistentConstant = true  # A top level persistent constant
end

Maglev.transient do
  PTestTransientConstant = true  # A top level transient constant
end

Maglev.commit_transaction
