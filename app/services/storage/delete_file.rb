module Storage
  class DeleteFile
    def initialize(user:, path:)
      @user = user
      @path = path
    end

    def call
      validate_ownership!
      blob = ActiveStorage::Blob.find_by(key: @path)
      raise ActiveRecord::RecordNotFound, "File not found" unless blob

      blob.purge
      { deleted: true }
    end

    private

    def validate_ownership!
      expected_prefix = "uploads/#{@user.id}/"
      unless @path.start_with?(expected_prefix)
        raise ActiveRecord::RecordNotFound, "File not found"
      end
    end
  end
end
