require 'json'
require 'webrick'

class Flash
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    @cookie_hash = {}
    req.cookies.each do |cookie|
      if cookie.name == '_rails_lite_app_flash'
        @cookie_hash = JSON.parse(cookie.value)
      end
    end
  end

  def [](key)
    @cookie_hash[key]
  end

  def []=(key, val)
    @cookie_hash[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_flash(res)
    res.cookies << WEBrick::Cookie.new('_rails_lite_app_flash', @cookie_hash.to_json)
  end
end
