class LocalModel::Model

  def self.schema(&block)
    raise NoMethodError.new("self.schema must be defined")
    # yield(SchemaBuilder.new(self))
  end

  def self.belongs_to(association)
    define_method association do
      id = self.send("#{association}_id")
      association_class_name = LocalModel::Functions.snake_to_camel(association).capitalize
      association_class = Object.const_get(association_class_name)
      association_class.find(id)
    end

    define_method "#{association}=" do |association_obj|
      self.send("#{association}_id=", association_obj.id)
    end
  end

  def self.has_many(association)
    association_portions = association.to_s.split('_')
    association_portions_last = association_portions.last
    singular_association_last = LocalModel::Functions.singularize(association_portions_last)
    singularized_association = association_portions[0...-1] + [singular_association_last]
    singularized_snakecase = singularized_association.join('_')
    association_classname = LocalModel::Functions.snake_to_camel(singularized_snakecase).capitalize
    current_class_id_methodname = "#{LocalModel::Functions.camel_to_snake(self.to_s)}_id"
    belongs_to_id_sym = current_class_id_methodname.to_sym

    define_method association do
      association_class = Object.const_get(association_classname)
      association_class.where(belongs_to_id_sym => self.id)
    end


  end


  def self.storage_path
    slash = LocalModel.path == '/' ? '' : '/'
    "#{LocalModel.path}#{slash}#{self}.csv"
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