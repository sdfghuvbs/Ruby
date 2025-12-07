# frozen_string_literal: true

module AtomicOutbox
  module EventPublisher
    def publish_event(event_type, data)
      unless ActiveRecord::Base.connection.transaction_open?
        raise AtomicOutbox::Error, "Event publishing must be inside an ActiveRecord transaction."
      end

      OutboxRecord.create!(
        event_type: event_type.to_s,
        payload: data.to_json,
        status: 'pending',
        retries: 0
      )
    end

  end
end