class Export < ApplicationRecord
  class UnknownExportTypeError < StandardError; end

  belongs_to :snap_application
  validates :status, inclusion: { in: %i(new queued in_process succeeded failed
                                         unnecessary) }
  validates :destination, inclusion: { in: %i(fax email) }

  attribute :destination, :symbol
  attribute :status, :symbol

  default_scope { order(updated_at: :desc) }
  scope :faxed, -> { where(destination: :fax) }
  scope :emailed, -> { where(destination: :email) }
  scope :succeeded, -> { where(status: :succeeded) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :application_ids, -> { pluck(:snap_application_id) }
  scope :latest, -> { first }

  def self.enqueue_faxes
    SnapApplication.faxable.find_each do |snap_application|
      create_and_enqueue(destination: :fax, snap_application: snap_application)
    end
  end

  def self.create_and_enqueue(params)
    create(params).enqueue
  end

  def self.create_and_enqueue!(params)
    create!(params).enqueue
  end

  # Queues up the export job for the given destination
  def enqueue
    transaction do
      save!
      case destination
      when :fax
        FaxApplicationJob.perform_later(export_id: id)
      when :email
        EmailApplicationJob.perform_later(export_id: id)
      else
        raise UnknownExportTypeError, destination
      end
      transition_to(new_status: :queued)
    end
  end

  def execute
    raise ArgumentError, "#export requires a block" unless block_given?
    transition_to new_status: :in_process
    update(metadata: yield(snap_application), completed_at: Time.zone.now)
    transition_to new_status: :succeeded
  rescue => e
    update(metadata: "#{e.class} - #{e.message} #{e.backtrace.join("\n")}",
           completed_at: Time.zone.now)
    transition_to new_status: :failed
    raise e
  ensure
    snap_application.pdf.try(:close)
    snap_application.pdf.try(:unlink)
  end

  def transition_to(new_status:)
    update!(status: new_status)
  end

  def succeeded?
    status == :succeeded
  end
end