# Test controller to demonstrate GitHub Action analysis
class TestController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @users = User.where(active: true)
    UserService.call(@users)
    render json: @users
  end
  
  def show
    @user = User.find(params[:id])
    @documents = Document.where(user: @user)
    
    respond_to do |format|
      format.html
      format.json { render json: @user }
    end
  end
  
  def create
    @user = User.new(user_params)
    
    if @user.save
      EmailWorker.perform_async(@user.id)
      redirect_to @user, notice: 'User created successfully'
    else
      render :new
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:name, :email, :firm_id)
  end
  
  def authenticate_user!
    # Simple authentication check
    redirect_to login_path unless current_user
  end
end 