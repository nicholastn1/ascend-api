class OauthAccount < ApplicationRecord
  include BelongsToUser

  validates :provider, presence: true
  validates :provider_uid, presence: true
  validates :provider_uid, uniqueness: { scope: :provider }
end
