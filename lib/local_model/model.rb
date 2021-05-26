class LocalModel::Model

  def self.schema(&block)
    raise NoMethodError.new("self.schema must be defined")
    # yield(SchemaBuilder.new(self))
  end

  def self.belongs_to(association, class_name: nil, foreign_key: nil)
    if class_name.nil?
      association_class_name = LocalModel::Functions.snake_to_camel(association)
      association_class_name[0] = association_class_name[0].upcase
      association_class_name = namespace_classname(association_class_name)
    else
      association_class_name = namespace_classname(class_name)
    end
    association_class = Object.const_get(association_class_name)

    if foreign_key.nil?
      keyname = "#{association}_id"
    else
      keyname = foreign_key
    end

    define_method association do
      id = self.send(keyname)
      association_class.find(id)
    end

    define_method "#{association}=" do |association_obj|
      self.send("#{keyname}=", association_obj.id)
    end
  end

  def self.has_many(association, through: nil, class_name: nil, foreign_key: nil)
    if class_name.nil?
      association_classname = namespace_classname(get_classname_from_association(association))
    else
      association_classname = namespace_classname(class_name)
    end

    current_class_id_methodname = foreign_key || "#{LocalModel::Functions.camel_to_snake(denamespace_classname(self))}_id"
    belongs_to_id_sym = current_class_id_methodname.to_sym

    if through.nil?
      define_method association do
        association_class = Object.const_get(association_classname)
        association_class.where(belongs_to_id_sym => self.id)
      end
    else
      through_classname = namespace_classname(get_classname_from_association(through))
      define_method association do 
        through_class = Object.const_get(through_classname)
        through_class.where(belongs_to_id_sym => self.id).map{|obj| obj.send(LocalModel::Functions.singularize(association))}
      end
    end
  end

  def self.has_one(association, class_name: nil, foreign_key: nil)
    if class_name.nil?
      association_classname = LocalModel::Functions.snake_to_camel(association)
      association_classname[0] = association_classname[0].upcase
      association_classname = namespace_classname(association_classname)
    else
      association_classname = class_name
    end
    current_class_id_methodname = foreign_key || "#{LocalModel::Functions.camel_to_snake(denamespace_classname(self))}_id"
    belongs_to_id_sym = current_class_id_methodname.to_sym

    define_method association do 
      association_class = Object.const_get(association_classname)
      association_class.where(belongs_to_id_sym => self.id).first
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