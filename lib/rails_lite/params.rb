require 'uri'

class Params
  # use your initialize to merge params from
  # 1. query string
  # 2. post body
  # 3. route params
  def initialize(req, route_params = {})
    @params = route_params
    query_params = parse_www_encoded_form(req.query_string)
    post_body = parse_www_encoded_form(req.body)
    @params = @params.merge(query_params)
    @params = @params.merge(post_body)
    @params = @params.merge(route_params)
    @params = deep_merge_all_the_hashes([@params])
    @permitted_keys = []
    @required_key = nil
  end

  def [](key)
    @params[key]
  end

  def permit(*keys)
    @permitted_keys +=  keys
  end

  def require(key)
    raise AttributeNotFoundError if @params[key].nil?
    @params[key.to_sym]
  end

  def permitted?(key)
    # raise AttributeNotFoundError unless @permitted_keys.include?(key)
    @permitted_keys.include?(key)
  end

  def to_s
    self.to_json
  end

  class AttributeNotFoundError < ArgumentError; end;

  private
  # this should return deeply nested hash
  # argument format
  # user[address][street]=main&user[address][zip]=89436
  # should return
  # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
  def parse_www_encoded_form(www_encoded_form)
    return {} if www_encoded_form.nil?
    query_arr = URI::decode_www_form(www_encoded_form)
    # [["user[address][street]", "main"], ["user[address][zip]", "89436"]] 
    params = []
    hashes = []
    query_arr.each do |query| 
      keys = parse_key(query[0])
      value = query[1]
      hashes << nest(keys, value)
    end
    deep_merge_all_the_hashes(hashes)
    
  end
  
  def nest(keys, value)
    if keys.length == 1
      { keys.pop => value}
    else
      { keys[0] => nest(keys[1..-1], value) }
    end
  end
  
  def deep_merge(hash1, hash2)
    if hash1.keys.first != hash2.keys.first 
      { (hash1.keys.first) => hash1.values.first, hash2.keys.first => hash2.values.first }
    else
      { (hash1.keys.first) => deep_merge(hash1[hash1.keys.first], hash2[hash1.keys.first])}
    end
  end
  
  def deep_merge_all_the_hashes(hashes)
    hashes.inject do |accum, hash|
      deep_merge(accum, hash)
    end
  end
  
  # this should return an array
  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    key.scan(/\w+/)
  end

end
