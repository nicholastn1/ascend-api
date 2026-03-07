class PatchResumeTool < RubyLLM::Tool
  description "Apply JSON Patch (RFC 6902) operations to modify the user's resume data. " \
    "Use this tool whenever the user asks to modify, update, add, or remove resume content."

  param :resume_id, desc: "The ID of the resume to modify"
  param :operations, desc: "Array of JSON Patch operations (RFC 6902). " \
    "Each operation has: op (add/remove/replace/move/copy), path (JSON pointer), value (for add/replace). " \
    "Example: [{\"op\":\"replace\",\"path\":\"/basics/name\",\"value\":\"John Doe\"}]"

  def execute(resume_id:, operations:)
    resume = Resume.find_by(id: resume_id)
    return { error: "Resume not found" }.to_json unless resume

    if resume.locked?
      return { error: "Resume is locked and cannot be modified" }.to_json
    end

    ops = operations.is_a?(String) ? JSON.parse(operations) : operations

    Resumes::PatchResume.new(resume, ops).call

    { success: true, message: "Applied #{ops.size} operation(s) to resume" }.to_json
  rescue JSON::ParserError => e
    { error: "Invalid JSON in operations: #{e.message}" }.to_json
  rescue => e
    { error: e.message }.to_json
  end
end
