# Test controller to demonstrate GitHub Action analysis
class TestController < ApplicationController
  before_action :authenticate_user!, except: [:public_info]
  before_action :check_two_factor, only: [:sensitive_data]
  
  def index
    # Improved query with includes
    @users = User.includes(:firm, :role).active_with_recent_activity
    
    # Security: Proper parameter validation
    if params[:search].present?
      # Fixed SQL injection vulnerability
      @filtered_users = @users.where("LOWER(users.name) LIKE LOWER(?)", "%#{params[:search]}%")
    end
    
    render json: @users.select(:id, :name, :email, :role_id)
  end
  
  def authenticate
    email = params[:email]
    password = params[:password]
    token = params[:two_factor_token]
    
    # Authentication logic
    user = User.find_by(email: email)
    
    unless user&.authenticate_with_password(password)
      # Security: Log failed attempts
      Rails.logger.warn "Failed login attempt for #{email} from #{request.remote_ip}"
      render json: { error: 'Invalid credentials' }, status: :unauthorized
      return
    end
    
    # Two-factor authentication check
    if user.two_factor_enabled? && !user.verify_two_factor_token(token)
      render json: { error: 'Invalid two-factor token' }, status: :unauthorized
      return
    end
    
    # Create session
    session = user.create_session!(request.remote_ip, request.user_agent)
    
    # Log successful login
    user.log_security_event('login', {
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      session_id: session.id
    })
    
    render json: { 
      token: session.session_token,
      user: user.slice(:id, :name, :email),
      permissions: user.role&.permissions || []
    }
  end
  
  def change_password
    current_password = params[:current_password]
    new_password = params[:new_password]
    
    # Vulnerability: No rate limiting on password changes
    unless current_user.authenticate_with_password(current_password)
      render json: { error: 'Current password is incorrect' }, status: :unauthorized
      return
    end
    
    # Weak password validation
    if new_password.length < 8
      render json: { error: 'Password must be at least 8 characters' }, status: :unprocessable_entity
      return
    end
    
    # Update password
    current_user.update!(password_hash: BCrypt::Password.create(new_password))
    
    # Force logout from all devices
    current_user.expire_all_sessions!
    
    # Log security event
    current_user.log_security_event('password_change', {
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    })
    
    render json: { message: 'Password updated successfully' }
  end
  
  def enable_two_factor
    # Security risk: No validation of user's identity before enabling 2FA
    current_user.enable_two_factor!
    
    qr_code_url = generate_qr_code_url(current_user)
    
    render json: {
      secret: current_user.two_factor_secret, # Security risk: exposing secret in response
      qr_code_url: qr_code_url
    }
  end
  
  def public_info
    # No authentication required
    render json: {
      app_name: 'System Visualizer Demo',
      version: '2.0.0',
      features: ['AI Analysis', 'Security Scanning', 'Performance Monitoring']
    }
  end
  
  private
  
  def authenticate_user!
    token = request.headers['Authorization']&.sub('Bearer ', '')
    
    return render_unauthorized unless token
    
    @current_session = Session.find_by(session_token: token, expired_at: nil)
    return render_unauthorized unless @current_session
    
    # Update last activity
    @current_session.update!(last_activity_at: Time.current)
    @current_user = @current_session.user
  end
  
  def check_two_factor
    unless current_user.two_factor_enabled?
      render json: { error: 'Two-factor authentication required' }, status: :forbidden
    end
  end
  
  def current_user
    @current_user
  end
  
  def render_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
  
  def generate_qr_code_url(user)
    # Simplified QR code URL generation
    "https://chart.googleapis.com/chart?chs=200x200&chld=M|0&cht=qr&chl=otpauth://totp/SystemVisualizer:#{user.email}?secret=#{user.two_factor_secret}"
  end
end 