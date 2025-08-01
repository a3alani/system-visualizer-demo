class UserService
  def self.call(users)
    new(users).process
  end
  
  def initialize(users)
    @users = users
  end
  
  def process
    @users.each do |user|
      update_last_seen(user)
      sync_with_billing(user)
      check_subscription_status(user)
    end
  end
  
  private
  
  def update_last_seen(user)
    user.update(last_seen_at: Time.current)
  end
  
  def sync_with_billing(user)
    BillingService.sync_user(user)
  end
  
  def check_subscription_status(user)
    firm = user.firm
    return unless firm.subscription_expired?
    
    NotificationService.send_renewal_reminder(user)
  end
end 