=begin

Some handy methods for checking the validity of command line arguments.

=end

module ArgsChecker
  #
  # Just return the path, if the file exists. Otherwise, complain.
  #
  def confirm_file_exists(path)
    if File.exist?(path)
      path
    else
      complain("'#{path}' does not exist.")
    end
  end

  #
  # Check that this URL will give us a response, and that the response looks
  # at least a little like the VIVO home page.
  #
  # If everything is OK, return the URL
  #
  def confirm_vivo_home_url(url)
    begin
      HttpRequest.new(url).exec do |response|
        complain("Response from '#{url}' does not look like VIVO's home page.") unless response.body =~ /body class="home"/
      end
    rescue
      complain("Can't contact VIVO at '#{url}': #{$!}")
    end

    url
  end

  #
  # If the file is not specified, use standard out.
  # If the file exists and replace is not specified, complain.
  # Otherwise, open the file for writing.
  #
  # In any case, return the output IO.
  #
  def set_output_io(path, replace)
    if path
      complain("'#{path}' already exists. Specify REPLACE to replace it.") if File.exist?(path) unless replace
      File.open(path, 'w')
    else
      $stdout
    end
  end

  #
  # The parameter should be a String representing an integer greater than 0.
  #
  def confirm_positive_integer(count_str)
    begin
      count = count_str.to_i
    rescue
      complain("Not a valid integer: '#{count_str}'")
    end
    complain("Expecting a positive integer, not '#{count_str}'") unless count > 0
    count
  end
end