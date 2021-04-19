class LocalModel::BooleanAdapter

  def self.write(bool)
    bool.to_s
  end

  def self.read(boolstr)
    boolstr == "true"
  end

end