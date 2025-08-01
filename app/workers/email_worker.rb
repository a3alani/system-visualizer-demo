class EmailWorker
  include Sidekiq::Worker
  include Sidekiq::Cron::Job
  
  # Security: Enhanced worker configuration
  sidekiq_options retry: 3, 
                  dead: false,
                  queue: :security_notifications,
                  backtrace: 5
  
  # Security: Rate limiting to prevent abuse
  RATE_LIMIT = 100 # emails per hour per firm
  SECURITY_RATE_LIMIT = 50 # security emails per hour
  
  def perform(action, recipient_id, data = {})
    # Security: Input validation and sanitization
    validate_security_params(action, recipient_id, data)
    
    # Security: Rate limiting check
    check_rate_limits(action, data)
    
    # Security: Audit logging
    log_email_activity(action, recipient_id, data)
    
    case action
    when 'security_alert'
      send_security_alert(recipient_id, data)
    when 'password_reset'
      send_password_reset(recipient_id, data)
    when 'login_notification'
      send_login_notification(recipient_id, data)
    when 'two_factor_setup'
      send_two_factor_setup(recipient_id, data)
    when 'account_lockout'
      send_account_lockout_notification(recipient_id, data)
    when 'suspicious_activity'
      send_suspicious_activity_alert(recipient_id, data)
    when 'compliance_report'
      send_compliance_report(recipient_id, data)
    else
      # Security: Log unknown action attempts
      Rails.logger.warn "Unknown email action attempted: #{action}"
      raise ArgumentError, "Unknown email action: #{action}"
    end
    
  rescue => e
    # Security: Log email failures for monitoring
    Rails.logger.error "Email worker failed: #{e.message}"
    SecurityEvent.create!(
      event_type: 'email_failure',
      details: {
        action: action,
        recipient_id: recipient_id,
        error: e.message,
        worker: self.class.name
      }
    )
    raise
  end
  
  private
  
  def validate_security_params(action, recipient_id, data)
    # Security: Validate recipient exists and is active
    recipient = User.find(recipient_id)
    unless recipient&.active?
      raise SecurityError, "Cannot send email to inactive user"
    end
    
    # Security: Validate action is allowed
    allowed_actions = %w[security_alert password_reset login_notification 
                        two_factor_setup account_lockout suspicious_activity 
                        compliance_report]
    unless allowed_actions.include?(action)
      raise SecurityError, "Unauthorized email action: #{action}"
    end
    
    # Security: Sanitize data
    data.each do |key, value|
      next unless value.is_a?(String)
      # Remove potential XSS or injection attempts
      data[key] = ActionController::Base.helpers.sanitize(value)
    end
  end
  
  def check_rate_limits(action, data)
    firm_id = data['firm_id']
    return unless firm_id
    
    # Security: Check general rate limit
    general_key = "email_rate_limit:#{firm_id}"
    general_count = Rails.cache.read(general_key) || 0
    
    if general_count >= RATE_LIMIT
      Rails.logger.warn "Email rate limit exceeded for firm #{firm_id}"
      raise SecurityError, "Email rate limit exceeded"
    end
    
    # Security: Check security email rate limit
    if security_action?(action)
      security_key = "security_email_rate_limit:#{firm_id}"
      security_count = Rails.cache.read(security_key) || 0
      
      if security_count >= SECURITY_RATE_LIMIT
        Rails.logger.warn "Security email rate limit exceeded for firm #{firm_id}"
        raise SecurityError, "Security email rate limit exceeded"
      end
      
      Rails.cache.write(security_key, security_count + 1, expires_in: 1.hour)
    end
    
    Rails.cache.write(general_key, general_count + 1, expires_in: 1.hour)
  end
  
  def log_email_activity(action, recipient_id, data)
    EmailActivity.create!(
      action: action,
      recipient_id: recipient_id,
      firm_id: data['firm_id'],
      details: {
        data_hash: Digest::SHA256.hexdigest(data.to_json),
        worker_class: self.class.name,
        queue_time: data['enqueued_at'],
        ip_address: data['ip_address']
      },
      sent_at: Time.current
    )
  end
  
  def send_security_alert(recipient_id, data)
    recipient = User.find(recipient_id)
    
    # Security: Enhanced security alert with context
    SecurityMailer.security_alert(
      recipient,
      data['alert_type'],
      {
        incident_details: data['incident_details'],
        recommended_actions: generate_security_recommendations(data['alert_type']),
        firm_id: data['firm_id'],
        timestamp: Time.current,
        reference_id: SecureRandom.uuid
      }
    ).deliver_now
  end
  
  def send_password_reset(recipient_id, data)
    recipient = User.find(recipient_id)
    
    # Security: Enhanced password reset with additional verification
    token = data['reset_token']
    
    # Security: Validate token format
    unless token&.match?(/\A[a-zA-Z0-9_\-]{32,}\z/)
      raise SecurityError, "Invalid reset token format"
    end
    
    # Security: Check if token is expired
    if data['expires_at'] && Time.parse(data['expires_at']) < Time.current
      raise SecurityError, "Reset token has expired"
    end
    
    SecurityMailer.password_reset(
      recipient,
      token,
      {
        expires_at: data['expires_at'],
        ip_address: data['ip_address'],
        user_agent: data['user_agent'],
        firm_name: recipient.firm&.name
      }
    ).deliver_now
  end
  
  def send_login_notification(recipient_id, data)
    recipient = User.find(recipient_id)
    
    # Security: Login notification with device tracking
    SecurityMailer.login_notification(
      recipient,
      {
        login_time: data['login_time'],
        ip_address: data['ip_address'],
        user_agent: data['user_agent'],
        device_info: data['device_info'],
        location: data['location'],
        suspicious: data['suspicious'] || false
      }
    ).deliver_now
  end
  
  def send_two_factor_setup(recipient_id, data)
    recipient = User.find(recipient_id)
    
    # Security: Two-factor setup with QR code
    SecurityMailer.two_factor_setup(
      recipient,
      {
        setup_url: data['setup_url'],
        backup_codes: data['backup_codes'],
        firm_policy: data['firm_policy']
      }
    ).deliver_now
  end
  
  def send_account_lockout_notification(recipient_id, data)
    recipient = User.find(recipient_id)
    
    # Security: Account lockout notification
    SecurityMailer.account_lockout(
      recipient,
      {
        lockout_reason: data['lockout_reason'],
        locked_at: data['locked_at'],
        unlock_instructions: data['unlock_instructions'],
        support_contact: data['support_contact']
      }
    ).deliver_now
  end
  
  def send_suspicious_activity_alert(recipient_id, data)
    recipient = User.find(recipient_id)
    
    # Security: Suspicious activity alert
    SecurityMailer.suspicious_activity(
      recipient,
      {
        activity_type: data['activity_type'],
        detected_at: data['detected_at'],
        activity_details: data['activity_details'],
        recommended_actions: generate_security_recommendations(data['activity_type'])
      }
    ).deliver_now
  end
  
  def send_compliance_report(recipient_id, data)
    recipient = User.find(recipient_id)
    
    # Security: Compliance report for administrators
    unless recipient.admin? || recipient.compliance_officer?
      raise SecurityError, "User not authorized to receive compliance reports"
    end
    
    ComplianceMailer.security_report(
      recipient,
      {
        report_period: data['report_period'],
        report_data: data['report_data'],
        compliance_status: data['compliance_status']
      }
    ).deliver_now
  end
  
  def security_action?(action)
    %w[security_alert account_lockout suspicious_activity 
       password_reset two_factor_setup compliance_report].include?(action)
  end
  
  def generate_security_recommendations(alert_type)
    case alert_type
    when 'unauthorized_access'
      [
        'Change your password immediately',
        'Enable two-factor authentication',
        'Review recent account activity',
        'Contact security team if suspicious'
      ]
    when 'suspicious_login'
      [
        'Verify the login was authorized',
        'Change password if unauthorized',
        'Check connected devices',
        'Enable login notifications'
      ]
    when 'data_breach'
      [
        'Change all passwords immediately',
        'Review data access logs',
        'Contact legal team',
        'Notify affected parties'
      ]
    else
      [
        'Review security settings',
        'Contact security team for guidance'
      ]
    end
  end
end 