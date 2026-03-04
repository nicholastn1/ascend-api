module Resumes
  class CreateResume
    def initialize(user, params)
      @user = user
      @params = params
    end

    def call
      @user.resumes.create!(
        name: @params[:name],
        slug: @params[:slug] || generate_slug(@params[:name]),
        data: @params[:data] || default_data,
        tags: @params[:tags] || [],
        is_public: @params[:is_public] || false
      )
    end

    private

    def generate_slug(name)
      base_slug = name.parameterize
      slug = base_slug
      counter = 1
      while @user.resumes.exists?(slug: slug)
        slug = "#{base_slug}-#{counter}"
        counter += 1
      end
      slug
    end

    def default_data
      { basics: { name: @user.name, email: @user.email } }
    end
  end
end
