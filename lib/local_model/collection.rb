class LocalModel::Collection < Array

    def self.create_from(array: , for_model: , for_collection_class:, add_to_collection_proc:)
       new_obj = new(array)
       new_obj.model = for_model 
       new_obj.collection_class = for_collection_class
       new_obj.add_to_collection = add_to_collection_proc
       new_obj
    end

    attr_accessor :model, :collection_class, :add_to_collection

    def <<(arg)
        self.push(arg)
    end

    def push(arg)
        self.[]=(self.length, arg)
        raise ArgumentError.new("#{arg.class} inputted, expecting #{self.collection_class}") if !arg.is_a?(self.collection_class)
        add_to_collection[arg, self.model]
        arg.save && self.model.save
    end

    def build(**args)
        self.push(collection_class.create(**args))
    end

    def where(**args)
        self.filter do |el|
            found = true
            args.each do |k,v|
                if el.send(k.to_s) != v
                    found = false
                    break
                end
            end
            found
        end
    end

end