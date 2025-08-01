class User < ApplicationRecord
  belongs_to :firm
  has_many :documents, dependent: :destroy
  has_many :payments
  has_and_belongs_to_many :cases
  
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  
  scope :active, -> { where(active: true) }
  
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def send_welcome_email
    EmailWorker.perform_async(id, 'welcome')
  end
  
  private
  
  def normalize_email
    self.email = email.downcase if email.present?
  end
end 