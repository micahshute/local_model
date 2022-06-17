require 'thor'
require 'thor/group'

module LocalModel
    module Generators
        class Initialize < Thor::Group
            include Thor::Actions

            class_option :namespace, default: "InMemory"

            desc 'Create required files'

            def self.source_root
                File.dirname(__FILE__) + '/../'
            end

            def create_initializer
                @namespace_classname = options[:namespace]
                template('templates/initializer.erb', 'config/initializers/local_model.rb')
            end

            def create_data_accessor
                template('templates/data_accessor.erb', 'lib/data_accessor.rb')
            end

            def create_model_generator
                @class_namespace_snake = LocalModel::Functions.camel_to_snake(@namespace_classname)
                template('templates/generate_model.erb', 'lib/tasks/local_model.rake')
            end
        end
    end
end