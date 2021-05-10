# LocalModel

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/local_model`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'local_model'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install local_model

## Usage

Create your schema:

```rb
# Some config file

LocalModel.config |c|
    c.path = "/some/path/you_want/to_store/the_csv_files"
end
```

```rb
# User.rb

class User < LocalModel::CSV

    schema do |t|
        t.string :name
        t.integer :age
        t.string :password
    end 

    has_many :dogs

end
```
```rb
# Dog.rb

class Dog < LocalModel::CSV

    schema do |t|
        t.string :name
        t.integer :age
        t.integer :user_id
    end

    belongs_to :user
end

```

...then

```rb

u = User.create(name: "Cyrus Harding", age: 45, password: "LincolnIsland")
d = Dog.create(name: "Top", age: 3, user: u)

u.dogs # => [#<Dog:0x00005568e92b3f48 @age=3, @id=1, @name="Top">]
d.user # => #<User:0x00005568e92b3f48 @age=45, @id=1, @name="Cyrus Harding", @password="LincolnIsland">

u == User.first # true
Dog.where(user: u).first == d # true

```
As of now, supports:
- #destroy, .find, .create, .new, .where, .first, .second, .last, relationships, updating,

Does not support yet (notably): 
- .build, .update, validations, #<< to add many relationships 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/local_model. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the LocalModel project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/local_model/blob/master/CODE_OF_CONDUCT.md).
