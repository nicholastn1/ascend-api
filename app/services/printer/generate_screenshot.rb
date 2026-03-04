module Printer
  class GenerateScreenshot
    SCREENSHOT_TTL = 6.hours
    A4_DIMENSIONS = { width: 794, height: 1123 }.freeze

    def initialize(resume:)
      @resume = resume
      @user = resume.user
    end

    def call
      validate_printer_endpoint!

      # Check cache first
      cached_url = find_cached_screenshot
      return cached_url if cached_url

      # Clean up stale screenshots
      cleanup_existing_screenshots

      # Generate new screenshot via Browserless
      screenshot_data = generate_via_browserless

      # Upload to storage
      upload_screenshot(screenshot_data)
    end

    private

    def validate_printer_endpoint!
      raise "PRINTER_ENDPOINT not configured" unless printer_endpoint.present?
    end

    def find_cached_screenshot
      prefix = "uploads/#{@user.id}/screenshots/#{@resume.id}"
      blobs = ActiveStorage::Blob.where("key LIKE ?", "#{prefix}%").order(created_at: :desc)

      return nil if blobs.empty?

      latest = blobs.first
      age = Time.current - latest.created_at

      # Return cached if within TTL
      return file_url(latest.key) if age < SCREENSHOT_TTL

      # Stale but resume hasn't changed since screenshot was taken
      return file_url(latest.key) if @resume.updated_at <= latest.created_at

      nil
    end

    def cleanup_existing_screenshots
      prefix = "uploads/#{@user.id}/screenshots/#{@resume.id}"
      ActiveStorage::Blob.where("key LIKE ?", "#{prefix}%").find_each(&:purge)
    end

    def generate_via_browserless
      token = PrinterToken.generate(@resume.id)
      url = "#{printer_app_url}/printer/#{@resume.id}?token=#{token}"

      response = Faraday.post(browserless_screenshot_url) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = {
          url: url,
          gotoOptions: {
            waitUntil: "networkidle0",
            timeout: 30_000
          },
          viewport: A4_DIMENSIONS,
          emulateMediaType: "print",
          options: {
            type: "webp",
            quality: 80,
            fullPage: false
          },
          waitForFunction: {
            fn: "() => document.body.getAttribute('data-wf-loaded') === 'true'",
            timeout: 5000
          }
        }.to_json
      end

      unless response.success?
        raise "Browserless screenshot generation failed: #{response.status} - #{response.body}"
      end

      response.body
    end

    def upload_screenshot(data)
      timestamp = (Time.current.to_f * 1000).to_i
      key = "uploads/#{@user.id}/screenshots/#{@resume.id}/#{timestamp}.webp"

      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(data),
        filename: "#{timestamp}.webp",
        content_type: "image/webp",
        key: key
      )

      file_url(key)
    end

    def printer_endpoint
      ENV["PRINTER_ENDPOINT"]
    end

    def printer_app_url
      ENV["PRINTER_APP_URL"].presence || ENV.fetch("APP_URL", "http://localhost:3000")
    end

    def browserless_screenshot_url
      endpoint = URI.parse(printer_endpoint)
      endpoint.scheme = endpoint.scheme&.sub("ws", "http")
      endpoint.path = "/chromium/screenshot"
      endpoint.to_s
    end

    def file_url(key)
      app_url = ENV.fetch("APP_URL", "http://localhost:3000")
      "#{app_url}/#{key}"
    end
  end
end
