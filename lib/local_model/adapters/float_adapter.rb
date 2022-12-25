class LocalModel::FloatAdapter

  def self.write(fl)
    "#{fl}"
  end

  def self.read(flstr)
    str = fltstr.strip
    str =~ /^[+-]?([1-9]\d*|0)(\.\d+)?$/ ? str.to_f : nil
  end

end