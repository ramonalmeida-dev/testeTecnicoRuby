require 'test_helper'

class ActivityFilters::BaseFilterServiceTest < ActiveSupport::TestCase
  def setup
    @service = ActivityFilters::BaseFilterService.new(Activity, {})
  end

  test "should return all records when no filter params" do
    result = ActivityFilters::BaseFilterService.call(Activity, {})
    assert_equal Activity.count, result.count
  end

  test "should return all records when filter params is blank" do
    result = ActivityFilters::BaseFilterService.call(Activity, nil)
    assert_equal Activity.count, result.count
  end

  test "should return all records when groups is empty" do
    filter_params = { groups: [] }
    result = ActivityFilters::BaseFilterService.call(Activity, filter_params)
    assert_equal Activity.count, result.count
  end

  test "should filter by single equals condition" do
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
      ],
      group_operator: 'AND'
    }

    result = ActivityFilters::BaseFilterService.call(Activity, filter_params)
    expected_count = Activity.where(kind: 2).count
    
    assert_equal expected_count, result.count
    assert result.all? { |activity| activity.kind == 2 }
  end

  test "should filter by string contains condition" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'title',
              operator: 'contains',
              value: 'Corrigir',
              operator_with_previous: 'AND'
            }
          ]
        }
      ],
      group_operator: 'AND'
    }

    result = ActivityFilters::BaseFilterService.call(Activity, filter_params)
    
    assert result.count > 0
    assert result.all? { |activity| activity.title.include?('Corrigir') }
  end

  test "should filter by boolean status" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'status',
              operator: 'equals',
              value: true,
              operator_with_previous: 'AND'
            }
          ]
        }
      ],
      group_operator: 'AND'
    }

    result = ActivityFilters::BaseFilterService.call(Activity, filter_params)
    expected_count = Activity.where(status: true).count
    
    assert_equal expected_count, result.count
    assert result.all?(&:status)
  end

  test "should filter by greater than condition" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'points',
              operator: 'greater_than',
              value: 5,
              operator_with_previous: 'AND'
            }
          ]
        }
      ],
      group_operator: 'AND'
    }

    result = ActivityFilters::BaseFilterService.call(Activity, filter_params)
    
    assert result.all? { |activity| activity.points > 5 }
  end

  test "should filter by less than condition" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'priority',
              operator: 'less_than',
              value: 3,
              operator_with_previous: 'AND'
            }
          ]
        }
      ],
      group_operator: 'AND'
    }

    result = ActivityFilters::BaseFilterService.call(Activity, filter_params)
    
    assert result.all? { |activity| activity.priority < 3 }
  end

  test "should filter by multiple conditions with AND" do
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
            },
            {
              field: 'status',
              operator: 'equals',
              value: true,
              operator_with_previous: 'AND'
            }
          ]
        }
      ],
      group_operator: 'AND'
    }

    result = ActivityFilters::BaseFilterService.call(Activity, filter_params)
    
    assert result.all? { |activity| activity.kind == 2 && activity.status == true }
  end

  test "should handle empty filter values gracefully" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'title',
              operator: 'contains',
              value: '',
              operator_with_previous: 'AND'
            }
          ]
        }
      ],
      group_operator: 'AND'
    }

    result = ActivityFilters::BaseFilterService.call(Activity, filter_params)
    # Should return all records when value is empty
    assert_equal Activity.count, result.count
  end

  test "should handle nil filter values gracefully" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'title',
              operator: 'contains',
              value: nil,
              operator_with_previous: 'AND'
            }
          ]
        }
      ],
      group_operator: 'AND'
    }

    result = ActivityFilters::BaseFilterService.call(Activity, filter_params)
    # Should return all records when value is nil
    assert_equal Activity.count, result.count
  end

  test "should handle invalid field names gracefully" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'invalid_field',
              operator: 'equals',
              value: 'test',
              operator_with_previous: 'AND'
            }
          ]
        }
      ],
      group_operator: 'AND'
    }

    # Should not raise an error
    assert_nothing_raised do
      ActivityFilters::BaseFilterService.call(Activity, filter_params)
    end
  end

  test "should process multiple groups with OR operator" do
    filter_params = {
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
        },
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
      ],
      group_operator: 'OR'
    }

    result = ActivityFilters::BaseFilterService.call(Activity, filter_params)
    
    # Deve retornar atividades que são Melhoria OU Bug
    expected_activities = Activity.where(kind: [1, 2])
    assert_equal expected_activities.count, result.count
    
    # Verificar se todas as atividades são do tipo 1 ou 2
    assert result.all? { |activity| [1, 2].include?(activity.kind) }
  end

  test "should process multiple groups with AND operator" do
    filter_params = {
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
        },
        {
          operator: 'AND',
          filters: [
            {
              field: 'status',
              operator: 'equals',
              value: true,  # Ativo
              operator_with_previous: 'AND'
            }
          ]
        }
      ],
      group_operator: 'AND'
    }

    result = ActivityFilters::BaseFilterService.call(Activity, filter_params)
    
    # Deve retornar atividades que são Bug E Ativo
    expected_activities = Activity.where(kind: 2, status: true)
    assert_equal expected_activities.count, result.count
    
    # Verificar se todas as atividades são Bug E ativas
    assert result.all? { |activity| activity.kind == 2 && activity.status == true }
  end

  test "should handle complex multiple groups" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'kind',
              operator: 'equals',
              value: 1,  # Melhoria
              operator_with_previous: 'AND'
            },
            {
              field: 'status',
              operator: 'equals',
              value: true,  # Ativo
              operator_with_previous: 'AND'
            }
          ]
        },
        {
          operator: 'AND',
          filters: [
            {
              field: 'kind',
              operator: 'equals',
              value: 2,  # Bug
              operator_with_previous: 'AND'
            },
            {
              field: 'priority',
              operator: 'equals',
              value: 1,  # Alta prioridade
              operator_with_previous: 'AND'
            }
          ]
        }
      ],
      group_operator: 'OR'
    }

    result = ActivityFilters::BaseFilterService.call(Activity, filter_params)
    
    # Deve retornar: (Melhoria E Ativo) OU (Bug E Alta Prioridade)
    group1_activities = Activity.where(kind: 1, status: true)
    group2_activities = Activity.where(kind: 2, priority: 1)
    expected_count = (group1_activities.pluck(:id) + group2_activities.pluck(:id)).uniq.count
    
    assert_equal expected_count, result.count
    
    # Verificar se cada atividade atende pelo menos uma das condições
    assert result.all? { |activity| 
      (activity.kind == 1 && activity.status == true) || 
      (activity.kind == 2 && activity.priority == 1)
    }
  end
end 