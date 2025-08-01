# Document model with payment integration
class Document < ApplicationRecord
  belongs_to :user
  belongs_to :firm
  
  # Payment-related associations
  has_many :billing_entries, dependent: :destroy
  has_many :payment_transactions, through: :billing_entries
  belongs_to :billing_category, optional: true
  
  # Document versioning for billing purposes
  has_many :document_versions, dependent: :destroy
  has_one :latest_version, -> { order(created_at: :desc) }, class_name: 'DocumentVersion'
  
  # Validations
  validates :title, presence: true
  validates :file_path, presence: true
  validates :document_type, presence: true
  validates :billable_hours, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :hourly_rate, presence: true, numericality: { greater_than: 0 }
  
  # Enums
  enum document_type: {
    contract: 0,
    invoice: 1, 
    legal_brief: 2,
    court_filing: 3,
    billing_statement: 4,
    payment_receipt: 5
  }
  
  enum billing_status: {
    unbilled: 0,
    pending_review: 1,
    approved: 2,
    billed: 3,
    paid: 4,
    disputed: 5
  }
  
  # Scopes for financial reporting
  scope :billable, -> { where.not(billable_hours: 0) }
  scope :unbilled_work, -> { billable.where(billing_status: :unbilled) }
  scope :pending_payment, -> { where(billing_status: [:approved, :billed]) }
  scope :revenue_generating, -> { where(billing_status: [:billed, :paid]) }
  
  # Payment calculation methods
  def calculate_total_fee
    # Potential performance issue: complex calculation without caching
    base_fee = billable_hours * hourly_rate
    
    # Add complexity-based surcharge
    complexity_multiplier = case document_type
                           when 'contract' then 1.2
                           when 'legal_brief' then 1.5
                           when 'court_filing' then 1.8
                           else 1.0
                           end
    
    # Apply firm-specific rates
    firm_multiplier = firm.rate_multiplier || 1.0
    
    (base_fee * complexity_multiplier * firm_multiplier).round(2)
  end
  
  def generate_billing_entry!
    # Security risk: No authorization check for billing
    return if billing_status == 'billed'
    
    total_amount = calculate_total_fee
    
    # Create billing entry
    billing_entry = billing_entries.create!(
      amount: total_amount,
      description: "#{document_type.humanize}: #{title}",
      billable_hours: billable_hours,
      hourly_rate: hourly_rate,
      billing_date: Time.current,
      user: user,
      firm: firm
    )
    
    # Update status
    update!(billing_status: :pending_review)
    
    # Potential N+1 query issue
    user.firm.update_billing_statistics!
    
    billing_entry
  end
  
  def process_payment!(payment_method, amount)
    # Security risk: No payment validation
    # Performance risk: Synchronous payment processing
    
    unless billing_status == 'approved'
      raise "Document must be approved before payment processing"
    end
    
    # External payment API call (blocking)
    payment_result = PaymentGateway.charge(
      amount: amount,
      payment_method: payment_method,
      description: "Payment for #{title}",
      metadata: {
        document_id: id,
        user_id: user_id,
        firm_id: firm_id
      }
    )
    
    if payment_result.success?
      # Create payment transaction
      transaction = payment_transactions.create!(
        amount: amount,
        payment_method_type: payment_method[:type],
        payment_method_id: payment_method[:id],
        gateway_transaction_id: payment_result.transaction_id,
        gateway_fee: payment_result.fee,
        processed_at: Time.current,
        status: 'completed'
      )
      
      # Update billing status
      update!(
        billing_status: :paid,
        payment_processed_at: Time.current
      )
      
      # Send receipt (potential performance bottleneck)
      DocumentMailer.payment_receipt(id, transaction.id).deliver_now
      
      transaction
    else
      # Log payment failure
      Rails.logger.error "Payment failed for document #{id}: #{payment_result.error_message}"
      
      payment_transactions.create!(
        amount: amount,
        payment_method_type: payment_method[:type],
        payment_method_id: payment_method[:id],
        gateway_error: payment_result.error_message,
        status: 'failed',
        processed_at: Time.current
      )
      
      raise "Payment processing failed: #{payment_result.error_message}"
    end
  end
  
  def refund_payment!(reason = nil)
    # Find the successful payment transaction
    successful_transaction = payment_transactions.where(status: 'completed').last
    
    unless successful_transaction
      raise "No successful payment found for refund"
    end
    
    # Process refund through gateway
    refund_result = PaymentGateway.refund(
      transaction_id: successful_transaction.gateway_transaction_id,
      amount: successful_transaction.amount,
      reason: reason
    )
    
    if refund_result.success?
      # Create refund transaction record
      payment_transactions.create!(
        amount: -successful_transaction.amount,
        payment_method_type: successful_transaction.payment_method_type,
        gateway_transaction_id: refund_result.refund_id,
        gateway_fee: refund_result.fee,
        processed_at: Time.current,
        status: 'refunded',
        refund_reason: reason
      )
      
      # Update document status
      update!(billing_status: :disputed)
      
      true
    else
      Rails.logger.error "Refund failed for document #{id}: #{refund_result.error_message}"
      false
    end
  end
  
  # Financial reporting
  def self.revenue_report(date_range = 1.month.ago..Time.current)
    # Potential performance issue: complex aggregation without proper indexing
    paid_documents = where(
      billing_status: :paid,
      payment_processed_at: date_range
    )
    
    {
      total_revenue: paid_documents.joins(:billing_entries).sum('billing_entries.amount'),
      document_count: paid_documents.count,
      average_fee: paid_documents.joins(:billing_entries).average('billing_entries.amount'),
      by_type: paid_documents.group(:document_type).joins(:billing_entries).sum('billing_entries.amount')
    }
  end
  
  # Database migration needed for new fields:
  # - billing_category_id (integer, needs index)
  # - billable_hours (decimal, precision: 8, scale: 2)
  # - hourly_rate (decimal, precision: 8, scale: 2)
  # - billing_status (integer, default: 0, needs index)
  # - payment_processed_at (datetime, needs index)
  
  private
  
  def notify_billing_team
    # Background job for billing notifications
    BillingNotificationJob.perform_later(id)
  end
end 