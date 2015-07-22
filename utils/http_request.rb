require 'net/http'
require 'uri'
require 'cgi'

class HttpRequest
  def initialize(url, method = :GET)
    @url = url
    @method = method
    @headers = {}
    @parameters = {}
  end

  def headers(heads)
    @headers = heads
    self
  end

  def parameters(params)
    @parameters = params
    self
  end

  def exec()
    uri = URI.parse(@url)

    Net::HTTP.start(uri.host, uri.port) do |http|
      if @method == :GET
        full_url = add_parameters(uri.request_uri)
        request = Net::HTTP::Get.new(full_url)
      elsif @method == :POST
        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data(@parameters)
      else
        raise 'Method must be :GET or :POST'
      end

      @headers.each_pair { |k, v| request[k] = v }

      begin
        http.request(request) do |response|
          if response.kind_of? Net::HTTPRedirection
            new_url = response['location']
            HttpRequest.new(new_url, @method).headers(@headers).parameters(@parameters).exec do |r|
              yield r if block_given?
            end
          else
            response.value
            yield response if block_given?
          end
        end
      rescue Net::HTTPServerException => e
        raise e.exception(e.message << "\nProblem request: \n#{inspect_request(request, @url)}")
      rescue IOError => e
        raise e.exception(e.message << "\nProblem request: \n#{inspect_request(request, @url)}")
      end
    end
  end

  def add_parameters(request_uri)
    if @parameters.empty?
      request_uri
    elsif request_uri.include?("?")
      request_uri + "&" + URI.encode_www_form(@parameters)
    else
      request_uri + "?" + URI.encode_www_form(@parameters)
    end

  end

  def inspect_request(r, url)
    headers = r.to_hash.to_a.map{|h| "   #{h[0]} ==> #{h[1]}"}.join("\n")
    body = body ? CGI.unescape(r.body) : 'NO BODY'
    "#{r.method} #{url}\n#{headers}\n#{body}"
  end

end
