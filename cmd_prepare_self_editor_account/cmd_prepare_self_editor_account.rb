=begin
--------------------------------------------------------------------------------

Write triples to the user accounts model of the VIVO to create the
self-editor-account (unless it exists already), and to make it a proxy editor for
all of the URLs in the list.

--------------------------------------------------------------------------------

Export the user-accounts model and parse it as RDF.
Note whether the editor account already exists, by email.
  If so,
    get the URI
    Complain if not a SELF_EDITOR
    Complain if not at least one login
    Complain if the md5 password is not the one we were planning to use.
  Otherwise,
    Generate triples to create the account.
       URI is <http://vivosnap.proxy/{timestamp}
       Name is VIVOSNAP PROXY
       email and password as provided
       SELF_EDITOR
       lastLoginTime now
       loginCount = 1
       status = ACTIVE
Generate triples
  URI proxyEditorFor each URI in the list
Upload the triples file.

--------------------------------------------------------------------------------

vivosnap.rb prepare self-editor-account [VIVO_homepage_URL] [uri_list_file] [admin_email:admin_password] [editor_email:editor_password]

--------------------------------------------------------------------------------

Annoying: all serialization formats remove the datatype from a String literal,
so the literal becomes plain. It doesn't look like this will cause a problem for
VIVO, but it's still annoying.

--------------------------------------------------------------------------------

Need to be logged in for the query
http://localhost:8080/vivo/programLogin?email=testAdmin@mydomain.edu&password=Password

Need to select the config models or we have a real problem!! Creates an empty
user model in the content triple store.

The query request
http://localhost:8080/vivo/ingest?action=outputModel&modelName=http%3A%2F%2Fvitro.mannlib.cornell.edu%2Fdefault%2Fvitro-kb-userAccounts
http://localhost:8080/vivo/ingest ?
        action=outputModel &
        modelName=http%3A%2F%2Fvitro.mannlib.cornell.edu%2Fdefault%2Fvitro-kb-userAccounts

Info on parsing and querying here: http://blog.datagraph.org/2010/03/rdf-for-ruby

--------------------------------------------------------------------------------

The upload request
   POST http://localhost:8080/vivo/uploadRDF
   modelName=http://vitro.mannlib.cornell.edu/default/vitro-kb-userAccounts
   action="loadRDFData"
   filePath=[file contents]
   language="N-TRIPLE"
   submit="Load Data"

http://ruby-doc.org/stdlib-2.0.0/libdoc/net/http/rdoc/Net/HTTPHeader.html#method-i-set_form

--------------------------------------------------------------------------------

The account record:
PREFIX auth: <http://vitro.mannlib.cornell.edu/ns/vitro/authorization#>
<http://vivo.mydomain.edu/individual/u3804>
        a                        auth:UserAccount ;
        auth:emailAddress        "proxy@mydomain.edu"^^xsd:string ;
        auth:firstName           "Proxy"^^xsd:string ;
        auth:hasPermissionSet    auth:SELF_EDITOR ;
        auth:lastName            "Proxy"^^xsd:string ;
        auth:loginCount          "1"^^xsd:int ;
        auth:md5password         "DC647EB65E6711E155375218212B3964"^^xsd:string ;
        auth:proxyEditorFor      <http://vivo.mydomain.edu/individual/n3765> ;
        auth:status              "ACTIVE"^^xsd:string .

--------------------------------------------------------------------------------

The proxy relationship
     <http://vitro.mannlib.cornell.edu/ns/vitro/authorization#proxyEditorFor>
            <http://vivo.mydomain.edu/individual/n3236> ;

--------------------------------------------------------------------------------
=end
require 'cgi'
require 'rubygems'
require 'httpclient'
require 'rdf'
require 'rdf/raptor'
require 'tempfile'

class CmdPrepareSelfEditorAccount
  include ::ArgsChecker

  USAGE = 'prepare self-editor-account [VIVO_homepage_URL] [uri_list_file] [admin_email:admin_password] [editor_email:editor_password]'

  USER_MODEL = 'http://vitro.mannlib.cornell.edu/default/vitro-kb-userAccounts'

  AUTH_EMAIL_ADDRESS = RDF::URI.new('http://vitro.mannlib.cornell.edu/ns/vitro/authorization#emailAddress')
  AUTH_FIRST_NAME = RDF::URI.new('http://vitro.mannlib.cornell.edu/ns/vitro/authorization#firstName')
  AUTH_HAS_PERMISSIONS = RDF::URI.new('http://vitro.mannlib.cornell.edu/ns/vitro/authorization#hasPermissionSet')
  AUTH_LAST_NAME = RDF::URI.new('http://vitro.mannlib.cornell.edu/ns/vitro/authorization#lastName')
  AUTH_LOGIN_COUNT = RDF::URI.new('http://vitro.mannlib.cornell.edu/ns/vitro/authorization#loginCount')
  AUTH_MD5_PASSWORD = RDF::URI.new('http://vitro.mannlib.cornell.edu/ns/vitro/authorization#md5password')
  AUTH_PROXY_EDITOR_FOR = RDF::URI.new('http://vitro.mannlib.cornell.edu/ns/vitro/authorization#proxyEditorFor')
  AUTH_SELF_EDITOR = RDF::URI.new('http://vitro.mannlib.cornell.edu/ns/vitro/authorization#SELF_EDITOR')
  AUTH_STATUS = RDF::URI.new('http://vitro.mannlib.cornell.edu/ns/vitro/authorization#status')
  AUTH_USER_ACCOUNT = RDF::URI.new('http://vitro.mannlib.cornell.edu/ns/vitro/authorization#UserAccount')

  def initialize(args)
    @args = args

    complain("usage: #{USAGE}") unless 4 == args.size

    @vivo_home_url = confirm_vivo_home_url(args[0])
    @uri_list_file = confirm_file_exists(args[1])
    @admin_email, @admin_password = split_credentials(args[2])
    @proxy_email, @proxy_password = split_credentials(args[3])
  end

  def split_credentials(arg)
    complain("usage: #{USAGE}") unless 1 == arg.count(':')
    arg.split(':')
  end

  def run()
    look_for_existing_self_editor
    prepare_upload_rdf_file
    upload_rdf
    report
  end

  def look_for_existing_self_editor
    export_user_model
    parse_user_model
    inspect_user_model
  end

  def export_user_model()
    @session = HTTPClient.new

    login_parms = { 'email' => @admin_email, 'password' => @admin_password }
    res = @session.get(add_to_home_url(@vivo_home_url, 'programLogin'), login_parms, nil, true)
    raise UserInputError.new("Invalid admin credentials: #{@admin_email}:#{@admin_password}") unless res.status == 200

    parms = {'action' => 'configModels', 'modelName' => USER_MODEL}
    res = @session.get(add_to_home_url(@vivo_home_url, 'ingest'), parms, nil, true)
    raise "Failed to show configModels." unless res.content.include?(USER_MODEL)

    export_parms = {'action' => 'outputModel', 'modelName' => USER_MODEL}
    res = @session.get(add_to_home_url(@vivo_home_url, 'ingest'), export_parms, nil, true)
    raise "Failed to export the User Accounts model." unless res.status == 200

    @user_model_string = res.content
  end

  def parse_user_model()
    @user_model_graph = RDF::Graph() do |graph|
      RDF::Reader.for(:turtle).new(@user_model_string) do |reader|
        reader.each_statement do |statement|
          graph << statement
        end
      end
    end
  end

  def inspect_user_model()
    @editor_uri = nil
    @create_editor = true

    editor_email_stmt = @user_model_graph.first([nil, AUTH_EMAIL_ADDRESS, RDF::Literal.new(@proxy_email)])
    return unless editor_email_stmt

    editor = editor_email_stmt.subject

    self_editor_stmt = @user_model_graph.first([editor, AUTH_HAS_PERMISSIONS, AUTH_SELF_EDITOR])
    raise "An account for #{@proxy_email} already exists, but is not a self-editor." unless self_editor_stmt

    login_count = @user_model_graph.first_literal([editor, AUTH_LOGIN_COUNT, nil])
    raise "An account for #{@proxy_email} already exists, but has never logged in." unless login_count && login_count.value.to_i > 0

    md5_password = @user_model_graph.first_literal([editor, AUTH_MD5_PASSWORD, nil])
    raise "An account for #{@proxy_email} already exists, but the password is not '#{@proxy_password}'." unless md5_password && md5_password.to_s == encode_md5(@proxy_password)

    @editor_uri = editor.to_s
    @create_editor = false
  end

  def add_to_home_url(home_url, path)
    if home_url.end_with?('/')
      home_url + path
    else
      home_url + '/' + path
    end
  end

  def prepare_upload_rdf_file
    insert_account_statements unless @editor_uri
    insert_proxy_statements
    write_graph_to_a_file
  end

  def insert_account_statements()
    @editor_uri = "http://vivosnap.proxy/#{Time.now.to_f}"
    editor = RDF::URI.new(@editor_uri)

    @user_model_graph << RDF::Statement.new(editor, RDF::type, AUTH_USER_ACCOUNT)
    @user_model_graph << RDF::Statement.new(editor, AUTH_EMAIL_ADDRESS, string_literal(@proxy_email))
    @user_model_graph << RDF::Statement.new(editor, AUTH_FIRST_NAME, string_literal('VIVOSNAP'))
    @user_model_graph << RDF::Statement.new(editor, AUTH_HAS_PERMISSIONS, AUTH_SELF_EDITOR)
    @user_model_graph << RDF::Statement.new(editor, AUTH_LAST_NAME, string_literal('PROXY'))
    @user_model_graph << RDF::Statement.new(editor, AUTH_LOGIN_COUNT, RDF::Literal.new(1))
    @user_model_graph << RDF::Statement.new(editor, AUTH_MD5_PASSWORD, string_literal(encode_md5(@proxy_password)))
    @user_model_graph << RDF::Statement.new(editor, AUTH_STATUS, string_literal('ACTIVE'))
  end

  def insert_proxy_statements
    @proxy_count = 0
    editor = RDF::URI.new(@editor_uri)
    File.open(@uri_list_file) do |f|
      f.each_line do |uri|
        next if uri.start_with?('#') || uri.strip.empty?
        @user_model_graph << RDF::Statement.new(editor, AUTH_PROXY_EDITOR_FOR, RDF::URI.new(uri.strip))
        @proxy_count += 1
      end
    end
  end

  def write_graph_to_a_file()
    @temp_file = Tempfile.new('user_model')
    RDF::Writer.for(:ntriples).new(@temp_file) do |writer|
      @user_model_graph.each_statement do |statement|
        writer << statement
      end
    end
    @temp_file.rewind
  end

  def upload_rdf
    begin
      parms = { 'action' => 'loadRDFData', 'modelName' => USER_MODEL, 'filePath' => @temp_file, 'language' => 'N-TRIPLE' }
      res = @session.post(add_to_home_url(@vivo_home_url, 'uploadRDF'), parms)
      raise "Failed to load the user model: status is #{res.status}." unless res.status == 200
    ensure
      @temp_file.close
      @temp_file.unlink
    end
  end

  def string_literal(s)
    RDF::Literal.new(s, :datatype => RDF::XSD.string)
  end

  def encode_md5(raw)
    Digest::MD5.new.digest(raw).each_byte.map { |b| b.to_s(16) }.join.upcase
  end

  def report()
    puts
    if @create_editor
      puts "Created user account #{@proxy_email}:#{@proxy_password}"
    else
      puts "Found existing user account #{@proxy_email}:#{@proxy_password}"
    end
    puts "Set #{@proxy_count} auth:proxyEditorFor statements on #{@editor_uri}"
    puts
  end

end

