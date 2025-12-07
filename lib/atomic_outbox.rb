# lib/atomic_outbox.rb

require_relative "atomic_outbox/version"
require_relative "atomic_outbox/atomic_outbox"
require_relative "atomic_outbox/dispatcher"
require_relative "atomic_outbox/event_publisher"
require_relative "atomic_outbox/outbox_record"

module AtomicOutbox
  class Error < StandardError; end
end
