class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :firm
  
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, inclusion: { in: %w[USD EUR GBP] }
  validates :status, presence: true
  
  enum status: {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3,
    refunded: 4
  }
  
  scope :successful, -> { where(status: [:completed]) }
  scope :failed_payments, -> { where(status: [:failed]) }
  scope :recent, -> { where(created_at: 1.month.ago..Time.current) }
  
  def process_payment!
    update!(status: :processing)
    
    begin
      result = PaymentGateway.charge(
        amount: amount,
        currency: currency,
        source: payment_method_token
      )
      
      if result.success?
        update!(
          status: :completed,
          transaction_id: result.transaction_id,
          processed_at: Time.current
        )
        NotificationService.payment_success(self)
      else
        update!(
          status: :failed,
          failure_reason: result.error_message
        )
        NotificationService.payment_failed(self)
      end
    rescue => e
      update!(
        status: :failed,
        failure_reason: e.message
      )
      Rails.logger.error "Payment processing failed: #{e.message}"
      raise
    end
  end
  
  def refund!
    return false unless completed?
    
    result = PaymentGateway.refund(transaction_id, amount)
    if result.success?
      update!(
        status: :refunded,
        refunded_at: Time.current
      )
      NotificationService.payment_refunded(self)
      true
    else
      false
    end
  end
  
  def display_amount
    "#{currency} #{amount}"
  end
  
  private
  
  def payment_method_token
    user.default_payment_method&.token
  end
end 