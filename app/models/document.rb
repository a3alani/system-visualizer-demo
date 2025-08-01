# Document model with payment integration
class Document < ApplicationRecord
  # Refactored: Moved constants to top for better organization
  VALID_TYPES = %w[contract invoice receipt agreement policy].freeze
  MAX_FILE_SIZE = 10.megabytes
  ALLOWED_FORMATS = %w[pdf doc docx txt].freeze
  
  # Refactored: Grouped all associations together
  belongs_to :user
  belongs_to :firm, optional: true
  has_many :document_versions, dependent: :destroy
  has_many :document_permissions, dependent: :destroy
  has_many :permitted_users, through: :document_permissions, source: :user
  
  # Refactored: Grouped all validations together
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :document_type, presence: true, inclusion: { in: VALID_TYPES }
  validates :file_size, numericality: { less_than: MAX_FILE_SIZE }
  validates :file_format, inclusion: { in: ALLOWED_FORMATS }
  validate :validate_file_content
  
  # Refactored: Organized scopes logically
  scope :by_type, ->(type) { where(document_type: type) }
  scope :recent, -> { where(created_at: 1.month.ago..Time.current) }
  scope :accessible_by, ->(user) { where(user: user).or(joins(:document_permissions).where(document_permissions: { user: user })) }
  scope :contracts, -> { where(document_type: 'contract') }
  scope :invoices, -> { where(document_type: 'invoice') }
  
  # Refactored: Extracted file handling into separate methods
  def upload_file(file_params)
    validate_upload_params(file_params)
    
    processed_file = process_file_upload(file_params)
    update_file_attributes(processed_file)
    
    create_document_version(processed_file)
    generate_file_hash(processed_file)
  end
  
  def download_url(expires_in: 1.hour)
    # Refactored: Centralized URL generation logic
    if cloud_storage_enabled?
      cloud_storage.signed_url(file_path, expires_in: expires_in)
    else
      local_file_url
    end
  end
  
  # Refactored: Improved permission checking methods
  def accessible_by?(user)
    return true if user == self.user
    return true if user.admin?
    
    document_permissions.exists?(user: user)
  end
  
  def grant_access(user, permission_level = 'read')
    return false if user == self.user # Owner already has full access
    
    permission = document_permissions.find_or_initialize_by(user: user)
    permission.permission_level = permission_level
    permission.save!
  end
  
  def revoke_access(user)
    document_permissions.where(user: user).destroy_all
  end
  
  # Refactored: Extracted search functionality
  def self.search(query, user = nil)
    scope = user ? accessible_by(user) : all
    
    scope.where(
      "title ILIKE :query OR content ILIKE :query OR document_type ILIKE :query",
      query: "%#{query}%"
    )
  end
  
  # Refactored: Extracted archival logic
  def archive!(reason = nil)
    transaction do
      update!(
        archived: true,
        archived_at: Time.current,
        archive_reason: reason
      )
      
      # Clean up temporary files
      cleanup_temp_files
      
      # Log archival
      Rails.logger.info "Document #{id} archived: #{reason}"
    end
  end
  
  private
  
  # Refactored: Private methods are now properly organized
  def validate_upload_params(params)
    raise ArgumentError, "File is required" unless params[:file]
    raise ArgumentError, "File too large" if params[:file].size > MAX_FILE_SIZE
    raise ArgumentError, "Invalid file format" unless valid_file_format?(params[:file])
  end
  
  def process_file_upload(params)
    # File processing logic
    file = params[:file]
    processed = {
      original_name: file.original_filename,
      size: file.size,
      content_type: file.content_type,
      temp_path: file.tempfile.path
    }
    
    processed[:content] = extract_text_content(file) if text_extractable?(file)
    processed
  end
  
  def update_file_attributes(processed_file)
    self.file_name = processed_file[:original_name]
    self.file_size = processed_file[:size]
    self.file_format = File.extname(processed_file[:original_name]).downcase[1..-1]
    self.content = processed_file[:content] if processed_file[:content]
    save!
  end
  
  def create_document_version(processed_file)
    document_versions.create!(
      version_number: next_version_number,
      file_name: processed_file[:original_name],
      file_size: processed_file[:size],
      uploaded_by: user,
      upload_notes: "File upload"
    )
  end
  
  def valid_file_format?(file)
    extension = File.extname(file.original_filename).downcase[1..-1]
    ALLOWED_FORMATS.include?(extension)
  end
  
  def text_extractable?(file)
    %w[pdf txt doc docx].include?(file_format)
  end
  
  def extract_text_content(file)
    # Text extraction logic would go here
    "Extracted content placeholder"
  end
  
  def cloud_storage_enabled?
    Rails.application.config.cloud_storage_enabled
  end
  
  def cleanup_temp_files
    # Cleanup logic
  end
  
  def next_version_number
    document_versions.maximum(:version_number).to_i + 1
  end
  
  def validate_file_content
    # Custom validation logic
  end
end 