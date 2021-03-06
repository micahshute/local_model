require_relative "./local_model/version"
require 'csv'
require_relative './local_model/errors/record_invalid'
require_relative './local_model/errors/record_not_found'
require_relative './local_model/sandbox'
require_relative './local_model/collection'
require_relative './local_model/adapters/boolean_adapter'
require_relative './local_model/adapters/datetime_adapter'
require_relative './local_model/adapters/float_adapter'
require_relative './local_model/adapters/integer_adapter'
require_relative './local_model/adapters/string_adapter'
require_relative './local_model/concerns/csv_interactable'
require_relative './local_model/helpers/functions'
require_relative './local_model/helpers/pluralized_words'
require_relative './local_model/model'
require_relative './local_model/csv'
require_relative './local_model/generators/initialize'

module LocalModel
  class Error < StandardError; end

  @@path = "#{Dir.pwd}/tmp"
  @@namespace = nil

  def self.namespaced?
    !!@@namespace
  end

  def self.namespace 
    if @@namespace.nil? 
      nil
    elsif @@namespace == :default || @@namespace == "default"
      "LocalModel::Sbx"
    else
      @@namespace
    end
  end

  def self.path
    @@path
  end

  def self.db_drop
    Dir.foreach(@@path) do |f|
      fn = File.join(@@path, f)
      File.delete(fn) if f != '.' && f != '..'
    end
  end

  def self.config(&block)
    configuration = Configuration.new
    if block_given?
      yield(configuration)
    end
    @@path = configuration.path
    @@namespace = configuration.namespace
    Dir.mkdir(configuration.path) unless Dir.exist?(configuration.path)
    if configuration.cleanup_on_start
      db_drop
    end
  end

  class Configuration

    attr_accessor :path, :cleanup_on_start, :namespace

    def initialize
      @path = "#{Dir.pwd}/tmp"
      @cleanup_on_start = false
      @namespace = nil
    end
  end
end