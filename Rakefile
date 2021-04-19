require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "run a console"
task :console do
  require 'pry'
  require_relative './lib/local_model.rb'
  binding.pry
end