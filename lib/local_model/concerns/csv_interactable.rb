module CSVInteractable

  module ClassMethods

    @@rand = Random.new

    def write_headers
      CSV.open(self.storage_path, 'wb') do |csv|
        csv << columns.map(&:to_s)
      end
    end

    def mutate_csv(option=:mutate,&block)
      while File.exist?("#{self.storage_path}.bak.csv")
        r = @@rand.rand / 10.0
        sleep(r)
      end
      rand_val = @@rand.rand(1000000)
      f = File.new("#{self.storage_path}-#{rand_val}.prep", 'w')
      f.close
      r = @@rand.rand / 10.0
      sleep(r)

      if File.exist?("#{self.storage_path}.bak.csv") || Dir["#{self.storage_path}-*.prep"].length > 1
        File.delete("#{self.storage_path}-#{rand_val}.prep")
        if @@rand.rand(2) == 1
          sleep(0.5)
        end
        mutate_csv
        return
      else
        File.delete("#{self.storage_path}-#{rand_val}.prep")
        last_id = 0
        CSV.open("#{self.storage_path}.bak.csv", 'wb', headers: self.get_schema.keys.map(&:to_s), write_headers: true, header_converters: [:symbol, :downcase]) do |csv_bak|
          CSV.open(self.storage_path, 'r', headers: true, header_converters: [:symbol, :downcase]) do |csv_orig|
            csv_orig.each do |row|
              csv_bak << row
              last_id = get_adapter(:integer).read(row[:id])
            end
          end
        end
        if option == :mutate
          CSV.open("#{self.storage_path}.bak.csv", 'r', headers: true, header_converters: [:symbol, :downcase]) do |csv_bak|
            CSV.open(self.storage_path, 'w', headers: self.get_schema.keys.map(&:to_s), write_headers: true,  header_converters: [:symbol, :downcase]) do |csv_orig|
              csv_bak.each do |bak_row|
                prep_row_read!(bak_row)
                yield(csv_orig, bak_row)
              end
            end
          end
        else
          CSV.open(self.storage_path, 'a', headers: true, header_converters: [:symbol, :downcase]) do |csv|
            yield(csv, last_id)
          end
        end
        File.delete("#{self.storage_path}.bak.csv")
      end
    end

    def read_from_record(row)
      row = row.to_h
      row.reduce({}) do |mem, (k,v)|
        data_type = self.get_schema[k]
        adapter = get_adapter[data_type]
        mem[k] = adapter.read(v)
      end
    end

    def new_from_record(row)
      formatted_hash = read_from_record(row)
      inst = self.new(**formatted_hash)
      inst.id = formatted_hash[:id]
      inst
    end

    def get_adapter(data_type)
      case data_type
      when :integer
        LocalModel::IntegerAdapter
      when :boolean
        LocalModel::BooleanAdapter
      when :float
        LocalModel::FloatAdapter
      when :datetime
        LocalModel::DatetimeAdapter
      when :string
        LocalModel::StringAdapter
      else
        raise ArgumentError.new("Incorrect datatype entered (#{data_type})")
      end
    end

    def prep_row_read!(row)
      row_hash = row.to_h
      row_hash.each do |k,v|
        data_type = get_schema[k]
        adapter = get_adapter(data_type)
        row[k] = adapter.read(v)
      end
      row
    end

    def prep_row_write!(row)
      row_hash = row.to_h
      row_hash.each do |k,v|
        data_type = get_schema[k]
        adapter = get_adapter(data_type)
        row[k] = adapter.write(v)
      end
      row
    end

    def find_record(mode: 'r', &block)
      CSV.open(self.storage_path, mode, headers: true, header_converters: [:symbol, :downcase]) do |csv|
        csv.each do |row|
          prep_row_read!(row)
          return row if yield(row)
        end
        return nil
      end
    end

    def each_record(mode: 'r', &block)
      CSV.open(self.storage_path, mode, headers: true, header_converters: [:symbol, :downcase]) do |csv|
        csv.each do |row|
          prep_row_read!(row)
          yield(row)
        end
      end
    end

    def all_records(mode: 'r', &block)
      records = []
      CSV.open(self.storage_path, mode, headers: true, header_converters: [:symbol, :downcase]) do |csv|
        csv.each do |row|
          prep_row_read!(row)
          records << row if yield(row)
        end
      end
      records
    end

    def append_row(data, should_add_id: true)
      row = data.reduce(CSV::Row.new([],[])) do |mem, (k,v)|
        data_type = get_schema[k]
        adapter = get_adapter(data_type)
        mem[k] = adapter.write(v)
        mem
      end
      begin
        ret_val = nil
        self.mutate_csv(:append) do |csv, last_id|
          if should_add_id
            ret_val = last_id + 1
            row[:id] = get_adapter(:integer).write(last_id + 1)
          end
          csv << row
        end
        ret_val
      rescue => e
        File.delete("#{self.storage_path}.bak.csv") if File.exist?("#{self.storage_path}.bak.csv")
        raise e
        false
      end
    end

    def mutate_row(data)
      begin
        self.mutate_csv(:mutate) do |csv, bak_row|
          if bak_row[:id] == data[:id]
            data.each do |k,v|
              bak_row[k] = data[k]
            end
            prep_row_write!(bak_row)
            csv << bak_row
          else
            prep_row_write!(bak_row)
            csv << bak_row
          end
        end
        true
      rescue => e
        File.delete("#{self.storage_path}.bak.csv")
        false
      end
    end

    def delete_row(data)
      begin
        self.mutate_csv(:mutate) do |csv, bak_row|
          if bak_row[:id] != data[:id]
            prep_row_write!(bak_row)
            csv << bak_row
          end
        end
        true
      rescue
        File.delete("#{self.storage_path}.bak.csv")
        false
      end
    end

  end

  module InstanceMethods
    def save
      model_schema = self.class.get_schema
      self_data = model_schema.reduce({}) do |mem, (k,v)|
        mem[k] = self.send(k)
        mem
      end
      if self.id.nil?
        id = self.class.append_row(self_data)
        self.id = id
        !!id
      else
        return self.class.mutate_row(self_data)
      end
    end

    def save!
      if !save
        raise LocalModel::RecordInvalid
      end
    end

  end

end