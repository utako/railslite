require 'erb'
require 'active_support/inflector'
require_relative 'params'
require_relative 'session'


class ControllerBase
  attr_reader :params, :req, :res

  # setup the controller
  def initialize(req, res, route_params = {})
    @params = Params.new(req, route_params)
    @req = req
    @res = res
  end

  # populate the response with content
  # set the responses content type to the given type
  # later raise an error if the developer tries to double render
  def render_content(content, type)
    raise "already rendered" if already_built_response?
    @res.body = content
    @res.content_type = type
    @already_built_response = true
    session.store_session(@res)
  end

  # helper method to alias @already_built_response
  def already_built_response?
    @already_built_response ||= false
  end

  # set the response status code and header
  def redirect_to(url)
    raise "already redirected" if already_built_response?
    @res.status = 302
    @res["Location"] = url
    @already_built_response = true
    session.store_session(@res)
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    file_path = "./views/#{self.class.to_s.underscore}/#{template_name}.html.erb"
    template = File.read(file_path)
    compiled_template = ERB.new(template)
    content = compiled_template.result(binding)
    type = 'text/html'
    render_content(content, type)
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req) 
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(action_name)
    self.send(action_name)
    # render(sometemplatename) unless already_built_response?
  end
end
