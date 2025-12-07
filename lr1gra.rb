def play_game
  secret = rand(1..100)
  attempts = 0

  puts "Я загадав число від 1 до 100. Спробуйте вгадати!"

  loop do
    print "Ваш варіант: "
    guess = gets.to_i
    attempts += 1

    if guess < secret
      puts "Більше"
    elsif guess > secret
      puts "Менше"
    else
      puts "Вгадано! 🎉"
      puts "Кількість спроб: #{attempts}"
      break
    end
  end
end

play_game
