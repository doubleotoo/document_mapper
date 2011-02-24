require './test/test_base'

describe DocumentMapper::Collection do
  describe 'when adding documents to the collection' do
    before do
      @collection = DocumentMapper::Collection.new
      @document = MyDocument.new('2010-08-08-test-document-file.textile')
    end

    it 'should not accept non-documents' do
      begin
        @collection << 'some string'
      rescue ArgumentError
        assert true
        return
      end
      assert false, 'collection falsely accepted a non DocumentMapper datatype'
    end

    it 'should accept documents' do
      @collection << @document
      assert_equal @document, @collection.first
    end

    it 'should define find_by_attribute finders' do
      @collection << @document
      attr = :find_by_title
      assert @collection.respond_to?(attr), fail_msg(attr)
    end

    it 'should define find_all_by_attribute finders' do
      @collection << @document
      attr = :find_all_by_status
      assert @collection.respond_to?(attr), fail_msg(attr)
    end

    it 'should define by_attribute finders for Array attributes' do
      @collection << @document
      attr = :by_tags
      assert @collection.respond_to?(attr), fail_msg(attr)
    end

    it 'should define find_all_by_attribute finders for Array attributes' do
      @collection << @document
      attr = :find_all_by_tag
      assert @collection.respond_to?(attr), fail_msg(attr)
    end

    private
    def fail_msg(failed_attribute)
      "collection does not respond to #{failed_attribute}"
    end
  end

  describe 'when creating a collection from an Array' do
    it 'should not accept non-documents' do
      assert_raises ArgumentError do
        DocumentMapper::Collection.new ['a string', 'some more']
      end
    end

    it 'should accept documents' do
      document = MyDocument.new '2010-08-08-test-document-file.textile'
      collection = DocumentMapper::Collection.new [document]
      assert document, collection.first
    end
  end

  describe 'when finding documents by date' do
    it 'should return a collection' do
      documents = MyDocument.find_all_by_date 2010
      assert_equal documents.class, DocumentMapper::Collection
    end

    it 'should return all documents with the year specified' do
      documents = MyDocument.find_all_by_date 2010
      assert_equal 2, documents.size
    end

    it 'should return all documents with the year and month specified' do
      documents = MyDocument.find_all_by_date 2010, 8
      assert_equal 2, documents.size
    end

    it 'should return all documents with the year, month and day specified' do
      documents = MyDocument.find_all_by_date 2010, 8, 8
      assert_equal 1, documents.size
    end

    it 'should return all documents with the year and day specified' do
      documents = MyDocument.find_all_by_date 2010, '*', 8
      assert_equal 1, documents.size
    end

    it 'should return all documents with the month and day specified' do
      documents = MyDocument.find_all_by_date '*', 8, 8
      assert_equal 1, documents.size
    end

    it 'should return all documents with the day specified' do
      documents = MyDocument.find_all_by_date '*', '*', 8
      assert_equal 1, documents.size
    end

    it 'should return all documents with the month specified' do
      documents = MyDocument.find_all_by_date '*', 8, '*'
      assert_equal 2, documents.size
    end

    it 'should return the first match' do
      document = MyDocument.find_by_date 2010, 8
      assert_equal 1, document.id
    end
  end

  describe 'when listing document_files by an Array attribute' do
    it 'should return a Hash' do
      assert_equal Hash, MyDocument.by_tags.class
    end

    it 'should use the tags as Hash keys' do
      assert_equal Set.new(['ruby', 'rails']), MyDocument.by_tags.keys.to_set
    end

    it 'should use the document_files as Hash values' do
      document_files = MyDocument.by_tags
      assert_equal Set.new([1, 2]), document_files['ruby'].map(&:id).to_set
      assert_equal Set.new([2]), document_files['rails'].map(&:id).to_set
    end

    it 'should not be confused by attributes that only some documents have' do
      document_files_by_authors = MyDocument.by_authors
      assert_equal 1, document_files_by_authors['Frank'].first.id

      document_files_by_friends = MyDocument.by_friends
      assert_equal 2, document_files_by_friends['Anton'].first.id
    end
  end

  describe 'when finding all document_files by an Array attribute value' do
    it 'should return a DocumentMapper::Collection' do
      klass = MyDocument.find_all_by_tag('ruby').class
      assert_equal DocumentMapper::Collection, klass
    end

    it 'should containt documents' do
      assert_equal MyDocument, MyDocument.find_all_by_tag('ruby').first.class
    end

    it 'should return the right documents' do
      assert_equal [1, 2], MyDocument.find_all_by_tag('ruby').map(&:id)
      assert_equal [2], MyDocument.find_all_by_tag('rails').map(&:id)
    end
  end

  describe 'when finding all document_files by an attribute value' do
    before do
      @collection = MyDocument.find_all_by_status(:published)
    end

    it 'should return a DocumentMapper::Collection' do
      assert_equal DocumentMapper::Collection, @collection.class
    end

    it 'should containt documents' do
      assert_equal MyDocument, @collection.first.class
    end

    it 'should return the right documents' do
      assert_equal [1, 2], @collection.map(&:id)
    end

    it 'should return an empty collection if the document was not found' do
      empty_collection = MyDocument.find_all_by_status(:draft)
      assert_equal [], empty_collection.map(&:id)
    end
  end

  describe 'when finding a document_file' do
    it 'should find the right document_file by an attribute' do
      title = 'Some fancy title'
      document_file = MyDocument.find_by_title(title)
      assert_equal title, document_file.title
    end

    it 'should find the right document_file by file_name' do
      file_name = '2010-08-08-test-document-file'
      document_file = MyDocument.find_by_file_name file_name
      assert_equal document_file.file_name, file_name
    end

    it 'should not be confused by attributes that only some dcuments have' do
      document_file = MyDocument.find_by_special_attribute 'Yes!'
      assert_equal 'Yes!', document_file.special_attribute
    end
  end

  describe 'when using a finder with offset or limit' do
    it 'should respect the offset' do
      document_files = MyDocument.find_all_by_tag 'ruby', :offset => 1
      assert_equal 1, document_files.size
      assert_equal 2, document_files.first.id
    end

    it 'should respect the limit' do
      document_files = MyDocument.find_all_by_tag 'ruby', :limit => 1
      assert_equal 1, document_files.size
      assert_equal 1, document_files.first.id
    end

    it 'should still deliver the total number of documents' do
      document_files = MyDocument.find_all_by_tag 'ruby', :offset => 1
      assert_equal 1, document_files.size
      assert_equal 2, document_files.total
    end

    it 'should work on the root collection' do
      document_files = MyDocument.all :limit => 1
      assert_equal 1, document_files.size
      assert_equal 1, document_files.first.id
    end
  end
end