require 'active_support/cache/dalli_store'
require 'active_support/core_ext/module/aliasing'

ActiveSupport::Cache::DalliStore.class_eval do
    
  CACHE_KEYS = "CacheKeys"
  
  alias_method :old_write_entry, :write_entry
  def write_entry(key, entry, options)
    keys = get_cache_keys
    unless keys.include?(key)
      keys << key
      return false unless old_write_entry(CACHE_KEYS, keys.to_yaml, {})
    end
    old_write_entry(key, entry, options)
  end
  
  alias_method :old_delete_entry, :delete_entry
  def delete_entry(key, options)
    ret = old_delete_entry(key, options)
    return false unless ret
    keys = get_cache_keys
    if keys.include?(key)
      keys -= [ key ]
      old_write_entry(CACHE_KEYS, keys.to_yaml, {})
    end
    ret
  end
  
  def delete_matched(matcher, options = nil)
    ret = true
    ret_all = []
    deleted_keys = []
    keys = get_cache_keys
    keys.each do |key|
      if key.match(matcher)
        ret_all << old_delete_entry(key, options)
        deleted_keys << key
      end
    end
    # CHANGED don't care if key was deleted
    # len = keys.length
    # keys -= deleted_keys
    old_write_entry(CACHE_KEYS, keys.to_yaml, {}) # if keys.length < len
    ret_all.all?
  end

private
  def get_cache_keys
    begin
      YAML.load read(CACHE_KEYS)
    rescue TypeError
      []
    end
  end
  
end