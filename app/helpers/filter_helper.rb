module FilterHelper
  def filter_field_options(model_class = Activity)
    model_class.field_options_for_filter
  end

  def filter_operator_options(field, model_class = Activity)
    model_class.operator_options_for_field(field)
  end

  def filter_value_options(field, model_class = Activity)
    model_class.value_options_for_field(field)
  end

  def filter_field_type(field, model_class = Activity)
    model_class.field_type(field)
  end

  def render_filter_value_input(field, value = nil, options = {})
    field_type = filter_field_type(field)
    input_options = {
      class: "form-control filter-value-input",
      data: { field: field, type: field_type }
    }.merge(options)

    case field_type
    when :boolean
      select_tag(
        "filter_value",
        options_for_select(filter_value_options(field), value),
        input_options.merge(include_blank: "Selecione...")
      )
    when :date, :datetime
      date_field_tag("filter_value", value, input_options)
    when :integer, :float
      number_field_tag("filter_value", value, input_options)
    else
      # Para campos com opções predefinidas (kind, urgency, user_id)
      value_options = filter_value_options(field)
      if value_options.any?
        select_tag(
          "filter_value",
          options_for_select(value_options, value),
          input_options.merge(include_blank: "Selecione...")
        )
      else
        text_field_tag("filter_value", value, input_options)
      end
    end
  end

  def filter_operator_label(operator)
    ActivityFilters::ActivityFilterService.operator_label(operator)
  end

  def filter_field_label(field)
    ActivityFilters::ActivityFilterService.field_label(field)
  end

  def group_operator_options
    [
      ['E (AND)', 'AND'],
      ['OU (OR)', 'OR']
    ]
  end

  def filter_operator_options_for_groups
    [
      ['E (AND)', 'AND'],
      ['OU (OR)', 'OR']
    ]
  end

  def max_groups
    4
  end

  def max_filters_per_group
    4
  end

  def can_add_group?(current_groups_count)
    current_groups_count < max_groups
  end

  def can_add_filter?(current_filters_count)
    current_filters_count < max_filters_per_group
  end

  def filter_summary(filter_params)
    return "Nenhum filtro aplicado" if filter_params.blank? || filter_params[:groups].blank?

    groups = filter_params[:groups]
    group_operator = filter_params[:group_operator] || 'AND'
    
    summary_parts = groups.map.with_index do |group, index|
      filters_summary = group[:filters].map do |filter|
        field_label = filter_field_label(filter[:field])
        operator_label = filter_operator_label(filter[:operator])
        value = filter[:value]
        
        "#{field_label} #{operator_label} #{value}"
      end.join(" #{group[:operator] || 'AND'} ")
      
      "(#{filters_summary})"
    end

    summary_parts.join(" #{group_operator} ")
  end

  def filter_params_to_json(filter_params)
    filter_params.to_json.html_safe
  end

  def empty_filter_structure
    {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: '',
              operator: '',
              value: '',
              operator_with_previous: 'AND'
            }
          ]
        }
      ],
      group_operator: 'AND'
    }.to_json.html_safe
  end
end 