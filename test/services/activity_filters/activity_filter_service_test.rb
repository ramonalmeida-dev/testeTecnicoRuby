require 'test_helper'

class ActivityFilters::ActivityFilterServiceTest < ActiveSupport::TestCase
  def setup
    @service = ActivityFilters::ActivityFilterService.new({})
  end

  # ===== TESTES DE CONFIGURAÇÃO =====
  
  test "should have correct filterable fields" do
    fields = ActivityFilters::ActivityFilterService.filterable_fields
    
    expected_fields = %w[id title description status start_date end_date kind completed_percent priority urgency points user_id created_at updated_at]
    assert_equal expected_fields.sort, fields.keys.sort
  end

  test "should return correct field options" do
    options = ActivityFilters::ActivityFilterService.field_options
    
    assert options.is_a?(Array)
    assert options.all? { |option| option.is_a?(Array) && option.size == 2 }
    
    # Verificar se contém campos essenciais
    field_values = options.map(&:last)
    assert_includes field_values, 'kind'
    assert_includes field_values, 'status'
    assert_includes field_values, 'urgency'
  end

  test "should return correct field labels in Portuguese" do
    assert_equal 'Tipo', ActivityFilters::ActivityFilterService.field_label('kind')
    assert_equal 'Status', ActivityFilters::ActivityFilterService.field_label('status')
    assert_equal 'Urgência', ActivityFilters::ActivityFilterService.field_label('urgency')
    assert_equal 'Responsável', ActivityFilters::ActivityFilterService.field_label('user_id')
  end

  test "should return correct operator labels in Portuguese" do
    assert_equal 'Igual a', ActivityFilters::ActivityFilterService.operator_label('equals')
    assert_equal 'Contém', ActivityFilters::ActivityFilterService.operator_label('contains')
    assert_equal 'Maior que', ActivityFilters::ActivityFilterService.operator_label('greater_than')
  end

  # ===== TESTES DE OPÇÕES DE VALORES =====
  
  test "should return kind options" do
    options = ActivityFilters::ActivityFilterService.kind_options
    
    assert options.is_a?(Array)
    assert_equal 5, options.size
    
    # Verificar se contém as opções esperadas
    values = options.map(&:last)
    assert_includes values, 1  # Melhoria
    assert_includes values, 2  # Bug
    assert_includes values, 3  # Spike
    assert_includes values, 4  # Documentação
    assert_includes values, 5  # Reunião
  end

  test "should return urgency options" do
    options = ActivityFilters::ActivityFilterService.urgency_options
    
    assert options.is_a?(Array)
    assert_equal 3, options.size
    
    # Verificar se contém as opções esperadas
    values = options.map(&:last)
    assert_includes values, 1  # Alto
    assert_includes values, 2  # Médio
    assert_includes values, 3  # Baixo
  end

  test "should return status options" do
    options = ActivityFilters::ActivityFilterService.status_options
    
    assert options.is_a?(Array)
    assert_equal 2, options.size
    
    # Verificar se contém as opções esperadas
    values = options.map(&:last)
    assert_includes values, true   # Ativo
    assert_includes values, false  # Inativo
  end

  test "should return user options" do
    options = ActivityFilters::ActivityFilterService.user_options
    
    assert options.is_a?(Array)
    assert options.size > 0
    
    # Verificar se contém usuários das fixtures
    names = options.map(&:first)
    assert_includes names, 'Alexandre Augusto Berns Simao'
    assert_includes names, 'Maria Silva'
  end

  test "should return correct value options for each field" do
    # Kind field
    kind_options = ActivityFilters::ActivityFilterService.value_options_for_field('kind')
    assert_equal 5, kind_options.size
    
    # Urgency field
    urgency_options = ActivityFilters::ActivityFilterService.value_options_for_field('urgency')
    assert_equal 3, urgency_options.size
    
    # Status field
    status_options = ActivityFilters::ActivityFilterService.value_options_for_field('status')
    assert_equal 2, status_options.size
    
    # User field
    user_options = ActivityFilters::ActivityFilterService.value_options_for_field('user_id')
    assert user_options.size > 0
    
    # Field without options
    empty_options = ActivityFilters::ActivityFilterService.value_options_for_field('title')
    assert_equal [], empty_options
  end

  # ===== TESTES DE FILTROS ESPECÍFICOS =====
  
  test "should filter by kind (Bug)" do
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
        }
      ]
    }

    result = ActivityFilters::ActivityFilterService.call(filter_params)
    
    assert result.count > 0
    assert result.all? { |activity| activity.kind == 2 }
    
    # Verificar se inclui as atividades Bug das fixtures
    titles = result.pluck(:title)
    assert_includes titles, 'Corrigir erro no login'
  end

  test "should filter by urgency (Alto)" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'urgency',
              operator: 'equals',
              value: 1,  # Alto
              operator_with_previous: 'AND'
            }
          ]
        }
      ]
    }

    result = ActivityFilters::ActivityFilterService.call(filter_params)
    
    assert result.count > 0
    assert result.all? { |activity| activity.urgency == 1 }
  end

  test "should filter by status (Ativo)" do
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
      ]
    }

    result = ActivityFilters::ActivityFilterService.call(filter_params)
    
    assert result.count > 0
    assert result.all?(&:status)
  end

  test "should filter by user" do
    alexandre = users(:alexandre)
    
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'user_id',
              operator: 'equals',
              value: alexandre.id,
              operator_with_previous: 'AND'
            }
          ]
        }
      ]
    }

    result = ActivityFilters::ActivityFilterService.call(filter_params)
    
    assert result.count > 0
    assert result.all? { |activity| activity.user_id == alexandre.id }
  end

  test "should filter by title contains" do
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
      ]
    }

    result = ActivityFilters::ActivityFilterService.call(filter_params)
    
    assert result.count > 0
    assert result.all? { |activity| activity.title.include?('Corrigir') }
  end

  test "should filter by title icontains (case insensitive)" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'title',
              operator: 'icontains',
              value: 'teste',
              operator_with_previous: 'AND'
            }
          ]
        }
      ]
    }

    result = ActivityFilters::ActivityFilterService.call(filter_params)
    
    # Deve encontrar atividades com "Teste", "TESTE", "teste", etc.
    assert result.count > 0
    assert result.all? { |activity| activity.title.downcase.include?('teste') }
  end

  test "should filter by points greater than" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'points',
              operator: 'greater_than',
              value: 10,
              operator_with_previous: 'AND'
            }
          ]
        }
      ]
    }

    result = ActivityFilters::ActivityFilterService.call(filter_params)
    
    assert result.all? { |activity| activity.points > 10 }
  end

  test "should filter by completed_percent less than" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'completed_percent',
              operator: 'less_than',
              value: 50.0,
              operator_with_previous: 'AND'
            }
          ]
        }
      ]
    }

    result = ActivityFilters::ActivityFilterService.call(filter_params)
    
    assert result.all? { |activity| activity.completed_percent < 50.0 }
  end

  # ===== TESTES DE FILTROS COMPLEXOS =====
  
  test "should filter by multiple conditions - Bug AND Ativo" do
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
            },
            {
              field: 'status',
              operator: 'equals',
              value: true,  # Ativo
              operator_with_previous: 'AND'
            }
          ]
        }
      ]
    }

    result = ActivityFilters::ActivityFilterService.call(filter_params)
    
    assert result.all? { |activity| activity.kind == 2 && activity.status == true }
  end

  test "should filter by high priority and high urgency" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'priority',
              operator: 'equals',
              value: 1,  # Alta prioridade
              operator_with_previous: 'AND'
            },
            {
              field: 'urgency',
              operator: 'equals',
              value: 1,  # Alta urgência
              operator_with_previous: 'AND'
            }
          ]
        }
      ]
    }

    result = ActivityFilters::ActivityFilterService.call(filter_params)
    
    assert result.all? { |activity| activity.priority == 1 && activity.urgency == 1 }
  end

  test "should include user associations" do
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
        }
      ]
    }

    result = ActivityFilters::ActivityFilterService.call(filter_params)
    
    # Verificar se as associações de usuário estão carregadas
    first_activity = result.first
    assert_not_nil first_activity
    assert_not_nil first_activity.user
    
    # Verificar se o includes foi aplicado corretamente
    assert_includes result.includes_values, :user
    
    # Forçar a execução da query para carregar os dados
    activities = result.to_a
    
    # Verificar se o includes está funcionando (não deve gerar N+1)
    queries_count = 0
    callback = lambda { |*args| queries_count += 1 }
    
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      activities.each { |activity| activity.user.name }
    end
    
    # Não deve executar queries adicionais se includes estiver funcionando
    assert_equal 0, queries_count, "N+1 query detected when accessing user names: #{queries_count}"
  end

  # ===== TESTES DE EDGE CASES =====
  
  test "should handle date filters" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'start_date',
              operator: 'greater_than',
              value: '2025-01-05',
              operator_with_previous: 'AND'
            }
          ]
        }
      ]
    }

    result = ActivityFilters::ActivityFilterService.call(filter_params)
    
    assert result.all? { |activity| activity.start_date > Date.parse('2025-01-05') }
  end

  test "should return correct field type" do
    assert_equal :integer, ActivityFilters::ActivityFilterService.field_type('kind')
    assert_equal :string, ActivityFilters::ActivityFilterService.field_type('title')
    assert_equal :boolean, ActivityFilters::ActivityFilterService.field_type('status')
    assert_equal :date, ActivityFilters::ActivityFilterService.field_type('start_date')
    assert_equal :float, ActivityFilters::ActivityFilterService.field_type('completed_percent')
  end
end 