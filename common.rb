#
# Helpful classes and utility methods.
#
class UserInputError < StandardError
end

class SettingsError < StandardError
end

def warning(message)
  puts("WARNING: #{message}")
end

def bogus(message)
  puts(">>>>>>>>>>>>>BOGUS #{message}")
end

def complain(message)
  raise UserInputError.new(message)
end

#
# Record stdout and stderr, even while they are being displayed.
#
class MultiIO < IO
  def initialize(*targets)
     @targets = targets
  end

  def write(*args)
    @targets.each {|t| t.write(*args)}
  end

  def flush()
    @targets.each(&:flush)
  end

  def close
    @targets.each(&:close)
  end
end

$stdout = MultiIO.new(STDOUT, File.open(File.expand_path('~/vivosnap.stdout'), "w"))
$stderr = MultiIO.new(STDERR, File.open(File.expand_path('~/vivosnap.stderr'), "w"))

require 'rdf'

require_relative 'utils/args_checker'
require_relative 'utils/http_request'

require_relative 'cmd_prepare_uri_list/cmd_prepare_uri_list'
require_relative 'cmd_prepare_session_list/cmd_prepare_session_list'
require_relative 'cmd_prepare_self_editor_account/cmd_prepare_self_editor_account'
require_relative 'cmd_prepare_sub_list/cmd_prepare_sub_list'
require_relative 'cmd_capture/cmd_capture'
require_relative 'cmd_compare/cmd_compare'
require_relative 'cmd_compare_again/cmd_compare_again'
require_relative 'cmd_display/cmd_display'
