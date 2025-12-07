# frozen_string_literal: true

module AtomicOutbox
  class OutboxRecord < ActiveRecord::Base
    self.table_name = 'outbox_events'

    scope :pending, -> { where(status: 'pending') }
    scope :ready_for_retry, -> { where(status: 'failed').where('retries < ?', 5) } # Приклад

    def mark_as_processing
      update!(status: 'processing')
    end

    def mark_as_completed
      update!(status: 'completed', processed_at: Time.current)
    end

    def mark_as_failed
      increment!(:retries)
      update!(status: 'failed')
    end
  end
end