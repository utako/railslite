require 'json'
require 'webrick'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    @cookie_hash = {}
    @flash_hash = {}
    req.cookies.each do |cookie|
      if cookie.name == '_rails_lite_app'
        @cookie_hash = JSON.parse(cookie.value)
      end
    end
    @flash_hash = @cookie_hash.select { |key, value| key == :flash }
    @cookie_hash.delete_if { |key, value| key == :flash }
  end

  def [](key)
    if key == :flash
      @flash_hash[key]
    else
      @cookie_hash[key]
    end
  end

  def []=(key, val)
    @cookie_hash[key] = val
  end
  
  

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    res.cookies << WEBrick::Cookie.new('_rails_lite_app', @cookie_hash.to_json)
  end

end