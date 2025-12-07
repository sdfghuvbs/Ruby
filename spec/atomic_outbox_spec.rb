# spec/atomic_outbox_spec.rb

require 'spec_helper'
require 'atomic_outbox'
require 'rspec'

# Конфігурація тестової бази даних
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

# Створення тестової таблиці
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

RSpec.describe AtomicOutbox::EventPublisher do
  let(:publisher) { Class.new { include AtomicOutbox::EventPublisher }.new }

  # Перевірка атомарності
  it 'raises an error if called outside a transaction' do
    expect { publisher.publish_event('TestEvent', { data: 1 }) }.to raise_error(
                                                                      AtomicOutbox::Error, /must be inside an ActiveRecord transaction/
                                                                    )
    expect(AtomicOutbox::OutboxRecord.count).to eq(0)
  end

  it 'creates an OutboxRecord inside a transaction' do
    ActiveRecord::Base.transaction do
      publisher.publish_event('UserCreated', { user_id: 42 })
    end

    record = AtomicOutbox::OutboxRecord.last
    expect(record.event_type).to eq('UserCreated')
    expect(record.status).to eq('pending')
    expect(record.retries).to eq(0)
    expect(record.payload).to include("user_id\":42")
  end
end

RSpec.describe AtomicOutbox::Dispatcher do
  let!(:pending_event) { AtomicOutbox::OutboxRecord.create!(event_type: 'Order', payload: '{}', status: 'pending', retries: 0) }

  it 'marks an event as completed after dispatch' do
    # Мок-об'єкт для імітації системи черг
    AtomicOutbox.configure do |config|
      config.queue_system = double('QueueSystem', publish: true)
    end

    AtomicOutbox::Dispatcher.run
    pending_event.reload

    expect(pending_event.status).to eq('completed')
    expect(pending_event.processed_at).to_not be_nil
  end

  it 'marks an event as failed and increments retries on dispatch error' do
    # Імітую помилку від системи черг
    AtomicOutbox.configure do |config|
      allow(config.queue_system).to receive(:publish).and_raise("Connection Error")
    end

    AtomicOutbox::Dispatcher.run
    pending_event.reload

    expect(pending_event.status).to eq('failed')
    expect(pending_event.retries).to eq(1)
  end
end