class UserService
  include ActiveModel::Model
  
  def self.call(users)
    new(users).process
  end
  
  def self.process_bulk_payments(user_ids, payment_data)
    new([]).process_bulk_payments(user_ids, payment_data)
  end
  
  def initialize(users)
    @users = users
  end
  
  def process
    validate_users
    enrich_user_data
    process_pending_payments
    send_notifications
    update_metrics
  end
  
  def process_bulk_payments(user_ids, payment_data)
    # Security risk: No authorization check for bulk operations
    # Performance risk: Processing all payments synchronously
    
    users = User.where(id: user_ids).includes(:firm, :documents)
    
    results = {
      successful: [],
      failed: [],
      total_amount: 0
    }
    
    users.each do |user|
      begin
        # Process each user's pending documents
        pending_documents = user.documents.where(billing_status: :approved)
        
        pending_documents.each do |document|
          # Synchronous payment processing (blocking)
          payment_result = process_single_payment(document, payment_data)
          
          if payment_result[:success]
            results[:successful] << {
              user_id: user.id,
              document_id: document.id,
              amount: payment_result[:amount]
            }
            results[:total_amount] += payment_result[:amount]
          else
            results[:failed] << {
              user_id: user.id,
              document_id: document.id,
              error: payment_result[:error]
            }
          end
        end
        
        # Update user payment statistics
        user.update_payment_statistics!
        
      rescue => e
        Rails.logger.error "Bulk payment processing failed for user #{user.id}: #{e.message}"
        results[:failed] << {
          user_id: user.id,
          error: e.message
        }
      end
    end
    
    # Send bulk payment report
    PaymentReportMailer.bulk_payment_summary(results).deliver_now
    
    results
  end
  
  private
  
  attr_reader :users
  
  def validate_users
    users.each do |user|
      # Potential N+1 query: accessing firm and role for each user
      next unless user.firm&.active? && user.role&.permissions&.include?('billing')
      
      # Database query in loop - performance risk
      user.update(last_validated_at: Time.current)
    end
  end
  
  def enrich_user_data
    # Enhanced user data enrichment with payment info
    users.each do |user|
      # Multiple synchronous external API calls
      credit_score = CreditCheckService.get_score(user.ssn) if user.ssn.present?
      payment_history = PaymentHistoryService.fetch(user.id)
      risk_assessment = FraudDetectionService.assess_user(user.id)
      
      # Database writes in loop
      user.update(
        credit_score: credit_score,
        payment_risk_score: risk_assessment[:score],
        last_payment_check: Time.current
      )
      
      # Cache payment methods for faster processing
      cache_user_payment_methods(user)
    end
  end
  
  def process_pending_payments
    # Process any pending payments for users
    users.each do |user|
      # Find all approved documents awaiting payment
      pending_docs = user.documents.where(billing_status: :approved)
      
      pending_docs.each do |document|
        # Auto-process if user has default payment method
        if user.default_payment_method.present?
          begin
            document.process_payment!(
              user.default_payment_method,
              document.calculate_total_fee
            )
          rescue => e
            Rails.logger.warn "Auto-payment failed for document #{document.id}: #{e.message}"
          end
        end
      end
    end
  end
  
  def send_notifications
    # Enhanced notification system
    users.each do |user|
      # Send payment reminders for overdue invoices
      overdue_docs = user.documents.where(
        billing_status: :billed,
        created_at: ..30.days.ago
      )
      
      if overdue_docs.any?
        UserMailer.payment_reminder(
          user.id, 
          overdue_docs.pluck(:id)
        ).deliver_now
      end
      
      # Send monthly billing summary
      if should_send_monthly_summary?(user)
        UserMailer.monthly_billing_summary(user.id).deliver_now
      end
    end
  end
  
  def update_metrics
    # Enhanced metrics with payment data
    payment_metrics = calculate_payment_metrics(users)
    
    # Update various payment-related counters
    Metric.update_all(
      total_users: users.count,
      total_revenue: payment_metrics[:total_revenue],
      pending_payments: payment_metrics[:pending_count],
      failed_payments: payment_metrics[:failed_count],
      last_updated: Time.current
    )
    
    # Update firm-level metrics
    users.group_by(&:firm_id).each do |firm_id, firm_users|
      firm_revenue = firm_users.sum { |u| u.total_revenue || 0 }
      Firm.find(firm_id).update(monthly_revenue: firm_revenue)
    end
  end
  
  def process_single_payment(document, payment_data)
    # Extract payment method from data
    payment_method = {
      type: payment_data[:type],
      id: payment_data[:method_id],
      token: payment_data[:token]
    }
    
    begin
      transaction = document.process_payment!(payment_method, document.calculate_total_fee)
      
      {
        success: true,
        amount: transaction.amount,
        transaction_id: transaction.id
      }
    rescue => e
      {
        success: false,
        error: e.message
      }
    end
  end
  
  def cache_user_payment_methods(user)
    # Cache payment methods in Redis for faster access
    payment_methods = PaymentMethodService.fetch_for_user(user.id)
    
    Rails.cache.write(
      "user_payment_methods:#{user.id}",
      payment_methods,
      expires_in: 1.hour
    )
  end
  
  def should_send_monthly_summary?(user)
    # Check if it's the first day of the month and user hasn't received summary yet
    Date.current.day == 1 && !user.monthly_summary_sent_this_month?
  end
  
  def calculate_payment_metrics(users)
    {
      total_revenue: users.sum { |u| u.documents.revenue_generating.sum { |d| d.calculate_total_fee } },
      pending_count: users.sum { |u| u.documents.pending_payment.count },
      failed_count: users.sum { |u| u.payment_transactions.where(status: 'failed').count }
    }
  end
  
  # New dependencies introduced:
  # - CreditCheckService (external API)
  # - PaymentHistoryService (external API)
  # - FraudDetectionService (external API)
  # - PaymentMethodService (internal service)
  # - PaymentReportMailer (mailer)
  # - PaymentGateway (external payment processor)
  # - BillingNotificationJob (background job)
end 