require_relative './lib/local_model'

LocalModel.config{}

class Dog < LocalModel::CSV

  schema do |t|
    t.string :name
    t.integer :user_id
    t.integer :age
  end

  belongs_to :user


end

class User < LocalModel::CSV

  schema do |t|
    t.string :name
    t.string :password
    t.integer :age
  end

  has_many :dogs

end