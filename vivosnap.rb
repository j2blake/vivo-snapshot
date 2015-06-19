#! /usr/bin/env ruby

require_relative 'common'

class Vivosnap
  COMMANDS = [
    [:CmdPrepareUriList, ['prepare', 'uri-list']],
    [:CmdPrepareSessionList, ['prepare', 'session-list']],
    [:CmdPrepareSelfEditorAccount, ['prepare', 'self-editor-account']],
    [:CmdPrepareSubList, ['prepare', 'sub-list']],
    [:CmdCapture, ['capture']],
    [:CmdCompareAgain, ['compare', 'again']],
    [:CmdCompare, ['compare']],
    [:CmdDisplay, ['display']]
  ]

  def initialize(args)
    COMMANDS.each do |cmd|
      cmd_args = cmd[1]
      matching_args = args.take(cmd_args.size)
      remaining_args = args.drop(cmd_args.size)
      if cmd_args == matching_args
        @cmd_instance = Object.const_get(cmd[0]).new(remaining_args)
        return
      end
    end
    complain("Arguments not valid: #{args.join(' ')}\nValid choices are #{format_cmds}")
  end

  def format_cmds()
    "\n   #{COMMANDS.map {|c| c[1].join(' ') }.join("\n   ")}"
  end

  def run()
    @cmd_instance.run()
  end
end

#
# ---------------------------------------------------------
# MAIN ROUTINE
# ---------------------------------------------------------
#

begin
  Vivosnap.new(ARGV).run
rescue UserInputError
  puts
  puts $!
  puts
end