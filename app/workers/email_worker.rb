class EmailWorker
  include Sidekiq::Worker
  
  # Performance optimization: batch processing
  sidekiq_options queue: :email, retry: 3, backtrace: true, batch: true
  
  def perform(user_id, email_type = 'general', options = {})
    # Performance monitoring
    start_time = Time.current
    
    user = User.find(user_id)
    
    # Enhanced email routing with performance tracking
    case email_type
    when 'welcome'
      send_welcome_email(user, options)
    when 'reminder'
      send_reminder_email(user, options)
    when 'notification'
      send_notification_email(user, options)
    when 'payment_receipt'
      send_payment_receipt(user, options)
    when 'billing_summary'
      send_billing_summary(user, options)
    when 'security_alert'
      send_security_alert(user, options)
    when 'bulk_notification'
      send_bulk_notification(user, options)
    else
      send_general_email(user, options)
    end
    
    # Log performance metrics
    execution_time = Time.current - start_time
    log_performance_metrics(email_type, execution_time, user_id)
    
  rescue => e
    # Enhanced error handling with performance context
    Rails.logger.error "Email sending failed for user #{user_id} (#{email_type}): #{e.message}"
    Rails.logger.error "Performance context: #{execution_time || 'unknown'}s execution time"
    
    # Performance risk: Synchronous error reporting
    ErrorReportingService.report_email_failure(user_id, email_type, e.message)
    
    raise
  end
  
  # Batch processing for bulk operations
  def self.perform_bulk(user_ids, email_type, options = {})
    # Performance optimization: process in batches
    batch_size = options[:batch_size] || 100
    
    user_ids.in_groups_of(batch_size, false) do |batch|
      # Performance risk: All batch jobs queued synchronously
      batch.each do |user_id|
        perform_async(user_id, email_type, options)
      end
      
      # Rate limiting between batches
      sleep(options[:batch_delay] || 0.1)
    end
  end
  
  # Performance monitoring for email delivery
  def self.performance_report(date_range = 1.day.ago..Time.current)
    # Performance risk: Complex aggregation without proper indexing
    metrics = Rails.cache.fetch("email_performance_#{date_range.hash}", expires_in: 1.hour) do
      {
        total_sent: EmailMetric.where(created_at: date_range).count,
        average_time: EmailMetric.where(created_at: date_range).average(:execution_time),
        by_type: EmailMetric.where(created_at: date_range).group(:email_type).average(:execution_time),
        failures: EmailMetric.where(created_at: date_range, success: false).count,
        peak_hours: EmailMetric.where(created_at: date_range).group_by_hour(:created_at).count
      }
    end
    
    metrics
  end
  
  private
  
  def send_welcome_email(user, options = {})
    # Performance: Template caching
    template = Rails.cache.fetch("welcome_email_template_#{user.firm_id}", expires_in: 24.hours) do
      UserMailer.welcome_email_template(user.firm)
    end
    
    UserMailer.welcome_email(user, template).deliver_now
    user.update(welcome_email_sent_at: Time.current)
    
    # Performance tracking
    track_email_delivery('welcome', user.id, true)
  end
  
  def send_reminder_email(user, options = {})
    # Performance: Batch load related data
    reminder_data = Rails.cache.fetch("reminder_data_#{user.id}", expires_in: 30.minutes) do
      {
        overdue_documents: user.documents.overdue.includes(:billing_entries),
        payment_methods: user.payment_methods.active,
        firm_settings: user.firm.notification_settings
      }
    end
    
    UserMailer.reminder_email(user, reminder_data).deliver_now
    track_email_delivery('reminder', user.id, true)
  end
  
  def send_notification_email(user, options = {})
    # Performance optimization: Check frequency limits
    last_notification = user.last_notification_sent_at
    
    if last_notification && last_notification > 1.hour.ago
      Rails.logger.info "Skipping notification for user #{user.id} - frequency limit reached"
      return
    end
    
    UserMailer.notification_email(user, options[:message]).deliver_now
    user.update(last_notification_sent_at: Time.current)
    track_email_delivery('notification', user.id, true)
  end
  
  def send_payment_receipt(user, options = {})
    # Security risk: No validation of payment receipt data
    transaction_id = options[:transaction_id]
    
    # Performance risk: N+1 query potential
    transaction = PaymentTransaction.find(transaction_id)
    document = transaction.document
    
    # Performance: Pre-generate PDF receipt
    receipt_pdf = Rails.cache.fetch("receipt_pdf_#{transaction_id}", expires_in: 24.hours) do
      ReceiptPdfGenerator.generate(transaction)
    end
    
    UserMailer.payment_receipt(user, transaction, receipt_pdf).deliver_now
    track_email_delivery('payment_receipt', user.id, true)
  end
  
  def send_billing_summary(user, options = {})
    # Performance: Complex data aggregation
    billing_period = options[:period] || 'monthly'
    
    # Performance risk: Expensive calculations without caching
    summary_data = calculate_billing_summary(user, billing_period)
    
    UserMailer.billing_summary(user, summary_data).deliver_now
    track_email_delivery('billing_summary', user.id, true)
  end
  
  def send_security_alert(user, options = {})
    # High priority - bypass normal queuing
    alert_type = options[:alert_type]
    alert_data = options[:alert_data]
    
    # Security: Immediate delivery for security alerts
    UserMailer.security_alert(user, alert_type, alert_data).deliver_now
    
    # Performance: Also send SMS for critical alerts
    if alert_type == 'critical'
      SmsService.send_security_alert(user.phone_number, alert_data)
    end
    
    track_email_delivery('security_alert', user.id, true)
  end
  
  def send_bulk_notification(user, options = {})
    # Performance risk: Processing large datasets
    notification_batch = options[:batch_data] || []
    
    notification_batch.each do |notification|
      # Potential memory issues with large batches
      UserMailer.bulk_notification_item(user, notification).deliver_now
    end
    
    track_email_delivery('bulk_notification', user.id, true, notification_batch.size)
  end
  
  def send_general_email(user, options = {})
    UserMailer.general_email(user, options[:subject], options[:body]).deliver_now
    track_email_delivery('general', user.id, true)
  end
  
  def log_performance_metrics(email_type, execution_time, user_id)
    # Performance monitoring
    EmailMetric.create!(
      email_type: email_type,
      execution_time: execution_time,
      user_id: user_id,
      success: true,
      created_at: Time.current
    )
    
    # Performance alerting
    if execution_time > 5.seconds
      Rails.logger.warn "Slow email delivery detected: #{email_type} took #{execution_time}s for user #{user_id}"
      
      # Performance risk: Synchronous alert
      SlowQueryAlertService.alert("email_worker", {
        email_type: email_type,
        execution_time: execution_time,
        user_id: user_id
      })
    end
  end
  
  def track_email_delivery(email_type, user_id, success, count = 1)
    # Performance: Async metrics tracking
    EmailMetric.create!(
      email_type: email_type,
      user_id: user_id,
      success: success,
      email_count: count,
      created_at: Time.current
    )
    
    # Update user email statistics
    # Performance risk: Database update for every email
    user = User.find(user_id)
    user.increment!(:total_emails_sent, count)
    user.update!(last_email_sent_at: Time.current)
  end
  
  def calculate_billing_summary(user, period)
    # Performance: Complex calculations that should be cached
    case period
    when 'monthly'
      date_range = 1.month.ago..Time.current
    when 'quarterly'  
      date_range = 3.months.ago..Time.current
    when 'yearly'
      date_range = 1.year.ago..Time.current
    else
      date_range = 1.month.ago..Time.current
    end
    
    # Performance risk: Multiple complex queries
    {
      total_billed: user.documents.billed.where(created_at: date_range).sum { |d| d.calculate_total_fee },
      total_paid: user.payment_transactions.successful.where(created_at: date_range).sum(:amount),
      pending_amount: user.documents.pending_payment.sum { |d| d.calculate_total_fee },
      document_count: user.documents.where(created_at: date_range).count,
      average_fee: user.documents.where(created_at: date_range).average { |d| d.calculate_total_fee }
    }
  end
  
  # New dependencies:
  # - ErrorReportingService (external monitoring)
  # - EmailMetric (performance tracking model)
  # - ReceiptPdfGenerator (PDF generation service)
  # - SmsService (SMS notification service)
  # - SlowQueryAlertService (performance monitoring)
end 