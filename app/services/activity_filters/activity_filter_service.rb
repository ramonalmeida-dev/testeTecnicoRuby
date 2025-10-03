# Service específico para filtros de Activity
# 
# Este service herda de BaseFilterService e adiciona configurações específicas
# para o modelo Activity, incluindo campos filtráveis, operadores permitidos
# e opções de valores para campos com dropdown.
#
# @example Uso básico
#   ActivityFilters::ActivityFilterService.call(filter_params)
#
# @example Filtro simples
#   filter_params = {
#     groups: [{
#       operator: 'AND',
#       filters: [{
#         field: 'kind',
#         operator: 'equals', 
#         value: 2
#       }]
#     }]
#   }
class ActivityFilters::ActivityFilterService < ActivityFilters::BaseFilterService
  # Constantes de configuração
  ALLOWED_OPERATORS = %w[equals contains icontains starts_with ends_with greater_than less_than greater_than_or_equal less_than_or_equal not_equal].freeze
  MAX_GROUPS = 4
  MAX_FILTERS_PER_GROUP = 4
  FILTERABLE_FIELDS = {
    'id' => { type: :integer, operators: %w[equals greater_than less_than between] },
    'title' => { type: :string, operators: %w[equals icontains contains starts_with ends_with] },
    'description' => { type: :string, operators: %w[equals icontains contains starts_with ends_with] },
    'status' => { type: :boolean, operators: %w[equals] },
    'start_date' => { type: :date, operators: %w[equals greater_than less_than between] },
    'end_date' => { type: :date, operators: %w[equals greater_than less_than between] },
    'kind' => { type: :integer, operators: %w[equals in] },
    'completed_percent' => { type: :float, operators: %w[equals greater_than less_than between] },
    'priority' => { type: :integer, operators: %w[equals greater_than less_than between] },
    'urgency' => { type: :integer, operators: %w[equals in] },
    'points' => { type: :integer, operators: %w[equals greater_than less_than between] },
    'user_id' => { type: :integer, operators: %w[equals in] },
    'created_at' => { type: :datetime, operators: %w[equals greater_than less_than between] },
    'updated_at' => { type: :datetime, operators: %w[equals greater_than less_than between] }
  }.freeze

  def initialize(filter_params = {})
    super(Activity, filter_params)
  end

  def self.call(filter_params = {})
    new(filter_params).call
  end

  def call
    query = super
    query = apply_joins(query)
    query.includes(:user)
  end

  def self.filterable_fields
    FILTERABLE_FIELDS
  end

  def self.field_options
    Rails.cache.fetch("activity_filter_field_options", expires_in: 1.hour) do
      FILTERABLE_FIELDS.keys.map do |field|
        [field_label(field), field]
      end
    end
  end

  def self.operator_options(field)
    field_config = FILTERABLE_FIELDS[field.to_s]
    return [] unless field_config

    field_config[:operators].map do |operator|
      [operator_label(operator), operator]
    end
  end

  def self.field_label(field)
    case field.to_s
    when 'id' then 'ID'
    when 'title' then 'Título'
    when 'description' then 'Descrição'
    when 'status' then 'Status'
    when 'start_date' then 'Data de Início'
    when 'end_date' then 'Data de Término'
    when 'kind' then 'Tipo'
    when 'completed_percent' then '% Completo'
    when 'priority' then 'Prioridade'
    when 'urgency' then 'Urgência'
    when 'points' then 'Pontos'
    when 'user_id' then 'Responsável'
    when 'created_at' then 'Data de Criação'
    when 'updated_at' then 'Data de Atualização'
    else field.humanize
    end
  end

  def self.operator_label(operator)
    case operator.to_s
    when 'equals' then 'Igual a'
    when 'contains' then 'Contém (sensível a maiúsculas)'
    when 'icontains' then 'Contém'
    when 'starts_with' then 'Começa com'
    when 'ends_with' then 'Termina com'
    when 'greater_than' then 'Maior que'
    when 'less_than' then 'Menor que'
    when 'greater_than_or_equal' then 'Maior ou igual a'
    when 'less_than_or_equal' then 'Menor ou igual a'
    when 'between' then 'Entre'
    when 'in' then 'Em'
    when 'not_equal' then 'Diferente de'
    when 'is_null' then 'É vazio'
    when 'is_not_null' then 'Não é vazio'
    else operator.humanize
    end
  end

  def self.kind_options
    Activity.new.class.const_get(:KIND_OPTIONS) rescue [
      ['Melhoria', 1],
      ['Bug', 2],
      ['Spike', 3],
      ['Documentação', 4],
      ['Reunião', 5]
    ]
  end

  def self.urgency_options
    Activity.new.class.const_get(:URGENCY_OPTIONS) rescue [
      ['Alto', 1],
      ['Médio', 2],
      ['Baixo', 3]
    ]
  end

  def self.user_options
    Rails.cache.fetch("activity_filter_user_options", expires_in: 30.minutes) do
      # Buscar usuários com nomes fictícios (renomeados de User X)
      fictional_users = [
        'Carlos Silva', 'Ana Santos', 'Bruno Costa', 'Fernanda Lima', 
        'Ricardo Oliveira', 'Juliana Pereira', 'Marcos Rodrigues', 
        'Patrícia Alves', 'Leonardo Martins', 'Camila Ferreira'
      ]
      User.where(name: fictional_users).order(:name).map { |user| [user.name, user.id] }
    end
  end

  def self.status_options
    [
      ['Ativo', true],
      ['Inativo', false]
    ]
  end

  def self.value_options_for_field(field)
    case field.to_s
    when 'kind'
      kind_options
    when 'urgency'
      urgency_options
    when 'user_id'
      user_options
    when 'status'
      status_options
    else
      []
    end
  end

  def self.field_type(field)
    FILTERABLE_FIELDS.dig(field.to_s, :type) || :string
  end

  private

  def apply_joins(query)
    # Adiciona joins necessários baseados nos filtros
    fields_in_filters = extract_fields_from_filters
    
    if fields_in_filters.include?('user_id')
      # Usar left_joins para permitir que includes funcione corretamente
      query = query.left_joins(:user)
    end

    query
  end

  def extract_fields_from_filters
    fields = []
    return fields unless filter_params[:groups]

    filter_params[:groups].each do |group|
      next unless group[:filters]
      
      group[:filters].each do |filter|
        fields << filter[:field] if filter[:field]
      end
    end

    fields.uniq
  end

  # Valida limites de grupos e filtros
  # @param groups [Array] Array de grupos de filtros
  # @raise [ActivityFilters::FilterLimitExceededError] Se os limites forem excedidos
  def validate_limits(groups)
    # Validar número de grupos
    if groups.size > MAX_GROUPS
      raise ActivityFilters::FilterLimitExceededError.new(:groups, groups.size, MAX_GROUPS)
    end
    
    # Validar número de filtros por grupo
    groups.each do |group|
      filters = group[:filters] || []
      if filters.size > MAX_FILTERS_PER_GROUP
        raise ActivityFilters::FilterLimitExceededError.new(:filters, filters.size, MAX_FILTERS_PER_GROUP)
      end
    end
  end
end 