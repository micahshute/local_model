class LocalModel::DatetimeAdapter

  def self.write(dt)
    dt.to_i.to_s
  end

  def self.read(dtstr)
    return nil if dtstr == 'nil' || dtstr.to_i == 0
    Time.at(dtstr.to_i)
  end
end