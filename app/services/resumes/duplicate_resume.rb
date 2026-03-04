module Resumes
  class DuplicateResume
    def initialize(resume)
      @resume = resume
    end

    def call
      new_slug = generate_unique_slug
      @resume.user.resumes.create!(
        name: "#{@resume.name} (Copy)",
        slug: new_slug,
        data: @resume.data.deep_dup,
        tags: @resume.tags&.dup || []
      )
    end

    private

    def generate_unique_slug
      base = "#{@resume.slug}-copy"
      slug = base
      counter = 1
      while @resume.user.resumes.exists?(slug: slug)
        slug = "#{base}-#{counter}"
        counter += 1
      end
      slug
    end
  end
end
