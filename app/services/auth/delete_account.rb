module Auth
  class DeleteAccount
    def initialize(user)
      @user = user
    end

    def call
      @user.destroy!
    end
  end
end
