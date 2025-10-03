class ActivityFilters::BaseFilterService
  attr_reader :model_class, :filter_params

  # @param model_class [Class] A classe do modelo ActiveRecord a ser filtrada
  # @param filter_params [Hash] Parâmetros de filtro contendo grupos e operadores
  def initialize(model_class, filter_params = {})
    @model_class = model_class
    @filter_params = filter_params || {}
  end

  # Método de conveniência para criar e executar o service
  # @param model_class [Class] A classe do modelo ActiveRecord a ser filtrada
  # @param filter_params [Hash] Parâmetros de filtro contendo grupos e operadores
  # @return [ActiveRecord::Relation] Query filtrada
  def self.call(model_class, filter_params = {})
    new(model_class, filter_params).call
  end

  # Executa os filtros e retorna a query filtrada
  # @return [ActiveRecord::Relation] Query filtrada com todas as condições aplicadas
  def call
    return model_class.all if filter_params.blank? || filter_params[:groups].blank?

    query = model_class.all
    groups = filter_params[:groups] || []
    group_operator = filter_params[:group_operator] || 'AND'

    return query if groups.empty?
    
    # Validar limites se definidos na classe filha
    validate_limits(groups) if respond_to?(:validate_limits, true)

    # Processar todos os grupos
    if groups.size == 1
      # Se há apenas um grupo, aplicar diretamente
      query = apply_group_filters(query, groups.first)
    else
      # Se há múltiplos grupos, usar OR entre eles
      group_conditions = []
      
      groups.each do |group|
        group_query = model_class.all
        group_query = apply_group_filters(group_query, group)
        
        # Extrair as condições WHERE do grupo
        if group_query.where_clause.any?
          group_conditions << group_query.where_clause.ast
        end
      end
      
      if group_conditions.any?
        if group_operator.upcase == 'OR'
          # Combinar grupos com OR
          combined_condition = group_conditions.reduce do |combined, condition|
            combined.or(condition)
          end
          query = query.where(combined_condition)
        else
          # Combinar grupos com AND (aplicar todos)
          group_conditions.each do |condition|
            query = query.where(condition)
          end
        end
      end
    end
    
    query
  end

  private

  def apply_group_filters(query, group)
    filters = group[:filters] || []
    return query if filters.empty?

    # Para um grupo simples, aplicar todos os filtros como AND
    filters.each do |filter|
      condition = build_filter_condition_hash(filter)
      next if condition.blank?

      if condition.is_a?(Array)
        # SQL com parâmetros: ["field LIKE ?", "%value%"]
        query = query.where(condition[0], condition[1])
      elsif condition.is_a?(Hash)
        # Hash simples: { field: value }
        query = query.where(condition)
      end
    end

    query
  end

  def build_group_conditions_hash(group)
    filters = group[:filters] || []
    return {} if filters.empty?

    # Por enquanto, apenas AND entre filtros do mesmo grupo
    # Para múltiplos grupos com OR, vamos usar apenas filtros simples (hash)
    conditions = {}
    filters.each do |filter|
      condition = build_filter_condition_hash(filter)
      if condition.is_a?(Hash)
        conditions.merge!(condition)
      end
      # Ignorar condições SQL complexas para OR entre grupos por enquanto
    end

    conditions
  end

  def build_filter_condition_hash(filter)
    field = filter[:field]
    operator = filter[:operator]
    value = filter[:value]

    return {} if field.blank? || operator.blank? || value.blank?

    case operator.downcase
    when 'equals', 'equal'
      { field => value }
    when 'contains', 'like'
      ["#{field} LIKE ?", "%#{value}%"]
    when 'icontains', 'ilike'
      # SQLite não suporta ILIKE, usar LOWER() para case insensitive
      if ActiveRecord::Base.connection.adapter_name.downcase.include?('sqlite')
        ["LOWER(#{field}) LIKE LOWER(?)", "%#{value}%"]
      else
        ["#{field} ILIKE ?", "%#{value}%"]
      end
    when 'starts_with'
      ["#{field} LIKE ?", "#{value}%"]
    when 'ends_with'
      ["#{field} LIKE ?", "%#{value}"]
    when 'greater_than', 'gt'
      ["#{field} > ?", value]
    when 'less_than', 'lt'
      ["#{field} < ?", value]
    when 'greater_than_or_equal', 'gte'
      ["#{field} >= ?", value]
    when 'less_than_or_equal', 'lte'
      ["#{field} <= ?", value]
    when 'not_equal', 'ne'
      ["#{field} != ?", value]
    else
      {}
    end
  end

  def build_group_condition(group)
    # Método legado mantido para compatibilidade
    filters = group[:filters] || []
    return '' if filters.empty?

    filter_conditions = []
    
    filters.each_with_index do |filter, index|
      condition = build_filter_condition(filter)
      next if condition.blank?

      if index == 0
        filter_conditions << condition
      else
        operator = filter[:operator_with_previous] || 'AND'
        if operator.upcase == 'OR'
          filter_conditions << "OR #{condition}"
        else
          filter_conditions << "AND #{condition}"
        end
      end
    end

    "(#{filter_conditions.join(' ')})"
  end

  def build_filter_condition(filter)
    field = filter[:field]
    operator = filter[:operator]
    value = filter[:value]

    return '' if field.blank? || operator.blank? || value.blank?

    case operator.downcase
    when 'equals', 'equal'
      "#{field} = #{sanitize_value(value, field)}"
    when 'contains', 'like'
      "#{field} LIKE #{sanitize_like_value(value)}"
    when 'icontains', 'ilike'
      # SQLite não suporta ILIKE, usar LOWER() para case insensitive
      if ActiveRecord::Base.connection.adapter_name.downcase.include?('sqlite')
        "LOWER(#{field}) LIKE LOWER(#{sanitize_like_value(value)})"
      else
        "#{field} ILIKE #{sanitize_like_value(value)}"
      end
    when 'starts_with'
      "#{field} LIKE #{sanitize_like_value(value, :starts_with)}"
    when 'ends_with'
      "#{field} LIKE #{sanitize_like_value(value, :ends_with)}"
    when 'greater_than', 'gt'
      "#{field} > #{sanitize_value(value, field)}"
    when 'less_than', 'lt'
      "#{field} < #{sanitize_value(value, field)}"
    when 'greater_than_or_equal', 'gte'
      "#{field} >= #{sanitize_value(value, field)}"
    when 'less_than_or_equal', 'lte'
      "#{field} <= #{sanitize_value(value, field)}"
    when 'between'
      values = value.is_a?(Array) ? value : value.split(',')
      return '' if values.size != 2
      "#{field} BETWEEN #{sanitize_value(values[0], field)} AND #{sanitize_value(values[1], field)}"
    when 'in'
      values = value.is_a?(Array) ? value : value.split(',')
      sanitized_values = values.map { |v| sanitize_value(v.strip, field) }
      "#{field} IN (#{sanitized_values.join(', ')})"
    when 'not_equal', 'ne'
      "#{field} != #{sanitize_value(value, field)}"
    when 'is_null'
      "#{field} IS NULL"
    when 'is_not_null'
      "#{field} IS NOT NULL"
    else
      ''
    end
  end

  def sanitize_value(value, field)
    return 'NULL' if value.nil?
    
    column = get_column_info(field)
    
    case column&.type
    when :string, :text
      "'#{value.to_s.gsub("'", "''")}'"
    when :integer
      value.to_i
    when :float, :decimal
      value.to_f
    when :boolean
      value.to_s.downcase == 'true' ? 'TRUE' : 'FALSE'
    when :date, :datetime, :time
      "'#{value}'"
    else
      "'#{value.to_s.gsub("'", "''")}'"
    end
  end

  def sanitize_like_value(value, position = :contains)
    escaped_value = value.to_s.gsub("'", "''").gsub('%', '\\%').gsub('_', '\\_')
    
    case position
    when :starts_with
      "'#{escaped_value}%'"
    when :ends_with
      "'%#{escaped_value}'"
    else # :contains
      "'%#{escaped_value}%'"
    end
  end

  def get_column_info(field)
    model_class.columns_hash[field.to_s]
  end
end 