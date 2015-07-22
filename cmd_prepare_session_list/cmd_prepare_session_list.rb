=begin
--------------------------------------------------------------------------------

Create a session list.
You provide a file of URIs, and the tool will generate the URLs needed to fetch
the profile pages for those URIs.

If you want a login on each session, provide the email address and password of
the desired login account.

if credentials are provided, each session looks like this:
LOGIN email password ==> display?uri=uri_from_list
otherwise, like this:
display?uri=uri_from_list

--------------------------------------------------------------------------------

vivosnap.rb prepare session-list [uri_list_file] [account_email:account_password] {session_list_file {REPLACE}}

--------------------------------------------------------------------------------
=end

class CmdPrepareSessionList
  USAGE = 'prepare session-list [uri_list_file] {account_email:account_password} {session_list_file {REPLACE}}'
  
  def initialize(args)
    @args = args
    @replace = true && args.delete('REPLACE')

    complain("usage: #{USAGE}") unless (1..3).include? args.size

    @uri_list_file = confirm_file_exists(args[0])
    @credential, @session_list_file = parse_remaining_args(args)
    @output = set_output_io(@session_list_file, @replace)
  end

  def parse_remaining_args(args)
    case args.size
    when 1
      [nil, nil]
    when 2
      if args[1].include?(':')
        [split_credentials(args[1]), nil]
      else
        [nil, args[1]]
      end
    else # 3
      [split_credentials(args[1]), args[2]]
    end
  end

  def split_credentials(arg)
    complain("usage: #{USAGE}") unless 1 == arg.count(':')
    arg.split(':')
  end

  def run()
    write_heading
    @counter = 0

    File.open(@uri_list_file) do |f|
      f.each_line do |uri|
        next if uri.start_with?('#') || uri.strip.empty?
        @output.puts(make_session(uri))
        @counter += 1
      end
    end

    write_report
  end

  def write_heading()
    @output.puts "#"
    @output.puts "# prepare session-list #{@args.join(' ')}"
    @output.puts "# #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    @output.puts "#"
  end

  def make_session(uri)
    session = @credentials ? "LOGIN %s %s ==> " % @credentials : ''
    session += "display?uri=#{uri}"
  end

  def write_report()
    report = "#\n# wrote #{@counter} session lines.\n#"
    @output.puts(report)
    puts(report) if @output != $stdout
  end
end

