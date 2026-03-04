# Seed AI Prompts from markdown files in db/prompts/
PROMPTS = [
  { slug: "chat-system", title: "Chat System Prompt", description: "System prompt for resume editing chat assistant" },
  { slug: "recruiter-reply-system", title: "Recruiter Reply System Prompt", description: "System prompt for recruiter message reply assistant" },
  { slug: "pdf-parser-system", title: "PDF Parser System Prompt", description: "System prompt for parsing PDF resumes into JSON" },
  { slug: "pdf-parser-user", title: "PDF Parser User Prompt", description: "User prompt template for PDF resume parsing" },
  { slug: "docx-parser-system", title: "DOCX Parser System Prompt", description: "System prompt for parsing Word resumes into JSON" },
  { slug: "docx-parser-user", title: "DOCX Parser User Prompt", description: "User prompt template for DOCX resume parsing" }
].freeze

PROMPTS.each do |prompt_data|
  file_path = Rails.root.join("db/prompts/#{prompt_data[:slug]}.md")
  next unless File.exist?(file_path)

  content = File.read(file_path)

  AiPrompt.find_or_create_by!(slug: prompt_data[:slug]) do |prompt|
    prompt.title = prompt_data[:title]
    prompt.description = prompt_data[:description]
    prompt.content = content
  end

  puts "  Seeded prompt: #{prompt_data[:slug]}"
end
