require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative './session'
require_relative './flash'

class ControllerBase
  attr_reader :req, :res, :params

  def initialize(req, res, route_params = {})
    @req, @res = req, res
    @params = route_params.merge(req.params)
    @params.keys.each {|k| @params[k.to_sym] = @params[k]}
  end

  # Use ERB and binding to render templates

  def render(arg)
    return render_template arg unless arg.is_a?(Hash)
    render_json arg[:json] if arg[:json]
  end

  def render_template(template_name)
    app_template = ERB.new(File.read('views/application.html.erb'))

    snake_case_class_name = self.class.to_s.underscore
    template_path = "views/#{snake_case_class_name}/#{template_name}.html.erb"
    action_template = File.read(template_path)

    html = app_template.result(self.get_binding {
      ERB.new(action_template).result(binding)
    })

    html.gsub!(/[\r\n]+/, "\n").gsub(/ +/, ' ')
    render_content(html, 'text/html')
  end

  def render_json(obj)
    render_content(obj.to_json, 'application/json')
  end

  def get_binding
    binding
  end

  # Redirect to specified URL

  def redirect_to(url)
    raise 'cannot render or redirect more that once' if already_built_response?
    @already_built_response = true

    session.store_session(res)
    flash.store_flash(res)

    res['Location'] = url
    res.status = 302
  end

  # Render a response. Raises an error if the caller tries to double
  # render or redirect.

  def render_content(content, content_type)
    raise 'cannot render or redirect more that once' if already_built_response?
    @already_built_response = true

    res['Content-Type'] = content_type
    res.write(content)
  end

  # Did we already render or redirect?

  def already_built_response?
    @already_built_response ||= false
  end

  # Retrieve current Session object

  def session
    @session ||= Session.new(@req)
  end

  # Retrieve current Flash object

  def flash
    @flash ||= Flash.new(@req)
  end

  # Invoke controller actions (e.g., :index, :show, :create)

  def invoke_action(name)
    if (protect_from_forgery? && @req.request_method != 'GET')
      check_authenticity_token
    end

    @@before_actions.map do |filter, options|
      invoke_filter(filter, name, options)
    end

    send(name)

    @@after_actions.map do |filter, options|
      invoke_filter(filter, name, options)
    end

    session.store_session(res)
    flash.store_flash(res)

    render(name) unless already_built_response?
  end

  #  CSRF protection

  def self.protect_from_forgery
    @@protect_from_forgery = true;
  end

  def check_authenticity_token
    cookie = @req.cookies['_tracks_app_token']
    raise 'Invalid authenticity token' unless
      cookie && cookie == params['authenticity_token']
  end

  def form_authenticity_token
    @token ||= generate_authenticity_token
    @res.set_cookie('_tracks_app_token', value: @token)
    @token
  end

  def generate_authenticity_token
    SecureRandom.urlsafe_base64(16)
  end

  def protect_from_forgery?
    @@protect_from_forgery
  end

  def self.before_action(name, options)
    @@before_actions << [ name, options ]
  end

  def self.after_action(name, options)
    @@after_actions << [ name, options ]
  end

  def invoke_filter(filter, action, options)
    return unless !options[:only] || options[:only].include?(action.to_sym)
    return if options[:except] && options[:except].include?(action.to_sym)
    send(filter)
  end

  private

  @@protect_from_forgery = false
  @@before_actions = []
  @@after_actions = []

end
