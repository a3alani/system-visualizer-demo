class EmailWorker
  include Sidekiq::Worker
  
  def perform(user_id, email_type = 'general')
    user = User.find(user_id)
    
    case email_type
    when 'welcome'
      send_welcome_email(user)
    when 'reminder'
      send_reminder_email(user)
    when 'notification'
      send_notification_email(user)
    else
      send_general_email(user)
    end
  rescue => e
    Rails.logger.error "Email sending failed for user #{user_id}: #{e.message}"
    raise
  end
  
  private
  
  def send_welcome_email(user)
    UserMailer.welcome_email(user).deliver_now
    user.update(welcome_email_sent_at: Time.current)
  end
  
  def send_reminder_email(user)
    UserMailer.reminder_email(user).deliver_now
  end
  
  def send_notification_email(user)
    UserMailer.notification_email(user).deliver_now
  end
  
  def send_general_email(user)
    UserMailer.general_email(user).deliver_now
  end
end 