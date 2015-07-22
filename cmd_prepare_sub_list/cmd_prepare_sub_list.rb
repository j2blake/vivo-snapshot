=begin
--------------------------------------------------------------------------------

Create a sub-list sample from a session list file.

You provide the session list file, and how many sessions you want to put into
the sub-list, and the tool will extract that many session lines from the original
list, evenly spaced, and put them into the new file.

--------------------------------------------------------------------------------

vivosnap.rb prepare sub-list [session_list_file] [count] [sub_list_file]

--------------------------------------------------------------------------------
=end

class CmdPrepareSubList
  include ::ArgsChecker

  USAGE = "prepare sub-list [session_list_file] [count] {sub_list_file {REPLACE}}"
  def initialize(args)
    @args = args
    @replace = args.delete('REPLACE')

    complain("usage: #{USAGE}") unless (2..3).include? args.size

    @session_list_file = confirm_file_exists(args[0])
    @line_count = confirm_positive_integer(args[1])
    @output = set_output_io(args[2], @replace)
  end

  def run()
    read_lines_and_remove_comments
    complain("#{@session_list_file} only contains #{@lines.size} effective lines.") if @lines.size < @line_count

    write_heading()
    write_selected_lines()
    write_report()
  end

  def write_heading()
    @output.puts "#"
    @output.puts "# prepare sub-list #{@args.join(' ')}"
    @output.puts "# #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    @output.puts "#"
  end

  def read_lines_and_remove_comments()
    @lines = File.readlines(@session_list_file)
    @lines.reject! do |line|
      line.start_with?('#') || line.strip.empty?
    end
  end

  def write_selected_lines()
    interval = (@lines.size / @line_count).to_i
    (1..@line_count).each do |i|
      @output.puts @lines[(i - 1) * interval]
    end
  end

  def write_report()
    report = "#\n#   Wrote #{@line_count} lines.\n#\n"

    @output.print(report)
    print(report) if @output != $stdout
  end

end

