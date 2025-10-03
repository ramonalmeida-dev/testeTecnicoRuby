class Activity < ApplicationRecord
  include Filterable
  
  belongs_to :user, optional: true

  KIND_OPTIONS = [
    ['Melhoria', 1],
    ['Bug', 2],
    ['Spike', 3],
    ['Documentação', 4],
    ['Reunião', 5]
  ].freeze

  URGENCY_OPTIONS = [
    ['Alto', 1],
    ['Médio', 2],
    ['Baixo', 3]
  ].freeze

  def kind_value
    { 1 => "Melhoria", 2 => "Bug", 3 => "Spike", 4 => "Documentação", 5 => "Reunião" }[self.kind]
  end

  def urgency_value
    { 1 => "Alto", 2 => "Médio", 3 => "Baixo" }[self.urgency]
  end

  def status_label
    status? ? 'Ativo' : 'Inativo'
  end

  def user_name
    user&.name || 'Não atribuído'
  end
end
