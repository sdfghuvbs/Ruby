# frozen_string_literal: true

module AtomicOutbox
  class Dispatcher
    MAX_RETRIES = 5

    def self.run
      (OutboxRecord.pending.limit(100) + OutboxRecord.ready_for_retry.limit(50)).each do |event|
        process_event(event)
      end
    end

    def self.process_event(record)
      record.mark_as_processing

      begin
        if AtomicOutbox.queue_system.respond_to?(:publish)
          AtomicOutbox.queue_system.publish(record.event_type, record.payload)
        else
          puts "--- DISPATCHED: #{record.event_type} --- Payload: #{record.payload}"
        end

        record.mark_as_completed

      rescue StandardError => e
        record.mark_as_failed
        puts "ERROR Dispatching #{record.id}: #{e.message}. Retries: #{record.retries}"
      end
    end
  end
end