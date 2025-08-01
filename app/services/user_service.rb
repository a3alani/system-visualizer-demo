class UserService
  include ActiveModel::Model
  
  def self.call(users)
    new(users).process
  end
  
  def initialize(users)
    @users = users
  end
  
  def process
    validate_users
    enrich_user_data
    send_notifications
    update_metrics
  end
  
  private
  
  attr_reader :users
  
  def validate_users
    users.each do |user|
      # Potential N+1 query: accessing firm for each user
      next unless user.firm.active?
      
      # Database query in loop - performance risk
      user.update(last_validated_at: Time.current)
    end
  end
  
  def enrich_user_data
    # Expensive operation: multiple API calls
    users.each do |user|
      # Synchronous external API calls
      credit_score = CreditCheckService.get_score(user.ssn)
      background_check = BackgroundCheckService.verify(user.id)
      
      # More database writes in loop
      user.update(
        credit_score: credit_score,
        background_verified: background_check
      )
    end
  end
  
  def send_notifications
    # Potential memory issues with large datasets
    user_emails = users.pluck(:email)
    
    # Bulk email operation - could be moved to background job
    user_emails.each do |email|
      UserMailer.welcome_email(email).deliver_now
    end
  end
  
  def update_metrics
    # Complex aggregation queries
    total_users = users.count
    active_firms = users.joins(:firm).where(firms: { active: true }).count
    
    # Direct database updates - could use counter caches
    Metric.update_all(
      total_users: total_users,
      active_firms: active_firms,
      last_updated: Time.current
    )
  end
  
  # New dependency: CreditCheckService
  # New dependency: BackgroundCheckService  
  # New dependency: UserMailer
  # New dependency: Metric model
end 