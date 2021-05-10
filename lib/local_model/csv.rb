class LocalModel::CSV < LocalModel::Model

  extend CSVInteractable::ClassMethods
  include CSVInteractable::InstanceMethods

  def self.schema(&block)
    builder = SchemaBuilder.new(self)
    yield builder

    schema_dict = builder.schema.dup
    self.define_method :get_schema do
      schema_dict
    end

    self.define_singleton_method :get_schema do
      schema_dict
    end

    cols = builder.schema.keys.dup
    self.define_method :columns do
      cols
    end

    self.define_singleton_method :columns do
        cols
    end

    schema_data = cols.each_with_index.reduce({}) do |mem, (key,i)|
      mem[key] = {}
      mem[key][:adapter] = get_adapter(schema_dict[key])
      mem[key][:type] = schema_dict[key]
      mem[key][:column_number] = i
      mem
    end

    self.define_method :schema_data do
      schema_data
    end

    if !File.file?(self.storage_path)
      CSV.open(self.storage_path, 'wb') do |csv|
        csv << cols.map(&:to_s)
      end
    end
  end

  def self.all
    all_instances = []
    each_record do |row|
      all_instances << new_from_record(row)
    end
    all_instances
  end

  def self.destroy_all
    self.all.each{ |obj| obj.destroy }
  end

  def self.where(**args)
    all_records do |row|
      found = true
      args.each do |k,v|
        if row[k] != v
          found = false
          break
        end
      end
      found
    end.map{|r| new_from_record(r) }
  end

  def self.find_by(**args)
    found_record = find_record do |row|
      matched = true
      args.each do |k,v|
        if row[k] != v
          matched = false
          break
        end
      end
      return new_from_record(row) if matched
    end
    nil
  end

  def self.first
    all.first
  end

  def self.second
    all[1]
  end

  def self.last
    all.last
  end

  def self.new_from_record(row)
    obj = new(**row.to_h)
    obj.id = row[:id]
    obj
  end

  def self.find(id)
    return self.find_by(id: id)
  end

  def self.create(**args)
    inst = new(**args)
    inst.save
    inst
  end

  def initialize(**args)
    args.each do |k,v|
      self.send("#{k}=", v)
    end
    self.id = nil
  end

  def saved?
    !self.id.nil?
  end

  def destroy
    self.class.delete_row({id: self.id})
  end

end