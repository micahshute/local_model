# LocalModel

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

Use the generator:

```bash
bundle add local_model
```
```
bundle exec local_model --namespace DesiredNamespace
``` 
Note: `--namespace` is optional and will default to `InMemory`
This creates a rails initializer which sets some config options,
and a `DataAccessor` class which you can use to switch between your `LocalModel` objects and your `ActiveRecord` objects.

Recommend adding: 

`config/application.rb`
```ruby
config.autoload_paths << config.root.join('lib')
```

so you get all of these files.

You can set an environment variable `USE_LOCAL_MODELS` to `true` or `false` to globally decide what to use.


You also now can use a rake task to generate your `LocalModel` models:
`rake local_model:create_model\[User\]`
(The `\`s should only be necessary in zsh, not bash)

OR, you can manually: 

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
- .build, .update, validations
- object equivalence if gotten from source twice


### Namespace Methods

```rb

LocalModel.config do |c|
    c.path = "/home/me/data/"
    c.cleanup_on_start = true # delete ALL files in path on startup 
    c.namespace = "InMemory" # Expect ALL LocalModels to be namespaced via this string
end

```

```rb
# in_memory/pokemon.rb

class InMemory::Pokemon < LocalModel::CSV

    schema do |t|
        t.string :name
        t.string :nickname
        t.integer :hp
        t.string :species
    end

end


```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/local_model. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the LocalModel project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/local_model/blob/master/CODE_OF_CONDUCT.md).
