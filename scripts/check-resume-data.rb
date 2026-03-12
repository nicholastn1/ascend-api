# Write to file so output survives SSH (stdout from piped rails runner may not display)
out = []
r = Resume.find_by(id: "e8768dfb-2aba-40a8-af6b-623add424c73")
if r
  out << "Resume e8768dfb:"
  out << "  Data keys: #{r.data.keys.inspect}"
  out << "  Has metadata?: #{r.data.key?('metadata')}"
  out << "  metadata.typography: #{r.data.dig('metadata', 'typography') ? 'present' : 'MISSING'}"
else
  out << "Resume e8768dfb not found"
end
out << ""
out << "Counting..."
total = Resume.count
missing = 0
Resume.find_each { |resume| missing += 1 unless resume.data["metadata"]&.key?("typography") }
out << "Total resumes: #{total}"
out << "Missing metadata.typography: #{missing}"
File.write("/tmp/resume-check.txt", out.join("\n"))
