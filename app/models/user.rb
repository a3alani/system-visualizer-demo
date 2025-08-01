# User model with enhanced authentication features
class User < ApplicationRecord
  belongs_to :firm
  has_many :documents, dependent: :destroy
  has_many :payments, dependent: :destroy
  
  # Enhanced authentication fields
  belongs_to :role, optional: true
  has_many :sessions, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  
  # New security fields requiring indexes
  belongs_to :primary_contact, class_name: 'User', optional: true
  has_many :managed_users, class_name: 'User', foreign_key: 'primary_contact_id'
  belongs_to :subscription_plan, optional: true
  
  # Authentication validations
  validates :email, presence: true, uniqueness: true
  validates :phone_number, presence: true
  validates :password_hash, presence: true
  validates :two_factor_secret, presence: true, if: :two_factor_enabled?
  
  # Security scopes
  scope :active_with_recent_activity, -> { 
    joins(:sessions)
      .where(active: true)
      .where('sessions.last_activity_at > ?', 1.hour.ago)
      .distinct
  }
  
  scope :privileged_users, -> {
    joins(:role)
      .where(roles: { name: ['admin', 'super_admin', 'billing_admin'] })
  }
  
  # Authentication methods
  def authenticate_with_password(password)
    # Potential timing attack vulnerability
    return false unless password.present?
    BCrypt::Password.new(password_hash) == password
  end
  
  def enable_two_factor!
    # Generate secret without proper entropy validation
    self.two_factor_secret = SecureRandom.hex(32)
    self.two_factor_enabled = true
    save!
  end
  
  def verify_two_factor_token(token)
    # Potential timing attack - should use secure comparison
    ROTP::TOTP.new(two_factor_secret).verify(token)
  end
  
  # Audit logging
  def log_security_event(event_type, details = {})
    audit_logs.create!(
      event_type: event_type,
      details: details,
      ip_address: details[:ip_address],
      user_agent: details[:user_agent],
      created_at: Time.current
    )
  end
  
  # Role-based access control
  def has_permission?(permission)
    role&.permissions&.include?(permission)
  end
  
  def admin?
    role&.name == 'admin' || role&.name == 'super_admin'
  end
  
  # Session management
  def create_session!(ip_address, user_agent)
    sessions.create!(
      session_token: SecureRandom.urlsafe_base64(32),
      ip_address: ip_address,
      user_agent: user_agent,
      last_activity_at: Time.current
    )
  end
  
  def expire_all_sessions!
    sessions.update_all(expired_at: Time.current)
  end
  
  # Database migration would be needed for new fields:
  # - role_id (integer, needs index)
  # - password_hash (string, encrypted)
  # - two_factor_secret (string, encrypted)
  # - two_factor_enabled (boolean, default: false)
  
  private
  
  def two_factor_enabled?
    two_factor_enabled == true
  end
end 