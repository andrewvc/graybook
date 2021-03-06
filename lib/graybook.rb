$:.unshift File.expand_path(File.join(File.dirname(__FILE__)))
require 'singleton'
require 'rubygems'

class Graybook
  include ::Singleton
  VERSION = '1.1.1'

  class Problem < Exception
    def nil?
      true
    end
  end

  attr_accessor :importers
  attr_accessor :exporters

  def self.get( *args )
    instance.get( *args )
  end

  def self.register(name, adapter_class)
    case adapter = adapter_class.new
      when Importer::Base
        instance.importers[name.to_sym] = adapter
      when Exporter::Base
        instance.exporters[name.to_sym] = adapter
      else
        return nil
    end
  end

  def export( importer, exporter, options )
    exporter.export importer.import( options )
  end

  # Searches registered importers for one that will handle the given options
  def find_importer( options )
    importers.each{ |key, importer| return importer if importer =~ options }
    nil
  end

  # Fetches contacts from various services or filetypes. The default is to return an array
  # of hashes - Graybook's internal format
  #
  # Handles several different calls:
  #  get( :username => 'something@gmail.com', :password => 'whatever' )
  def get( *args )
    options   = args.last.is_a?(Hash) ? args.pop : {}
    to_format = exporters[:basic]
    source    = (importers[args.first.to_sym] rescue nil) || find_importer(options)

    return nil unless to_format
    return nil unless source

    export source, to_format, options
  end

  def initialize
    self.importers = {}
    self.exporters = {}
  end
end

# Require all the importers/exporters
require 'graybook/importer/base'
require 'graybook/exporter/base'
Dir.glob(File.join(File.dirname(__FILE__), 'graybook/importer/*.rb')).each {|f| require f }
Dir.glob(File.join(File.dirname(__FILE__), 'graybook/exporter/*.rb')).each {|f| require f }

class NilClass
  def empty?
    true
  end
end

class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end

