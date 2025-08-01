class Document < ApplicationRecord
  belongs_to :user
  belongs_to :case, optional: true
  
  validates :title, presence: true
  validates :file_type, inclusion: { in: %w[pdf doc docx txt] }
  
  scope :by_type, ->(type) { where(file_type: type) }
  scope :recent, -> { where('created_at > ?', 30.days.ago) }
  
  def process_document
    DocumentProcessor.perform_async(id)
  end
  
  def file_size_mb
    (file_size || 0) / 1.megabyte.to_f
  end
end 