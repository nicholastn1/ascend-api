module Storage
  class UploadFile
    MAX_FILE_SIZE = 10.megabytes
    IMAGE_CONTENT_TYPES = %w[image/gif image/png image/jpeg image/webp].freeze
    MAX_IMAGE_DIMENSION = 800

    def initialize(user:, file:, type: "picture", resume_id: nil)
      @user = user
      @file = file
      @type = type
      @resume_id = resume_id
    end

    def call
      validate_file!
      processed = process_image_if_needed
      blob = store_file(processed)
      { url: file_url(blob.key), path: blob.key, content_type: blob.content_type }
    end

    private

    def validate_file!
      raise ArgumentError, "No file provided" unless @file
      raise ArgumentError, "File too large (max #{MAX_FILE_SIZE / 1.megabyte}MB)" if @file.size > MAX_FILE_SIZE
    end

    def process_image_if_needed
      return @file unless image? && !image_processing_disabled?

      processed = ImageProcessing::Vips
        .source(@file.tempfile.path)
        .resize_to_limit(MAX_IMAGE_DIMENSION, MAX_IMAGE_DIMENSION)
        .convert("webp")
        .call

      ActionDispatch::Http::UploadedFile.new(
        tempfile: processed,
        filename: "#{File.basename(@file.original_filename, '.*')}.webp",
        type: "image/webp"
      )
    end

    def store_file(file)
      key = generate_key(file)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file.tempfile,
        filename: File.basename(key),
        content_type: file.content_type,
        key: key
      )
      blob
    end

    def generate_key(file)
      timestamp = (Time.current.to_f * 1000).to_i
      ext = File.extname(file.original_filename).presence || ".webp"

      case @type
      when "picture"
        "uploads/#{@user.id}/pictures/#{timestamp}#{ext}"
      when "screenshot"
        "uploads/#{@user.id}/screenshots/#{@resume_id}/#{timestamp}#{ext}"
      when "pdf"
        "uploads/#{@user.id}/pdfs/#{@resume_id}/#{timestamp}#{ext}"
      else
        "uploads/#{@user.id}/files/#{timestamp}#{ext}"
      end
    end

    def image?
      IMAGE_CONTENT_TYPES.include?(@file.content_type)
    end

    def image_processing_disabled?
      ENV["FLAG_DISABLE_IMAGE_PROCESSING"] == "true"
    end

    def file_url(key)
      app_url = ENV.fetch("APP_URL", "http://localhost:3000")
      "#{app_url}/#{key}"
    end
  end
end
