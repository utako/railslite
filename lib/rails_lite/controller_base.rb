require 'erb'
require 'active_support/inflector'
require_relative 'params'
require_relative 'session'

module ProtectFromForgery
  
  def protect_from_forgery(options = {})
    if options == { with: :exception }
      @protection_action = :raise_exception
    else      
      @protection_action = :reset_session!
    end
    @protect_from_forgery = true
  end
  
  def csrf_token_verified?
    params[:csrf_token] == session[:csrf_token]
  end
  
  def form_authenticity_token
    session[:csrf_token] ||= SecureRandom.hex
  end  

end


class ControllerBase
  
  include ProtectFromForgery
  
  attr_reader :params, :req, :res

  # setup the controller
  def initialize(req, res, route_params = {})
    @params = Params.new(req, route_params)
    @req = req
    @res = res
    @protect_from_forgery = false
    @protection_action = nil
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
  
  def flash
    session[:flash]
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
  
  def reset_session!
    @session = Session.new(req)
  end
  
  def raise_exception
    raise "CSRF Token Error"
  end
  
  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(action_name)
    unprotected_actions = [:index, :show, :edit, :new]
    if (unprotected_actions.include?(action_name) || 
        @protect_from_forgery == false ) || 
           csrf_token_verified?
      self.send(action_name)
    else
      self.send(@protection_action)
    end
  end
  
end
