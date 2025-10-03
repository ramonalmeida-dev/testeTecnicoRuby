require 'test_helper'

class FilterableTest < ActiveSupport::TestCase
  test "Activity should include Filterable" do
    assert Activity.included_modules.include?(Filterable)
  end

  test "should respond to filterable methods" do
    assert Activity.respond_to?(:filtered)
    assert Activity.respond_to?(:filterable_fields)
    assert Activity.respond_to?(:field_options_for_filter)
    assert Activity.respond_to?(:operator_options_for_field)
    assert Activity.respond_to?(:value_options_for_field)
    assert Activity.respond_to?(:field_type)
  end

  test "should apply filters using scope" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'kind',
              operator: 'equals',
              value: 2,
              operator_with_previous: 'AND'
            }
          ]
        }
      ]
    }

    result = Activity.filtered(filter_params)
    
    assert result.count > 0
    assert result.all? { |activity| activity.kind == 2 }
  end

  test "should return all records when filter params is blank" do
    result = Activity.filtered({})
    assert_equal Activity.count, result.count

    result = Activity.filtered(nil)
    assert_equal Activity.count, result.count
  end

  test "should delegate to ActivityFilterService" do
    # Verificar se o service correto é chamado através de teste funcional
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'kind',
              operator: 'equals',
              value: 2,
              operator_with_previous: 'AND'
            }
          ]
        }
      ]
    }
    
    # Testar se o resultado é o mesmo que chamar o service diretamente
    direct_result = ActivityFilters::ActivityFilterService.call(filter_params)
    filtered_result = Activity.filtered(filter_params)
    
    assert_equal direct_result.count, filtered_result.count
    assert_equal direct_result.pluck(:id).sort, filtered_result.pluck(:id).sort
  end

  test "should return field options for filter" do
    options = Activity.field_options_for_filter
    
    assert options.is_a?(Array)
    assert options.size > 0
    assert options.all? { |option| option.is_a?(Array) && option.size == 2 }
  end

  test "should return operator options for field" do
    options = Activity.operator_options_for_field('title')
    
    assert options.is_a?(Array)
    assert options.size > 0
  end

  test "should return value options for field" do
    # Field with options
    kind_options = Activity.value_options_for_field('kind')
    assert kind_options.size > 0
    
    # Field without options
    title_options = Activity.value_options_for_field('title')
    assert_equal [], title_options
  end

  test "should return field type" do
    assert_equal :integer, Activity.field_type('kind')
    assert_equal :string, Activity.field_type('title')
    assert_equal :boolean, Activity.field_type('status')
  end

  test "instance should respond to filterable methods" do
    activity = activities(:melhoria_ativa)
    
    assert activity.respond_to?(:filterable?)
    assert activity.respond_to?(:matches_filter?)
  end

  test "instance should be filterable" do
    activity = activities(:melhoria_ativa)
    assert activity.filterable?
  end

  test "instance should match filter" do
    activity = activities(:melhoria_ativa)
    
    # Filter que deve fazer match
    matching_filter = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'kind',
              operator: 'equals',
              value: 1,  # Melhoria
              operator_with_previous: 'AND'
            }
          ]
        }
      ]
    }
    
    assert activity.matches_filter?(matching_filter)
    
    # Filter que não deve fazer match
    non_matching_filter = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'kind',
              operator: 'equals',
              value: 2,  # Bug
              operator_with_previous: 'AND'
            }
          ]
        }
      ]
    }
    
    assert_not activity.matches_filter?(non_matching_filter)
  end

  test "instance should match blank filter" do
    activity = activities(:melhoria_ativa)
    
    assert activity.matches_filter?({})
    assert activity.matches_filter?(nil)
  end
end 