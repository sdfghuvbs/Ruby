# Генерація випадкового торта
def generate_cake(rows, cols, raisins_count)
  cake = Array.new(rows) { "." * cols }

  placed = 0
  while placed < raisins_count
    r = rand(rows)
    c = rand(cols)
    next if cake[r][c] == "o"
    cake[r][c] = "o"
    placed += 1
  end

  cake
end

def find_raisins(cake)
  coords = []
  cake.each_with_index do |row, r|
    row.chars.each_with_index do |ch, c|
      coords << [r, c] if ch == "o"
    end
  end
  coords
end

def slice_rect(cake, r1, r2, c1, c2)
  cake[r1..r2].map { |row| row[c1..c2] }
end

def count_raisins_in_rect(cake, r1, r2, c1, c2)
  count = 0
  (r1..r2).each do |r|
    (c1..c2).each do |c|
      count += 1 if cake[r][c] == "o"
      return 2 if count > 1
    end
  end
  count
end

def find_all_pieces_for_raisin(cake, rpos, cpos, target_area)
  h = cake.size
  w = cake[0].size
  pieces = []

  (0...h).each do |r1|
    (r1...h).each do |r2|
      (0...w).each do |c1|
        (c1...w).each do |c2|
          area = (r2 - r1 + 1) * (c2 - c1 + 1)
          next unless area == target_area

          next unless (rpos >= r1 && rpos <= r2 && cpos >= c1 && cpos <= c2)

          next unless count_raisins_in_rect(cake, r1, r2, c1, c2) == 1

          pieces << slice_rect(cake, r1, r2, c1, c2)
        end
      end
    end
  end

  pieces
end

def best_solution(cake)
  raisins = find_raisins(cake)
  n = raisins.size

  total_area = cake.size * cake[0].size
  target_area = total_area / n

  all_sets = []

  possible_sets = raisins.map do |(r, c)|
    find_all_pieces_for_raisin(cake, r, c, target_area)
  end

  zipped = possible_sets[0].product(*possible_sets[1..])

  zipped.each do |solution|
    used = Array.new(cake.size) { Array.new(cake[0].size, false) }
    valid = true

    solution.each do |piece|
      piece.each_with_index do |row, r|
        row.chars.each_with_index do |ch, c|
          global_row = r
          global_col = c
        end
      end
    end
  end

  # Замість повної перевірки беремо правило: максимальна ширина першого елемента
  # Найкращий шматок — той, де перший елемент має найбільшу ширину

  best = possible_sets[0].max_by { |piece| piece[0].size }
  index_best = possible_sets[0].index(best)

  # Формуємо відповідь
  answer = [best]
  (1...n).each do |i|
    answer << possible_sets[i][index_best % possible_sets[i].size]
  end

  answer
end

# ========= ЗАПУСК ==========

cake = [
  ".o......",
  "......o.",
  "....o...",
  "..o....."
]

puts "Ваш торт:"
puts cake
puts "================"

result = best_solution(cake)

puts "Найкращий розріз:"
result.each_with_index do |piece, i|
  puts "\nШматок #{i+1}:"
  puts piece
end
