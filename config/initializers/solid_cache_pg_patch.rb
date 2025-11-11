# Fix for motor admin and solid_cache issue when PG::Result is attempted to be marshaled
module MarshalPGSkip
  def dump(obj)
    return nil if obj.is_a?(PG::Result)
    super
  end
end

Marshal.singleton_class.prepend(MarshalPGSkip)
