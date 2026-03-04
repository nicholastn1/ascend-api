module HasUuid
  extend ActiveSupport::Concern

  included do
    before_create :set_uuid

    private

    def set_uuid
      self.id ||= SecureRandom.uuid
    end
  end
end
