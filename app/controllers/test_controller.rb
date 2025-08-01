# Test controller to demonstrate GitHub Action analysis
class TestController < ApplicationController
  # Refactored: Added proper authentication and authorization
  before_action :authenticate_user!
  before_action :authorize_admin!, only: [:admin_dashboard, :system_health]
  before_action :set_test_data, only: [:show, :update, :destroy]
  before_action :rate_limit_check, only: [:create, :update]
  
  # Refactored: Added proper error handling
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
  rescue_from RateLimitExceeded, with: :handle_rate_limit
  
  def index
    # Refactored: Improved query performance and pagination
    @tests = current_user.accessible_tests
                         .includes(:user, :test_results)
                         .order(created_at: :desc)
                         .page(params[:page])
                         .per(25)
    
    # Refactored: Support multiple response formats
    respond_to do |format|
      format.html
      format.json { render json: serialize_tests(@tests) }
      format.csv { send_data generate_csv(@tests) }
    end
  end
  
  def show
    # Refactored: Enhanced security checks
    authorize_test_access!
    
    respond_to do |format|
      format.html
      format.json { render json: serialize_test(@test) }
    end
  end
  
  def create
    # Refactored: Extracted creation logic to service
    result = TestCreationService.call(
      user: current_user,
      params: test_params,
      ip_address: request.remote_ip
    )
    
    if result.success?
      @test = result.test
      render json: { 
        message: 'Test created successfully',
        test: serialize_test(@test),
        redirect_url: test_path(@test)
      }, status: :created
    else
      render json: {
        error: 'Test creation failed',
        errors: result.errors
      }, status: :unprocessable_entity
    end
  end
  
  def update
    # Refactored: Added update authorization and audit logging
    authorize_test_modification!
    
    if @test.update(test_params)
      log_test_modification('updated')
      
      render json: {
        message: 'Test updated successfully',
        test: serialize_test(@test)
      }
    else
      render json: {
        error: 'Update failed',
        errors: @test.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    # Refactored: Added soft delete and audit trail
    authorize_test_modification!
    
    @test.soft_delete!(
      deleted_by: current_user,
      deletion_reason: params[:reason]
    )
    
    log_test_modification('deleted')
    
    render json: { message: 'Test deleted successfully' }
  end
  
  # Refactored: Added admin functionality
  def admin_dashboard
    @statistics = {
      total_tests: Test.count,
      active_tests: Test.active.count,
      failed_tests: Test.failed.count,
      average_execution_time: Test.average(:execution_time)
    }
    
    @recent_activities = TestActivity.recent.includes(:user, :test).limit(10)
  end
  
  def system_health
    # Refactored: Comprehensive system health check
    health_status = SystemHealthService.check_all
    
    render json: {
      status: health_status.overall_status,
      components: health_status.component_statuses,
      timestamp: Time.current
    }
  end
  
  private
  
  # Refactored: Organized private methods
  def set_test_data
    @test = current_user.accessible_tests.find(params[:id])
  end
  
  def authorize_admin!
    unless current_user.admin?
      render json: { error: 'Admin access required' }, status: :forbidden
    end
  end
  
  def authorize_test_access!
    unless @test.accessible_by?(current_user)
      render json: { error: 'Access denied' }, status: :forbidden
    end
  end
  
  def authorize_test_modification!
    unless @test.modifiable_by?(current_user)
      render json: { error: 'Modification not allowed' }, status: :forbidden
    end
  end
  
  def rate_limit_check
    if RateLimiter.exceeded?(current_user, action_name)
      raise RateLimitExceeded, "Rate limit exceeded for #{action_name}"
    end
  end
  
  def log_test_modification(action)
    TestActivity.create!(
      user: current_user,
      test: @test,
      action: action,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end
  
  def serialize_test(test)
    {
      id: test.id,
      name: test.name,
      status: test.status,
      created_at: test.created_at,
      updated_at: test.updated_at,
      user: {
        id: test.user.id,
        name: test.user.name
      }
    }
  end
  
  def serialize_tests(tests)
    tests.map { |test| serialize_test(test) }
  end
  
  def generate_csv(tests)
    # CSV generation logic
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Name', 'Status', 'Created At', 'User']
      tests.each do |test|
        csv << [test.id, test.name, test.status, test.created_at, test.user.name]
      end
    end
  end
  
  def test_params
    params.require(:test).permit(:name, :description, :test_type, :configuration)
  end
  
  # Refactored: Error handling methods
  def handle_not_found
    render json: { error: 'Test not found' }, status: :not_found
  end
  
  def handle_validation_error(exception)
    render json: { 
      error: 'Validation failed',
      errors: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end
  
  def handle_rate_limit(exception)
    render json: { 
      error: exception.message,
      retry_after: RateLimiter.retry_after(current_user)
    }, status: :too_many_requests
  end
end 