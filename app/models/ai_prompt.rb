class AiPrompt < ApplicationRecord
  validates :slug, presence: true, uniqueness: true
  validates :title, presence: true
  validates :content, presence: true
end
