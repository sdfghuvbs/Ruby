require 'bigdecimal'
module UnitConverter
  CONVERSION_FACTORS = {
    # Маса (базова одиниця: г)
    'kg' => { 'g' => 1000, 'kg' => 1 },
    'g' => { 'g' => 1, 'kg' => 0.001 },
    # Об'єм (базова одиниця: мл)
    'l' => { 'ml' => 1000, 'l' => 1 },
    'ml' => { 'ml' => 1, 'l' => 0.001 },
    # Штуки (базова одиниця: шт)
    'pcs' => { 'pcs' => 1 }
  }.freeze

  def self.base_unit(unit)
    unit = unit.to_s.downcase
    return 'g' if %w[g kg].include?(unit)
    return 'ml' if %w[ml l].include?(unit)
    return 'pcs' if unit == 'pcs'

    raise ArgumentError, "Невідома одиниця виміру: #{unit}"
  end

  def self.convert(quantity, from_unit, to_unit)
    from_unit = from_unit.to_s.downcase
    to_unit = to_unit.to_s.downcase

    if base_unit(from_unit) != base_unit(to_unit)
      raise ArgumentError, "Конвертація між #{from_unit} та #{to_unit} заборонена."
    end

    return quantity if from_unit == to_unit

    factors = CONVERSION_FACTORS[from_unit]

    if factors && factors[to_unit]
      return quantity * factors[to_unit]
    else
      base = base_unit(from_unit)
      qty_in_base = quantity * CONVERSION_FACTORS[from_unit][base]
      return qty_in_base / CONVERSION_FACTORS[to_unit][base]
    end
  end

  def self.to_base(quantity, unit)
    convert(quantity, unit, base_unit(unit))
  end
end

class Ingredient
  attr_reader :name, :unit, :calories_per_unit

  def initialize(name, unit, calories_per_unit)
    @name = name.to_s
    @unit = unit.to_sym
    @calories_per_unit = BigDecimal(calories_per_unit.to_s)
  end
end

class Pantry
  def initialize
    @stock = {} # { 'борошно' => { qty_base: 1000, unit: :g } }
  end

  def add(name, qty, unit)
    name = name.to_s
    base_unit = UnitConverter.base_unit(unit)
    qty_base = UnitConverter.to_base(qty, unit)

    if @stock[name]
      @stock[name][:qty_base] += qty_base
    else
      @stock[name] = { qty_base: qty_base, unit: base_unit.to_sym }
    end
  end

  def available_for(name)
    @stock.dig(name.to_s, :qty_base) || 0
  end

  def stock
    @stock
  end
end

class Recipe
  attr_reader :name, :steps, :items

  def initialize(name, steps, items)
    @name = name.to_s
    @steps = steps # Масив рядків
    @items = items # [{ ingredient: Ingredient, qty: Number, unit: Symbol }]
  end

  def need
    needed = Hash.new(0)
    @items.each do |item|
      ingredient_name = item[:ingredient].name
      qty_base = UnitConverter.to_base(item[:qty], item[:unit])
      needed[ingredient_name] += qty_base
    end
    needed
  end

  def total_calories
    total = BigDecimal('0')
    @items.each do |item|
      ingredient = item[:ingredient]
      qty_base = UnitConverter.to_base(item[:qty], item[:unit])
      total += qty_base * ingredient.calories_per_unit
    end
    total.round(2)
  end
end

class Planner
  # price_list: { 'ingredient_name' => price_per_base_unit }
  # ingredient_map: { 'ingredient_name' => Ingredient_object }
  def self.plan(recipes, pantry, price_list, ingredient_map)
    total_need = Hash.new(0)
    total_calories = BigDecimal('0')

    recipes.each do |recipe|
      recipe.need.each do |name, qty_base|
        total_need[name] += qty_base
      end
      total_calories += recipe.total_calories
    end

    current_cost = BigDecimal('0')
    report_ingredients = {}

    total_need.each do |name, need_qty|
      have_qty = pantry.available_for(name)
      deficit_qty = [BigDecimal('0'), need_qty - have_qty].max

      price = BigDecimal(price_list[name.to_s].to_s) || BigDecimal('0')
      cost = deficit_qty * price
      current_cost += cost

      ingredient_obj = ingredient_map[name]
      unless ingredient_obj
        raise ArgumentError, "Інгредієнт '#{name}' не знайдено в INGREDIENT_MAP."
      end
      base_unit = ingredient_obj.unit

      report_ingredients[name] = {
        unit: base_unit.to_sym,
        need: need_qty.to_f,
        have: have_qty.to_f,
        deficit: deficit_qty.to_f,
        cost_deficit: cost.to_f
      }
    end

    {
      ingredients: report_ingredients,
      total_calories: total_calories.to_f.round(2),
      total_cost: current_cost.to_f.round(2)
    }
  end
end

ING_EGG = Ingredient.new('яйця', :pcs, 72.0)
ING_MILK = Ingredient.new('молоко', :ml, 0.06)
ING_FLOUR = Ingredient.new('борошно', :g, 3.64)
ING_PASTA = Ingredient.new('паста', :g, 3.5)
ING_SAUCE = Ingredient.new('соус', :ml, 0.2)
ING_CHEESE = Ingredient.new('сир', :g, 4.0)

INGREDIENT_MAP = {
  'яйця' => ING_EGG, 'молоко' => ING_MILK, 'борошно' => ING_FLOUR,
  'паста' => ING_PASTA, 'соус' => ING_SAUCE, 'сир' => ING_CHEESE
}.freeze

pantry = Pantry.new

pantry.add('борошно', 1, :kg)
pantry.add('молоко', 0.5, :l)
pantry.add('яйця', 6, :pcs)
pantry.add('паста', 300, :g)
pantry.add('сир', 150, :g)

omelette = Recipe.new(
  'Омлет',
  ['Змішати інгредієнти', 'Смажити'],
  [
    { ingredient: ING_EGG, qty: 3, unit: :pcs },
    { ingredient: ING_MILK, qty: 100, unit: :ml },
    { ingredient: ING_FLOUR, qty: 20, unit: :g }
  ]
)

pasta = Recipe.new(
  'Паста',
  ['Відварити пасту', 'Підігріти соус', 'Посипати сиром'],
  [
    { ingredient: ING_PASTA, qty: 200, unit: :g },
    { ingredient: ING_SAUCE, qty: 150, unit: :ml },
    { ingredient: ING_CHEESE, qty: 50, unit: :g }
  ]
)

recipes = [omelette, pasta]

PRICE_LIST = {
  'борошно' => 0.02,
  'молоко' => 0.015,
  'яйця' => 6.0,
  'паста' => 0.03,
  'соус' => 0.025,
  'сир' => 0.08
}.freeze

report = Planner.plan(recipes, pantry, PRICE_LIST, INGREDIENT_MAP)

puts "=========================================================="
puts "                RecipeCraft Planner"
puts "=========================================================="

puts "Загальна Калорійність Рецептів: #{report[:total_calories]} ккал"
puts "Загальна Вартість Дефіциту:     #{report[:total_cost]} грн"
puts "----------------------------------------------------------"
puts "Інгредієнт | Потрібно | Є | Дефіцит | Ціна дефіциту (грн)"
puts "----------------------------------------------------------"

report[:ingredients].each do |name, data|
  unit = data[:unit]
  line = format(
    "%-10s | %8.1f %-3s| %7.1f %-3s| %7.1f %-3s| %15.2f",
    name.capitalize,
    data[:need], unit,
    data[:have], unit,
    data[:deficit], unit,
    data[:cost_deficit]
  )
  puts line
end
puts "=========================================================="