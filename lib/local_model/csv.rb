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

    self.define_method :schema_defaults do 
      builder.defaults
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

  def self.count
    total = 0
    self.each_record{ total += 1 }
    total
  end

  def self.destroy_all
    delete_all_rows
  end

  def self.where(**args)
    arr = all_records do |row|
      found = true
      args.each do |k,v|
        if row[k] != v
          found = false
          break
        end
      end
      found
    end.map{|r| new_from_record(r) }
    LocalModel::Collection.create_from(
      array: arr,
      for_model: self,
      for_collection_class: nil,
      add_to_collection_proc: ->(a,b) { raise NoMethodError.new("Cannot add to this collection") }
    )
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
    found_record = self.find_by(id: id)
    if !found_record
      raise LocalModel::RecordNotFound.new
    else
      found_record
    end
  end

  def self.find_or_create_by(**args)
    found_obj = find_by(**args)
    return found_obj if found_obj
    create(**args)
  end

  # TODO: Move necessary methods to model.rb

  def self.create(**args)
    inst = new(**args)
    inst.save
    inst
  end

  def self.create!(**args)
    inst = new(**args)
    inst.save!
    inst
  end

  def initialize(**args)
    self.schema_defaults.each do |property, value|
      self.send("#{property}=", value)
    end
    args.each do |k,v|
      self.send("#{k}=", v)
    end
    self.id = nil
  end

  def saved?
    !self.id.nil?
  end
  
  def reload
    raise LocalModel::RecordNotFound if !self.id
    self.class.find(self.id)
  end

  def destroy
    self.class.delete_row({id: self.id})
  end

end