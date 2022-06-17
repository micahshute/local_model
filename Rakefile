require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "environment"
task :environment do 
  require_relative './lib/local_model.rb'
end

desc "run file generator"
task :generate => :environment do 
  LocalModel::Generator.new.invoke_all
end