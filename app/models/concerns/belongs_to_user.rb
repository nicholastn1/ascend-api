module BelongsToUser
  extend ActiveSupport::Concern

  included do
    belongs_to :user

    scope :for_user, ->(user) { where(user: user) }
  end
end
