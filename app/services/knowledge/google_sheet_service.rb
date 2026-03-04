require "google/apis/sheets_v4"

module Knowledge
  class GoogleSheetService
    # Fetch content from a Google Sheet and return as plain text.
    # Expects a Google Sheets URL or spreadsheet ID.
    #
    # Returns a string with all sheet data formatted as text.
    def self.fetch(source_url:)
      new(source_url: source_url).fetch
    end

    def initialize(source_url:)
      @source_url = source_url
      @spreadsheet_id = extract_spreadsheet_id(source_url)
    end

    def fetch
      service = Google::Apis::SheetsV4::SheetsService.new
      service.key = ENV.fetch("GOOGLE_SHEETS_API_KEY")

      spreadsheet = service.get_spreadsheet(@spreadsheet_id, include_grid_data: false)
      sheets = spreadsheet.sheets

      text_parts = []

      sheets.each do |sheet|
        title = sheet.properties.title
        range = "#{title}"

        begin
          response = service.get_spreadsheet_values(@spreadsheet_id, range)
          values = response.values
          next if values.blank?

          text_parts << "## #{title}\n"

          # First row as headers
          headers = values.first
          data_rows = values[1..] || []

          data_rows.each do |row|
            row_text = headers.each_with_index.filter_map do |header, i|
              value = row[i]
              "#{header}: #{value}" if value.present?
            end
            text_parts << row_text.join(", ") if row_text.any?
          end

          text_parts << ""
        rescue Google::Apis::ClientError => e
          Rails.logger.warn("Failed to fetch sheet '#{title}': #{e.message}")
          next
        end
      end

      text_parts.join("\n")
    end

    private

    def extract_spreadsheet_id(url)
      # Handle both full URLs and raw IDs
      if url.include?("docs.google.com")
        match = url.match(%r{/spreadsheets/d/([a-zA-Z0-9_-]+)})
        raise ArgumentError, "Invalid Google Sheets URL" unless match

        match[1]
      else
        url # Assume it's a raw spreadsheet ID
      end
    end
  end
end
