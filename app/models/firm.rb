class Firm < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :documents, through: :users
  has_many :cases
  
  validates :name, presence: true
  validates :subscription_type, inclusion: { in: %w[basic premium enterprise] }
  
  def active_users
    users.where(active: true)
  end
  
  def total_documents
    documents.count
  end
end 