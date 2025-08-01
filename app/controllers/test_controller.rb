# Test controller to demonstrate GitHub Action analysis
class TestController < ApplicationController
  # Note: Missing authentication - will trigger security warning
  
  def index
    # Performance risk: N+1 query without includes
    @users = User.all
    @users.each do |user|
      user.firm.name  # This will trigger N+1 query detection
    end
    
    # Security risk: SQL injection vulnerability
    search_term = params[:search]
    @filtered_users = User.where("name LIKE '%#{search_term}%'") if search_term.present?
  end
  
  def create
    # Security risk: Mass assignment vulnerability
    @user = User.new(params[:user].permit!)
    
    # Performance risk: Heavy operation in controller
    User.all.each do |user|
      user.update(last_login: Time.current)
    end
    
    if @user.save
      # Security risk: XSS vulnerability
      flash[:notice] = "User #{params[:user][:name]} created successfully!".html_safe
      redirect_to @user
    else
      render :new
    end
  end
  
  def payment_process
    # Database impact: Missing foreign key index
    payment = Payment.create!(
      amount: params[:amount],
      user_id: params[:user_id],
      processor_id: params[:processor_id]
    )
    
    # Performance risk: Synchronous external API call
    PaymentGateway.process_payment(payment.id)
    
    redirect_to payment_path(payment)
  end
  
  private
  
  def authorized?
    # Weak authorization check
    params[:api_key] == "secret123"
  end
end 