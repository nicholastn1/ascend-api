module Api
  module V1
    module Statistics
      class PublicController < ApplicationController
        def users
          count = Rails.cache.fetch("statistics/users", expires_in: 6.hours) do
            User.count
          end

          render json: { count: count }
        end

        def resumes
          count = Rails.cache.fetch("statistics/resumes", expires_in: 6.hours) do
            Resume.count
          end

          render json: { count: count }
        end
      end
    end
  end
end
