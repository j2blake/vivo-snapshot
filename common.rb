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

module Kernel
  def bogus(message)
    puts(">>>>>>>>>>>>>BOGUS #{message}")
  end
end

require_relative 'cmd_prepare_uri_list/cmd_prepare_uri_list'
require_relative 'cmd_prepare_session_list/cmd_prepare_session_list'
require_relative 'cmd_prepare_self_editor_account/cmd_prepare_self_editor_account'
require_relative 'cmd_prepare_sub_list/cmd_prepare_sub_list'
require_relative 'cmd_capture/cmd_capture'
require_relative 'cmd_compare/cmd_compare'
require_relative 'cmd_compare_again/cmd_compare_again'
require_relative 'cmd_display/cmd_display'
