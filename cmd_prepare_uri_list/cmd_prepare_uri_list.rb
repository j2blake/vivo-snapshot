=begin
--------------------------------------------------------------------------------

execute LISTRDF requests, like this:
http://localhost:8080/vivo/listrdf?vclass=http%3A%2F%2Fvivoweb.org%2Fontology%2Fcore%23FacultyMember

write the results to the file, one URI per line.

--------------------------------------------------------------------------------
=end

class CmdPrepareUriList
  USAGE = 'prepare uri-list [class_list_file] [VIVO_homepage_URL] {uri_list_file {REPLACE}}'
  def initialize(args)
    @args = args
    @replace = args.delete('REPLACE')
    
    complain("usage: #{USAGE}") unless (2..3).include? args.size

    @class_list_file = confirm_file_exists(args[0])
    @vivo_home_url = confirm_vivo_home_url(args[1])
    @output = set_output_io(args[2], @replace)
  end

  def run()
    write_heading
    @stats = []

    File.open(@class_list_file) do |f|
      f.each_line do |line|
        line.strip!
        perform_listrdf(line) unless line.empty? || line.start_with?('#')
      end
    end

    write_report
  end

  def perform_listrdf(class_uri)
    HttpRequest.new(listrdf_url).parameters('vclass' => class_uri).headers('Accept' => 'text/plain').exec do |response|
      process_response(class_uri, response.body.lines)
    end
  end

  def process_response(class_uri, lines)
    @stats << [class_uri, lines.size]
    @output.puts
    @output.puts "# class = #{class_uri}"
    @output.puts

    lines.each do |line|
      if line =~ /<([^>]+)>/
        @output.puts $1
      else
        warning("Unexpected line in response '#{line}'")
      end
    end
  end

  def listrdf_url()
    if @vivo_home_url.end_with?('/')
      @vivo_home_url + 'listrdf'
    else
      @vivo_home_url + '/listrdf'
    end
  end

  def write_heading()
    @output.puts "#"
    @output.puts "# prepare uri-list #{@args.join(' ')}"
    @output.puts "# #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    @output.puts "#"
  end

  def write_report()
    width = @stats.map { |s| s[0].size }.max

    report = "\n"
    @stats.each do |s|
      report += "#   %-#{width}s  %5d \n" % s
    end
    report += "#   %-#{width}s  %5d \n" % ['TOTAL', @stats.map{|s| s[1]}.inject(:+)]

    @output.print(report)
    print(report) if @output != $stdout
  end
end
