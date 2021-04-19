class LocalModel::StringAdapter


  def self.write(str)
    str.to_s
  end

  def self.read(str)
    str == 'nil' ? nil : str
  end

end