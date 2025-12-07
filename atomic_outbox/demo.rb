# demo.rb
# 1. Завантаження гема з локальної директорії
$LOAD_PATH.unshift(File.expand_path("lib", __dir__))
require "atomic_outbox"

require "logger"
require "sqlite3"
require "active_record"

# 2. Налаштування бази даних SQLite
ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "outbox_demo.sqlite3")

unless ActiveRecord::Base.connection.table_exists?(:outbox_events)
  ActiveRecord::Schema.define do
    create_table :outbox_events, force: true do |t|
      t.string :event_type
      t.text :payload
      t.string :status
      t.integer :retries
      t.datetime :processed_at
      t.timestamps
    end
  end

  puts "INFO: Created table outbox_events"
end

# 3. Мок для системи черг
class MockQueue
  def publish(type, payload)
    if type == "FaultyEvent" && rand < 0.5
      raise "Simulated network failure!"
    end

    puts "QUEUE: Published event #{type}"
    true
  end
end

AtomicOutbox.configure do |config|
  config.queue_system = MockQueue.new
end

# 4. Бізнес-логіка з EventPublisher
class OrderService
  include AtomicOutbox::EventPublisher

  def place_order(order_data)
    puts "\n=== Starting transaction for Order #{order_data[:id]} ==="

    ActiveRecord::Base.transaction do
      puts "Saving order #{order_data[:id]}..."

      publish_event("OrderPlaced", order_data)
      puts "Outbox: OrderPlaced added."

      publish_event("FaultyEvent", order_data)
      puts "Outbox: FaultyEvent added."
    end

    puts "=== Transaction OK ==="
  rescue => e
    puts "!!! ERROR: Transaction failed: #{e.message}"
  end
end

# 5. ДЕМОНСТРАЦІЯ
service = OrderService.new
service.place_order(id: 101, amount: 500)
service.place_order(id: 102, amount: 350)

# 6. Стан Outbox перед диспетчером
puts "\n--- BEFORE DISPATCHER ---"
AtomicOutbox::OutboxRecord.all.each do |r|
  puts "ID: #{r.id}, Type: #{r.event_type}, Status: #{r.status}, Retries: #{r.retries}"
end

# 7. Запуск Dispatcher
puts "\n--- DISPATCHER RUN ---"
AtomicOutbox::Dispatcher.run

# 8. Стан Outbox після диспетчера
puts "\n--- AFTER DISPATCHER ---"
AtomicOutbox::OutboxRecord.all.each do |r|
  puts "ID: #{r.id}, Type: #{r.event_type}, Status: #{r.status}, Retries: #{r.retries}"
end

puts "\n*** Demo finished. Run dispatcher again to retry failed events. ***"
