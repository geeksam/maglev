require File.expand_path('simple', File.dirname(__FILE__))

#     BEGIN TEST CASES

plat = RUBY_PLATFORM

if plat.index('solaris')
  # use xpg4 compatibility version
  test(Maglev::System.getgid,  `/usr/xpg4/bin/id -r -g`.chomp.to_i, "getgid")
  test(Maglev::System.getegid, `/usr/xpg4/bin/id -g`.chomp.to_i,    "getegid")

  test(Maglev::System.getuid,  `/usr/xpg4/bin/id -r -u`.chomp.to_i, "getuid")
  test(Maglev::System.geteuid, `/usr/xpg4/bin/id -u`.chomp.to_i,    "geteuid")
else
  test(Maglev::System.getgid,  `id -r -g`.chomp.to_i, "getgid")
  test(Maglev::System.getegid, `id -g`.chomp.to_i,    "getegid")

  test(Maglev::System.getuid,  `id -r -u`.chomp.to_i, "getuid")
  test(Maglev::System.geteuid, `id -u`.chomp.to_i,    "geteuid")
end

# Test access to the session stats
47.times do |i|
  test(Maglev::System.get_session_stat(i), 0, "A: get_session_stat(#{i})")

  Maglev::System.set_session_stat(i, i)
  test(Maglev::System.get_session_stat(i), i, "B: set_session_stat(#{i})")

  Maglev::System.increment_session_stat(i)
  test(Maglev::System.get_session_stat(i), i+1, "C: increment_session_stat(#{i})")

  Maglev::System.decrement_session_stat(i, 2)
  test(Maglev::System.get_session_stat(i), i-1, "D: decrement_session_stat(#{i})")
end

# MagLev was (1) modifying the command string passed to system() and (2)
# not putting a space between the command and first param if command_parts
# was size 2
command_parts = ["echo", "foo"]

success = system(*command_parts)

test(success, true, "echo command worked")
test(command_parts[0], "echo", "Modified command_parts[0]")

# Now with more args
command_parts = ["echo", "foo", "bar"]

success = system(*command_parts)

test(success, true, "echo command worked")
test(command_parts[0], "echo", "Modified command_parts[0]")

report
