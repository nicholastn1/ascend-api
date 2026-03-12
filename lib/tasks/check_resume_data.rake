# frozen_string_literal: true

desc "Check resume data structure (metadata/typography) in the database"
task check_resume_data: :environment do
  r = Resume.find_by(id: "e8768dfb-2aba-40a8-af6b-623add424c73")
  if r
    puts "Resume e8768dfb:"
    puts "  Data keys: #{r.data.keys.inspect}"
    puts "  Has metadata?: #{r.data.key?('metadata')}"
    puts "  metadata.typography: #{r.data.dig('metadata', 'typography') ? 'present' : 'MISSING'}"
  else
    puts "Resume e8768dfb not found"
  end

  puts ""
  puts "Counting..."
  total = Resume.count
  missing = 0
  Resume.find_each { |resume| missing += 1 unless resume.data["metadata"]&.key?("typography") }
  puts "Total resumes: #{total}"
  puts "Missing metadata.typography: #{missing}"
end
