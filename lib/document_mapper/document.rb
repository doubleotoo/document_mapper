require 'active_model'

module DocumentMapper
  module Document
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods
    include AttributeMethods::Read
    include YamlParsing

    attr_accessor :attributes, :content, :directory, :file_path

    included do
      @@documents = []
    end

    def ==(other_document)
      return false unless other_document.is_a? Document
      self.file_path == other_document.file_path
    end

    def file_name(options = {})
      File.basename self.file_path
    end

    def file_name_without_extension
      File.basename self.file_path, File.extname(self.file_path)
    end

    def extension
      File.extname(self.file_path).sub(/^\./, '')
    end

    module ClassMethods
      def reset
        @@documents = []
      end

      def reload
        self.reset
        self.directory = @@directory
      end

      def from_file(file_path)
        if !File.exist? file_path
          raise FileNotFoundError
        end
        self.new.tap do |document|
          document.file_path = File.expand_path(file_path)
          document.read_yaml
          @@documents << document
        end
      end

      def directory=(new_directory)
        raise FileNotFoundError unless File.directory?(new_directory)
        self.reset
        @@directory = Dir.new File.expand_path(new_directory)
        @@directory.each do |file|
          next if ['.', '..'].include? file
          self.from_file [@@directory.path, file].join('/')
        end
      end

      def select(options = {})
        documents = @@documents.dup
        options[:where].each do |selector, selector_value|
          documents.select! do |document|
            next unless document.respond_to? selector.attribute
            document_value = document.send(selector.attribute)
            operator = REVERSE_OPERATOR_MAPPING[selector.operator]
            selector_value.send operator, document_value
          end
        end
        documents
      end

      def where(hash)
        Query.new(self).where(hash)
      end

      def sort(field)
        Query.new(self).sort(field)
      end

      def offset(number)
        Query.new(self).offset(number)
      end

      def limit(number)
        Query.new(self).limit(number)
      end

      def all
        @@documents
      end

      def first
        @@documents.first
      end

      def last
        @@documents.last
      end
    end
  end
end
