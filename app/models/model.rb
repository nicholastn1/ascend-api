class Model < ApplicationRecord
  acts_as_model

  validates :model_id, presence: true
  validates :provider, presence: true
end
