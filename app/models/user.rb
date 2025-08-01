# User model with enhanced features
class User < ApplicationRecord
  belongs_to :firm
  has_many :documents, dependent: :destroy
  has_many :payments, dependent: :destroy
  
  # New associations - will trigger index recommendations
  belongs_to :primary_contact, class_name: 'User', optional: true
  has_many :managed_users, class_name: 'User', foreign_key: 'primary_contact_id'
  belongs_to :subscription_plan, optional: true
  
  # New field that may need indexing for searches
  validates :email, presence: true, uniqueness: true
  validates :phone_number, presence: true
  
  # Potential performance issue: complex scope without proper indexing
  scope :active_with_recent_activity, -> { 
    joins(:payments)
      .where(active: true)
      .where('payments.created_at > ?', 1.month.ago)
      .distinct
  }
  
  # Method that could cause N+1 queries
  def recent_document_count
    documents.where('created_at > ?', 1.week.ago).count
  end
  
  # Method that performs expensive calculations
  def total_payment_amount
    payments.sum(:amount)  # Could be optimized with counter cache
  end
  
  # Security consideration: sensitive data handling
  def full_name_with_ssn
    "#{first_name} #{last_name} (SSN: #{ssn})"  # Should be encrypted
  end
  
  # Database migration would be needed for new fields
  # - phone_number (string)
  # - primary_contact_id (integer, needs index)
  # - subscription_plan_id (integer, needs index)
  # - ssn (string, should be encrypted)
  
  private
  
  def ensure_subscription_plan
    self.subscription_plan ||= SubscriptionPlan.default
  end
end 