# Firm model with performance monitoring
class Firm < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :documents, through: :users
  
  # Performance optimization: counter caches
  has_many :active_users, -> { where(active: true) }, class_name: 'User'
  has_many :payment_transactions, through: :documents
  has_many :billing_entries, through: :documents
  
  # Performance monitoring associations
  has_many :performance_metrics, dependent: :destroy
  has_many :cache_entries, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  validates :subscription_plan, presence: true
  validates :rate_multiplier, presence: true, numericality: { greater_than: 0 }
  
  # Performance monitoring scopes
  scope :active, -> { where(active: true) }
  scope :high_volume, -> { where('monthly_revenue > ?', 10000) }
  scope :performance_critical, -> { joins(:performance_metrics).where('performance_metrics.avg_response_time > ?', 1.0) }
  
  # Performance optimized methods with caching
  def total_revenue(cache_duration = 1.hour)
    cache_key = "firm_revenue_#{id}_#{Date.current}"
    
    Rails.cache.fetch(cache_key, expires_in: cache_duration) do
      # Performance risk: Complex calculation without database optimization
      documents.joins(:billing_entries)
               .where(billing_status: [:billed, :paid])
               .sum('billing_entries.amount')
    end
  end
  
  def monthly_statistics(month = Date.current.beginning_of_month)
    cache_key = "firm_stats_#{id}_#{month.strftime('%Y_%m')}"
    
    Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      date_range = month..month.end_of_month
      
      {
        total_revenue: calculate_revenue_for_period(date_range),
        document_count: documents.where(created_at: date_range).count,
        active_users: users.joins(:sessions).where('sessions.last_activity_at' => date_range).distinct.count,
        payment_volume: payment_transactions.where(created_at: date_range).sum(:amount),
        average_response_time: calculate_average_response_time(date_range)
      }
    end
  end
  
  def performance_dashboard_data
    # Performance risk: Multiple complex queries without optimization
    {
      real_time_metrics: real_time_performance_metrics,
      historical_trends: historical_performance_trends,
      bottleneck_analysis: identify_performance_bottlenecks,
      resource_utilization: calculate_resource_utilization,
      user_activity_patterns: analyze_user_activity_patterns
    }
  end
  
  def update_billing_statistics!
    # Performance risk: Expensive calculations called frequently
    start_time = Time.current
    
    # Calculate various billing metrics
    current_stats = {
      total_unbilled_hours: documents.unbilled_work.sum(:billable_hours),
      pending_payment_amount: documents.pending_payment.sum { |d| d.calculate_total_fee },
      monthly_recurring_revenue: calculate_mrr,
      average_collection_time: calculate_average_collection_time,
      client_lifetime_value: calculate_client_ltv
    }
    
    # Update firm attributes
    update!(
      monthly_revenue: current_stats[:monthly_recurring_revenue],
      pending_revenue: current_stats[:pending_payment_amount],
      billing_statistics_updated_at: Time.current
    )
    
    # Log performance metrics
    execution_time = Time.current - start_time
    log_performance_metric('billing_update', execution_time)
    
    # Performance alert for slow operations
    if execution_time > 10.seconds
      SlowQueryAlertService.alert("firm_billing_update", {
        firm_id: id,
        execution_time: execution_time,
        stats: current_stats
      })
    end
    
    current_stats
  end
  
  def cache_warm_up!
    # Performance optimization: Pre-warm frequently accessed caches
    # Security risk: No authorization check for cache warming
    
    Rails.logger.info "Starting cache warm-up for firm #{id}"
    
    # Warm up revenue caches
    total_revenue(24.hours)
    monthly_statistics
    
    # Warm up user-related caches
    users.includes(:documents, :payment_transactions).find_each do |user|
      # Performance risk: N+1 queries during cache warming
      Rails.cache.write("user_summary_#{user.id}", {
        total_documents: user.documents.count,
        total_payments: user.payment_transactions.sum(:amount),
        last_activity: user.sessions.maximum(:last_activity_at)
      }, expires_in: 1.hour)
    end
    
    # Performance risk: Synchronous external API calls during warm-up
    external_data = fetch_external_performance_data
    Rails.cache.write("external_performance_#{id}", external_data, expires_in: 30.minutes)
    
    Rails.logger.info "Cache warm-up completed for firm #{id}"
  end
  
  def invalidate_performance_caches!
    # Cache invalidation for performance-critical data
    cache_patterns = [
      "firm_revenue_#{id}_*",
      "firm_stats_#{id}_*",
      "user_summary_*",
      "external_performance_#{id}"
    ]
    
    cache_patterns.each do |pattern|
      # Performance risk: Inefficient cache clearing
      Rails.cache.delete_matched(pattern)
    end
    
    # Update cache invalidation timestamp
    update!(caches_invalidated_at: Time.current)
  end
  
  # Performance monitoring methods
  def track_performance_metric(metric_name, value, metadata = {})
    performance_metrics.create!(
      metric_name: metric_name,
      metric_value: value,
      metadata: metadata,
      recorded_at: Time.current
    )
    
    # Performance alerting
    if should_alert_for_metric?(metric_name, value)
      PerformanceAlertService.trigger_alert(self, metric_name, value, metadata)
    end
  end
  
  def optimize_database_queries!
    # Performance optimization: Analyze and optimize slow queries
    # Security risk: No authorization for database operations
    
    slow_queries = identify_slow_queries
    
    slow_queries.each do |query_info|
      case query_info[:type]
      when 'missing_index'
        suggest_database_index(query_info)
      when 'inefficient_join'
        suggest_query_optimization(query_info)
      when 'large_dataset'
        suggest_pagination_strategy(query_info)
      end
    end
  end
  
  private
  
  def calculate_revenue_for_period(date_range)
    # Performance: Use database aggregation instead of Ruby calculation
    billing_entries.joins(:document)
                   .where(documents: { created_at: date_range, billing_status: [:billed, :paid] })
                   .sum(:amount)
  end
  
  def calculate_average_response_time(date_range)
    performance_metrics.where(
      metric_name: 'response_time',
      recorded_at: date_range
    ).average(:metric_value) || 0.0
  end
  
  def real_time_performance_metrics
    # Performance risk: Real-time calculations without caching
    {
      current_load: calculate_current_system_load,
      active_sessions: users.joins(:sessions).where('sessions.last_activity_at > ?', 15.minutes.ago).count,
      queue_depth: get_sidekiq_queue_depth,
      memory_usage: get_memory_usage_stats,
      response_times: get_recent_response_times
    }
  end
  
  def historical_performance_trends(days = 30)
    date_range = days.days.ago..Time.current
    
    performance_metrics.where(recorded_at: date_range)
                      .group_by_day(:recorded_at)
                      .group(:metric_name)
                      .average(:metric_value)
  end
  
  def identify_performance_bottlenecks
    # Performance analysis based on metrics
    bottlenecks = []
    
    # Check for slow database queries
    slow_query_threshold = 1.0 # seconds
    recent_slow_queries = performance_metrics.where(
      metric_name: 'query_time',
      recorded_at: 1.hour.ago..Time.current
    ).where('metric_value > ?', slow_query_threshold)
    
    if recent_slow_queries.any?
      bottlenecks << {
        type: 'database',
        severity: 'high',
        count: recent_slow_queries.count,
        average_time: recent_slow_queries.average(:metric_value)
      }
    end
    
    # Check for memory usage issues
    high_memory_usage = performance_metrics.where(
      metric_name: 'memory_usage',
      recorded_at: 1.hour.ago..Time.current
    ).where('metric_value > ?', 0.8) # 80% memory usage
    
    if high_memory_usage.any?
      bottlenecks << {
        type: 'memory',
        severity: 'medium',
        peak_usage: high_memory_usage.maximum(:metric_value)
      }
    end
    
    bottlenecks
  end
  
  def calculate_mrr
    # Monthly Recurring Revenue calculation
    # Performance risk: Complex calculation without proper caching
    monthly_payments = payment_transactions.where(
      created_at: 1.month.ago..Time.current,
      status: 'completed'
    ).sum(:amount)
    
    # Apply growth projections
    growth_factor = calculate_growth_factor
    (monthly_payments * growth_factor).round(2)
  end
  
  def log_performance_metric(operation, execution_time)
    track_performance_metric(operation, execution_time, {
      timestamp: Time.current,
      firm_id: id,
      operation_type: 'billing'
    })
  end
  
  def fetch_external_performance_data
    # Performance risk: Synchronous external API calls
    {
      uptime_status: UptimeService.check_status(id),
      external_integrations: IntegrationHealthService.check_all(id),
      third_party_response_times: ThirdPartyMonitorService.get_metrics(id)
    }
  rescue => e
    Rails.logger.error "Failed to fetch external performance data for firm #{id}: #{e.message}"
    {}
  end
  
  def should_alert_for_metric?(metric_name, value)
    thresholds = {
      'response_time' => 2.0,
      'memory_usage' => 0.85,
      'query_time' => 1.0,
      'error_rate' => 0.05
    }
    
    threshold = thresholds[metric_name]
    threshold && value > threshold
  end
  
  # New dependencies introduced:
  # - PerformanceMetric (performance tracking model)
  # - CacheEntry (cache management model)
  # - SlowQueryAlertService (performance monitoring)
  # - PerformanceAlertService (alerting system)
  # - UptimeService (external monitoring)
  # - IntegrationHealthService (health checks)
  # - ThirdPartyMonitorService (external metrics)
end 