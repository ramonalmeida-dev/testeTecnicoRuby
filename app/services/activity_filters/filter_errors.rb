module ActivityFilters
  # Classe base para erros de filtro
  class FilterError < StandardError
    attr_reader :field, :operator, :value

    def initialize(message, field: nil, operator: nil, value: nil)
      super(message)
      @field = field
      @operator = operator
      @value = value
    end
  end

  # Erro para campo inválido
  class InvalidFieldError < FilterError
    def initialize(field, allowed_fields = [])
      message = "Campo '#{field}' não é permitido para filtros."
      message += " Campos permitidos: #{allowed_fields.join(', ')}" if allowed_fields.any?
      super(message, field: field)
    end
  end

  # Erro para operador inválido
  class InvalidOperatorError < FilterError
    def initialize(operator, field = nil, allowed_operators = [])
      message = "Operador '#{operator}' não é válido"
      message += " para o campo '#{field}'" if field
      message += ". Operadores permitidos: #{allowed_operators.join(', ')}" if allowed_operators.any?
      super(message, field: field, operator: operator)
    end
  end

  # Erro para valor inválido
  class InvalidValueError < FilterError
    def initialize(value, field = nil, expected_type = nil)
      message = "Valor '#{value}' não é válido"
      message += " para o campo '#{field}'" if field
      message += ". Tipo esperado: #{expected_type}" if expected_type
      super(message, field: field, value: value)
    end
  end

  # Erro para estrutura de filtro malformada
  class MalformedFilterError < FilterError
    def initialize(details = nil)
      message = "Estrutura de filtro malformada"
      message += ": #{details}" if details
      super(message)
    end
  end

  # Erro para limite excedido
  class FilterLimitExceededError < FilterError
    def initialize(type, current, limit)
      message = case type
                when :groups
                  "Número de grupos (#{current}) excede o limite permitido (#{limit})"
                when :filters
                  "Número de filtros por grupo (#{current}) excede o limite permitido (#{limit})"
                else
                  "Limite excedido: #{current} > #{limit}"
                end
      super(message)
    end
  end
end 