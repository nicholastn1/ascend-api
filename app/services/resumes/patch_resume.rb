module Resumes
  class PatchResume
    def initialize(resume, operations)
      @resume = resume
      @operations = operations
    end

    def call
      raise ResumeLockedError, "Resume is locked" if @resume.locked?

      data = @resume.data.deep_dup
      patch = Hana::Patch.new(@operations)
      patched_data = patch.apply(data)
      @resume.update!(data: patched_data)
      @resume
    end
  end
end
