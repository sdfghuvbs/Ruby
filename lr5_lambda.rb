sum3 = ->(a, b, c) { a + b + c }

def curry3(proc_or_lambda)
  unless proc_or_lambda.arity == 3
    raise ArgumentError, "curry3 підтримує лише функції з арністю 3."
  end

  curried_fn = ->(params) do
    ->(*new_args) do
      combined_args = params + new_args

      case combined_args.size
      when 0...3
        curried_fn.call(combined_args)
      when 3
        proc_or_lambda.call(*combined_args)
      else
        raise ArgumentError, "wrong number of arguments (given #{combined_args.size}, expected 3)"
      end
    end
  end

  curried_fn.call([])
end

puts "--- 1. Тестування curry3 з sum3 (сума) ---"

cur = curry3(sum3)

# Тест 1: Послідовне часткове застосування
result_1 = cur.call(1).call(2).call(3)
puts "cur.call(1).call(2).call(3)  => #{result_1} (Очікується: 6)" # => 6

# Тест 2: Застосування пачками (1, 2)
result_2 = cur.call(1, 2).call(3)
puts "cur.call(1, 2).call(3)      => #{result_2} (Очікується: 6)" # => 6

# Тест 3: Застосування пачками (1) та (2, 3)
result_3 = cur.call(1).call(2, 3)
puts "cur.call(1).call(2, 3)      => #{result_3} (Очікується: 6)" # => 6

# Тест 4: Виклик з нульовою кількістю аргументів
result_4 = cur.call()
puts "cur.call()                  => #{result_4.class} (Очікується: Proc/Lambda)" # => Proc

# Тест 5: Повний виклик
result_5 = cur.call(1, 2, 3)
puts "cur.call(1, 2, 3)           => #{result_5} (Очікується: 6)" # => 6

# Тест 6: Перевірка помилки (забагато аргументів)
begin
  cur.call(1, 2, 3, 4)
rescue ArgumentError => e
  puts "cur.call(1, 2, 3, 4)        => Помилка: #{e.message}" # => ArgumentError
end

puts "\n--- 2. Тестування curry3 з іншою функцією (конкатенація) ---"

f = ->(a, b, c) { "#{a}-#{b}-#{c}" }
cF = curry3(f)

result_f = cF.call('A').call('B', 'C')
puts "cF.call('A').call('B', 'C') => \"#{result_f}\" (Очікується: \"A-B-C\")" # => "A-B-C"