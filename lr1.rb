def word_stats(text)
  words = text.split(/\s+/)

  total_words = words.length
  longest_word = words.max_by(&:length)
  unique_words = words.map(&:downcase).uniq.count

  return total_words, longest_word, unique_words
end

print "Введіть текст: "
input_text = gets.chomp

total, longest, unique = word_stats(input_text)

puts "Кількість слів: #{total}"
puts "Найдовше слово: #{longest}"
puts "Унікальних слів (без урахування регістру): #{unique}"
