class LocalModel::IntegerAdapter

  def self.write(int)
    "#{int}"
  end

  def self.read(intstr)
    return nil if intstr != '0' && intstr.to_i == 0
    intstr.to_i
  end

end