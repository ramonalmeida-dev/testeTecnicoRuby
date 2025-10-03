# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Criar usuários de teste
users = [
  { name: "Alexandre Augusto Berns Simao" },
  { name: "Maria Silva" },
  { name: "João Santos" },
  { name: "Ana Costa" }
]

users.each do |user_data|
  User.find_or_create_by(name: user_data[:name])
end

puts "Criados #{User.count} usuários"

# Criar atividades de teste
user_ids = User.pluck(:id)

activities = [
  {
    title: "Teste 1",
    description: "Primeira atividade de teste",
    status: true,
    start_date: Date.parse("2025-07-16"),
    end_date: Date.parse("2025-07-30"),
    kind: 1, # Melhoria
    completed_percent: 75.0,
    priority: 1,
    urgency: 1, # Alto
    points: 8,
    user_id: user_ids.sample
  },
  {
    title: "Teste 2", 
    description: "Segunda atividade de teste",
    status: false,
    start_date: Date.parse("2025-07-30"),
    end_date: Date.parse("2025-08-15"),
    kind: 2, # Bug
    completed_percent: 30.0,
    priority: 3,
    urgency: 2, # Médio
    points: 5,
    user_id: user_ids.sample
  },
  {
    title: "Teste 23",
    description: "Terceira atividade de teste",
    status: true,
    start_date: Date.parse("2025-08-01"),
    end_date: Date.parse("2025-08-20"),
    kind: 3, # Spike
    completed_percent: 90.0,
    priority: 2,
    urgency: 3, # Baixo
    points: 3,
    user_id: user_ids.sample
  },
  {
    title: "Documentação API",
    description: "Criar documentação completa da API",
    status: true,
    start_date: Date.parse("2025-08-05"),
    end_date: Date.parse("2025-08-25"),
    kind: 4, # Documentação
    completed_percent: 60.0,
    priority: 2,
    urgency: 2, # Médio
    points: 13,
    user_id: user_ids.sample
  },
  {
    title: "Reunião Sprint Review",
    description: "Reunião de revisão da sprint",
    status: false,
    start_date: Date.parse("2025-08-10"),
    end_date: Date.parse("2025-08-10"),
    kind: 5, # Reunião
    completed_percent: 0.0,
    priority: 1,
    urgency: 1, # Alto
    points: 2,
    user_id: user_ids.sample
  }
]

activities.each do |activity_data|
  Activity.find_or_create_by(title: activity_data[:title]) do |activity|
    activity.assign_attributes(activity_data)
  end
end

puts "Criadas #{Activity.count} atividades"
puts "Seeds executadas com sucesso!"
