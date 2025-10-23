class Bag
  include Enumerable

  def initialize
    @items = []
  end

  def add(item)
    @items << item
  end

  def each
    @items.each { |item| yield item }
  end

  def size
    @items.size
  end

  def median
    sorted_items = self.sort
    n = sorted_items.size

    return nil if n.zero?

    if n.odd?
      sorted_items[n / 2]
    else
      (sorted_items[n / 2 - 1] + sorted_items[n / 2]).to_f / 2
    end
  end

  def frequencies
    self.each_with_object(Hash.new(0)) do |item, counts|
      counts[item] += 1
    end
  end
end

puts "--- Приклад використання Bag ---"

my_bag = Bag.new
my_bag.add(10)
my_bag.add(20)
my_bag.add(10)
my_bag.add(30)
my_bag.add(20)
my_bag.add(10)
my_bag.add(40)

puts "Розмір колекції: #{my_bag.size}" # 7

puts "Мінімальне значення (min): #{my_bag.min}" # 10
puts "Елементи > 15 (select): #{my_bag.select { |x| x > 15 }.inspect}" # [20, 30, 20, 40]

puts "Медіана (median): #{my_bag.median}"
# Посортовані: [10, 10, 10, 20, 20, 30, 40] -> Медіана: 20

puts "Частоти (frequencies): #{my_bag.frequencies.inspect}"
# {10=>3, 20=>2, 30=>1, 40=>1}