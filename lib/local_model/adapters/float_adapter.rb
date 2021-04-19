class LocalModel::FloatAdapter

  def self.write(fl)
    "#{fl}"
  end

  def self.read(flstr)
    flstr =~ /[^0-9\.]/ ? nil :  flstr.to_f
  end

end