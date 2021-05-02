require 'pry'
require_relative "./local_model/version"
require 'csv'
require 'require_all'
require_all 'lib/local_model/adapters'
require_all 'lib/local_model/concerns'
require_all 'lib/local_model/helpers'
require_relative './local_model/model'
require_relative './local_model/csv'

module LocalModel
  class Error < StandardError; end

  @@path = "#{Dir.pwd}/tmp"

  def self.path
    @@path
  end

  def self.config(&block)
    configuration = Configuration.new
    if block_given?
      yield(configuration)
    end
    @@path = configuration.path
    Dir.mkdir(configuration.path) unless Dir.exist?(configuration.path)
    if configuration.cleanup_on_start
      Dir.foreach do |f|
        fn = File.join(configuration.path, f)
        File.delete(fn) if f != '.' && f != '..'
      end
    end
  end

  class Configuration

    attr_accessor :path, :cleanup_on_start

    def initialize
      @path = "#{Dir.pwd}/tmp"
      @cleanup_on_start = false
    end
  end
end