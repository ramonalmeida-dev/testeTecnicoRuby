module Filterable
  extend ActiveSupport::Concern

  included do
    scope :filtered, ->(filter_params) { apply_filters(filter_params) }
  end

  class_methods do
    def apply_filters(filter_params)
      return all if filter_params.blank?

      service_class = "ActivityFilters::#{name}FilterService".constantize
      service_class.call(filter_params)
    rescue NameError
      # Fallback para BaseFilterService se não existir service específico
      ActivityFilters::BaseFilterService.call(self, filter_params)
    end

    def filterable_fields
      service_class = "ActivityFilters::#{name}FilterService".constantize
      service_class.filterable_fields
    rescue NameError
      # Retorna campos básicos baseados nas colunas da tabela
      columns_hash.keys.index_with do |column|
        { type: columns_hash[column].type, operators: default_operators_for_type(columns_hash[column].type) }
      end
    end

    def field_options_for_filter
      service_class = "ActivityFilters::#{name}FilterService".constantize
      service_class.field_options
    rescue NameError
      columns_hash.keys.map { |field| [field.humanize, field] }
    end

    def operator_options_for_field(field)
      service_class = "ActivityFilters::#{name}FilterService".constantize
      service_class.operator_options(field)
    rescue NameError
      column = columns_hash[field.to_s]
      return [] unless column
      
      default_operators_for_type(column.type).map do |operator|
        [operator.humanize, operator]
      end
    end

    def value_options_for_field(field)
      service_class = "ActivityFilters::#{name}FilterService".constantize
      service_class.value_options_for_field(field)
    rescue NameError
      []
    end

    def field_type(field)
      service_class = "ActivityFilters::#{name}FilterService".constantize
      service_class.field_type(field)
    rescue NameError
      column = columns_hash[field.to_s]
      column&.type || :string
    end

    private

    def default_operators_for_type(type)
      case type
      when :string, :text
        %w[equals contains starts_with ends_with]
      when :integer, :float, :decimal
        %w[equals greater_than less_than between]
      when :date, :datetime, :time
        %w[equals greater_than less_than between]
      when :boolean
        %w[equals]
      else
        %w[equals]
      end
    end
  end

  # Métodos de instância
  def filterable?
    self.class.respond_to?(:filterable_fields)
  end

  def matches_filter?(filter_params)
    return true if filter_params.blank?

    # Aplica o filtro e verifica se este registro está nos resultados
    filtered_records = self.class.apply_filters(filter_params)
    filtered_records.exists?(id: self.id)
  end
end 