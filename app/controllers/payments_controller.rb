class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment, only: [:show, :update, :destroy, :process, :refund]
  before_action :authorize_payment_access, only: [:show, :update, :destroy, :process, :refund]
  
  def index
    @payments = current_user.payments
                           .includes(:firm)
                           .recent
                           .order(created_at: :desc)
                           .page(params[:page])
    
    respond_to do |format|
      format.html
      format.json { render json: PaymentSerializer.new(@payments) }
    end
  end
  
  def show
    respond_to do |format|
      format.html
      format.json { render json: PaymentSerializer.new(@payment) }
    end
  end
  
  def create
    @payment = current_user.payments.build(payment_params)
    @payment.firm = current_firm if current_firm
    
    if @payment.save
      PaymentProcessingJob.perform_later(@payment)
      
      respond_to do |format|
        format.html { redirect_to @payment, notice: 'Payment was successfully created.' }
        format.json { render json: PaymentSerializer.new(@payment), status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: { errors: @payment.errors }, status: :unprocessable_entity }
      end
    end
  end
  
  def update
    if @payment.update(payment_params)
      respond_to do |format|
        format.html { redirect_to @payment, notice: 'Payment was successfully updated.' }
        format.json { render json: PaymentSerializer.new(@payment) }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render json: { errors: @payment.errors }, status: :unprocessable_entity }
      end
    end
  end
  
  def process
    if @payment.process_payment!
      render json: { 
        message: 'Payment processed successfully',
        payment: PaymentSerializer.new(@payment)
      }
    else
      render json: { 
        error: 'Payment processing failed',
        errors: @payment.errors 
      }, status: :unprocessable_entity
    end
  rescue => e
    render json: { 
      error: 'Payment processing error',
      message: e.message 
    }, status: :internal_server_error
  end
  
  def refund
    if @payment.refund!
      render json: { 
        message: 'Payment refunded successfully',
        payment: PaymentSerializer.new(@payment)
      }
    else
      render json: { 
        error: 'Refund failed'
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @payment.destroy
    respond_to do |format|
      format.html { redirect_to payments_url, notice: 'Payment was successfully deleted.' }
      format.json { head :no_content }
    end
  end
  
  private
  
  def set_payment
    @payment = current_user.payments.find(params[:id])
  end
  
  def authorize_payment_access
    unless @payment.user == current_user || current_user.admin?
      respond_to do |format|
        format.html { redirect_to root_path, alert: 'Access denied.' }
        format.json { render json: { error: 'Access denied' }, status: :forbidden }
      end
    end
  end
  
  def payment_params
    params.require(:payment).permit(:amount, :currency, :description, :firm_id)
  end
  
  def current_firm
    @current_firm ||= current_user.firms.find(params[:firm_id]) if params[:firm_id]
  end
end 