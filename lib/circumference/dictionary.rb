require 'circumference/dictionary/attributes'
require 'circumference/dictionary/values'

module Circumference
  class Dictionary

    ATTRIBUTE    = 'ATTRIBUTE'
    VENDOR       = 'VENDOR'
    BEGIN_VENDOR = 'BEGIN-VENDOR'
    END_VENDOR   = 'END-VENDOR'
    VALUE        = 'VALUE'

    DEFAULT_DICTIONARIES_PATH = '/usr/share/freeradius'

    attr_reader :attributes, :vendors

    def initialize(initial_path = nil)
      @attributes = AttributesCollection.new
      @vendors    = VendorCollection.new

      read_files initial_path if initial_path
    end

    def read_files(path)
      raise Circumference::DictionaryPathNotFound, path unless File.exist?(path)

      dict_files = File.join(path, "*")

      # Read attributes
      Dir.glob(dict_files) { |file| read_attributes(file) }

      # Read values
      Dir.glob(dict_files) { |file| read_values(file) }
    end

    def find_attribute_by_name(name)
      @attributes.find_by_name(name)
    end

    def find_attribute_by_id(id)
      @attributes.find_by_id(id)
    end

    def attribute_name_defined?(name)
      !@attributes.find_by_name(name).nil?
    end

    def attribute_id_defined?(id)
      !@attributes.find_by_id(id).nil?
    end

    class << self

      def default
        new DEFAULT_DICTIONARIES_PATH
      end

    end

    protected

    def read_attributes(path)
      file = File.open(path) do |f|
        current_vendor = nil
        f.each_line do |line|
          next if line =~ /^\#/	# discard comments
          split_line = line.split(/\s+/)
          next if split_line == []
          case split_line.first.upcase
          when ATTRIBUTE
            current_vendor.nil? ? set_attr(split_line) : set_vendor_attr(current_vendor, split_line)
          when VENDOR
            add_vendor(split_line)
          when BEGIN_VENDOR
            current_vendor = set_vendor(split_line)
          when END_VENDOR
            current_vendor = nil
          end
        end
      end
    end

    def read_values(path)
      file = File.open(path) do |f|
        current_vendor = nil
        f.each_line do |line|
          next if line =~ /^\#/	# discard comments
          split_line = line.split(/\s+/)
          next if split_line == []
          case split_line.first.upcase
          when VALUE
            if current_vendor.nil?
              set_value(split_line)
            else
              begin
                set_vendor_value(current_vendor, split_line)
              rescue
                set_value(split_line)
              end
            end
          when BEGIN_VENDOR
            current_vendor = set_vendor(split_line)
          when END_VENDOR
            current_vendor = nil
          end
        end
      end
    end

    private

    def set_attr(line)
      @attributes.add(line[1], line[2], line[3])
    end

    def set_value(line)
      attribute = @attributes.find_by_name(line[1])
      attribute.add_value(line[2], line[3]) if attribute
    end

    def add_vendor(line)
      @vendors.add(line[2], line[1])
    end

    def set_vendor(line)
      @vendors.find_by_name(line[1])
    end

    def set_vendor_attr(vendor, line)
      vendor.add_attribute(line[1], line[2], line[3])
    end

    def set_vendor_value(vendor, line)
      attribute = vendor.find_attribute_by_name(line[1])
      attribute.add_value(line[2], line[3]) if attribute
    end

  end

end
