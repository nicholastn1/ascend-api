module Printer
  class GeneratePdf
    # Page dimensions in pixels (matching frontend pageDimensionsAsPixels)
    PAGE_DIMENSIONS = {
      "a4" => { width: 794, height: 1123 },
      "letter" => { width: 816, height: 1056 },
      "free-form" => { width: 794, height: 1123 }
    }.freeze

    # Templates that need margins applied via PDF options (not CSS)
    PRINT_MARGIN_TEMPLATES = %w[chikorita leafeon nosepass onyx pikachu].freeze

    def initialize(resume:)
      @resume = resume
      @user = resume.user
    end

    def call
      validate_printer_endpoint!

      # Clean up any existing PDFs for this resume
      cleanup_existing_pdfs

      # Generate the PDF via Browserless
      pdf_data = generate_via_browserless

      # Upload to storage
      upload_pdf(pdf_data)
    end

    private

    def validate_printer_endpoint!
      raise "PRINTER_ENDPOINT not configured" unless printer_endpoint.present?
    end

    def cleanup_existing_pdfs
      prefix = "uploads/#{@user.id}/pdfs/#{@resume.id}"
      ActiveStorage::Blob.where("key LIKE ?", "#{prefix}%").find_each(&:purge)
    end

    def generate_via_browserless
      token = PrinterToken.generate(@resume.id)
      url = "#{printer_app_url}/printer/#{@resume.id}?token=#{token}"

      format = resume_format
      dimensions = PAGE_DIMENSIONS.fetch(format, PAGE_DIMENSIONS["a4"])
      margins = calculate_margins

      response = Faraday.post(browserless_pdf_url) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = {
          url: url,
          gotoOptions: {
            waitUntil: "networkidle0",
            timeout: 30_000
          },
          viewport: {
            width: dimensions[:width],
            height: dimensions[:height]
          },
          emulateMediaType: "print",
          options: {
            width: "#{dimensions[:width]}px",
            height: "#{dimensions[:height]}px",
            printBackground: true,
            tagged: true,
            margin: {
              top: margins[:y],
              bottom: 0,
              left: margins[:x],
              right: margins[:x]
            }
          },
          waitForFunction: {
            fn: "() => document.body.getAttribute('data-wf-loaded') === 'true'",
            timeout: 5000
          }
        }.to_json
      end

      unless response.success?
        raise "Browserless PDF generation failed: #{response.status} - #{response.body}"
      end

      response.body
    end

    def upload_pdf(pdf_data)
      timestamp = (Time.current.to_f * 1000).to_i
      key = "uploads/#{@user.id}/pdfs/#{@resume.id}/#{timestamp}.pdf"

      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(pdf_data),
        filename: "#{timestamp}.pdf",
        content_type: "application/pdf",
        key: key
      )

      app_url = ENV.fetch("APP_URL", "http://localhost:3000")
      "#{app_url}/#{key}"
    end

    def resume_format
      @resume.data.dig("metadata", "page", "format") || "a4"
    end

    def resume_template
      @resume.data.dig("metadata", "template") || "rhyhorn"
    end

    def calculate_margins
      template = resume_template
      return { x: 0, y: 0 } unless PRINT_MARGIN_TEMPLATES.include?(template)

      margin_x = @resume.data.dig("metadata", "page", "marginX") || 0
      margin_y = @resume.data.dig("metadata", "page", "marginY") || 0

      # Convert CSS pixels to PDF points (1pt = 0.75px at 72dpi)
      { x: (margin_x / 0.75).round, y: (margin_y / 0.75).round }
    end

    def printer_endpoint
      ENV["PRINTER_ENDPOINT"]
    end

    def printer_app_url
      ENV["PRINTER_APP_URL"].presence || ENV.fetch("APP_URL", "http://localhost:3000")
    end

    def browserless_pdf_url
      endpoint = URI.parse(printer_endpoint)
      endpoint.scheme = endpoint.scheme&.sub("ws", "http")
      endpoint.path = "/chromium/pdf"
      endpoint.to_s
    end
  end
end
