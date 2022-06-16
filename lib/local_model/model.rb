class LocalModel::Model

  def self.schema(&block)
    raise NoMethodError.new("self.schema must be defined")
    # yield(SchemaBuilder.new(self))
  end

  def self.belongs_to(association, class_name: nil, foreign_key: nil, polymorphic: false)
    if foreign_key.nil?
      keyname = "#{association}_id"
      typename = "#{association}_type"
    else
      keyname = foreign_key
    end

    if class_name.nil?
      association_class_name = LocalModel::Functions.snake_to_camel(association)
      association_class_name[0] = association_class_name[0].upcase
      association_class_name = namespace_classname(association_class_name)
    else
      association_class_name = namespace_classname(class_name)
    end


    define_method association do
      if polymorphic
        association_type = self.send(typename)
        return nil if association_type.nil? || association_type.empty?
        polymorphic_class_name = LocalModel::Functions.snake_to_camel(association_type.gsub("_type", ""))
        polymorphic_class_name[0] = polymorphic_class_name[0].upcase
        association_class = Object.const_get(polymorphic_class_name)
      else
        association_class = Object.const_get(association_class_name)
      end
      id = self.send(keyname)
      association_class.find(id)
    end

    define_method "#{association}=" do |association_obj|
      self.send("#{keyname}=", association_obj&.id)
      if polymorphic
        if !association_obj.nil?
          self.send("#{typename}=", association_obj.class.to_s)
        end
      end
    end
  end

  def self.has_many(association, through: nil, class_name: nil, foreign_key: nil, as: nil)
    if class_name.nil?
      association_classname = namespace_classname(get_classname_from_association(association))
    else
      association_classname = namespace_classname(class_name)
    end

    if through.nil?
      if as.nil?
        current_class_id_methodname = foreign_key || "#{LocalModel::Functions.camel_to_snake(denamespace_classname(self))}_id"
      else
        current_class_id_methodname = "#{as}_id"
      end
      belongs_to_id_sym = current_class_id_methodname.to_sym
      add_to_collection = Proc.new do |arg, model|
        arg.send("#{belongs_to_id_sym}=", model.id)
      end

      define_method association do
        collection_args = {belongs_to_id_sym => self.id}
        if !as.nil?
          collection_args["#{as}_type".to_sym] = self.class.to_s
        end

        association_class = Object.const_get(association_classname)
        LocalModel::Collection.create_from(
          array: association_class.where(**collection_args),
          for_model: self,
          for_collection_class: association_class,
          add_to_collection_proc: add_to_collection
        )
      end
    else
      current_class_id_methodname = foreign_key || "#{LocalModel::Functions.camel_to_snake(LocalModel::Functions.singularize(association))}_id"
      belongs_to_id_sym = current_class_id_methodname.to_sym
      add_to_collection = Proc.new do |arg, model|
        through_collection = model.send(through)
        through_classname = through_collection.collection_class
        new_join = through_classname.new
        new_join.send("#{belongs_to_id_sym}=", arg.id)
        through_collection << new_join
      end
      define_method association do 
        association_class = Object.const_get(association_classname)
        LocalModel::Collection.create_from(
          array: self.send(through).map{|through_obj| association_class.find(through_obj.send(belongs_to_id_sym))},
          for_model: self,
          for_collection_class: association_class,
          add_to_collection_proc: add_to_collection
        )
      end
    end
  end

  def self.has_one(association, through: nil, class_name: nil, foreign_key: nil, as: nil)
    if class_name.nil?
      association_classname = LocalModel::Functions.snake_to_camel(association)
      association_classname[0] = association_classname[0].upcase
      association_classname = namespace_classname(association_classname)
    else
      association_classname = namespace_classname(class_name)
    end

    if through.nil?
      if as.nil?
        current_class_id_methodname = foreign_key || "#{LocalModel::Functions.camel_to_snake(denamespace_classname(self))}_id"
      else
        current_class_id_methodname = "#{as}_id"
      end
      belongs_to_id_sym = current_class_id_methodname.to_sym
      define_method association do 
        collection_args = {belongs_to_id_sym => self.id}
        if !as.nil?
          collection_args["#{as}_type".to_sym] = self.class.to_s
        end
        association_class = Object.const_get(association_classname)
        association_class.where(**collection_args).first
      end
    else
      current_class_id_methodname = foreign_key || "#{LocalModel::Functions.camel_to_snake(association)}_id"
      belongs_to_id_sym = current_class_id_methodname.to_sym
      define_method association do 
        association_class = Object.const_get(association_classname)
        association_class.where(id: self.send(through)&.send(belongs_to_id_sym)).first
      end
    end
  end

  def self.get_classname_from_association(association)
    association_portions = association.to_s.split('_')
    association_portions_last = association_portions.last
    singular_association_last = LocalModel::Functions.singularize(association_portions_last)
    singularized_association = association_portions[0...-1] + [singular_association_last]
    singularized_snakecase = singularized_association.join('_')
    classname = LocalModel::Functions.snake_to_camel(singularized_snakecase)
    classname[0] = classname[0].upcase
    classname
  end
  private_class_method :get_classname_from_association

  def self.denamespace_classname(classname)
    return classname.to_s.split("::").last
  end
  private_class_method :denamespace_classname

  def self.namespace_classname(classname)
    if LocalModel.namespaced?
      "#{LocalModel.namespace}::#{classname}"
    else
      classname
    end
  end
  private_class_method :namespace_classname

  def self.storage_path
    slash = LocalModel.path == '/' ? '' : '/'
    "#{LocalModel.path}#{slash}#{self}.csv"
  end

  def update(**args)
    args.each do |k,v|
      self.send("#{k.to_s}=", v)
    end
    self.save
  end

  def update!(**args)
    args.each do |k,v|
      self.send("#{k.to_s}=", v)
    end
    self.save!
  end

  def reload
    self.class.find(self.id)
  end

  def ==(other)
    self.class == other.class && 
    self.id == other.id
  end


  class SchemaBuilder

    attr_reader :schema

    def initialize(model)
      @model = model
      @schema = { id: :integer }
      @model.attr_accessor :id
    end

    def string(name)
      @model.attr_accessor name
      @schema[name] = :string
    end

    def integer(name)
      @model.attr_accessor name
      @schema[name] = :integer
    end

    def boolean(name)
      @model.attr_accessor name
      @schema[name] = :boolean
    end

    def float(name)
      @model.attr_accessor name
      @schema[name] = :float
    end

    def datetime(name)
      @model.attr_accessor name
      @schema[name] = :datetime
    end

  end
end