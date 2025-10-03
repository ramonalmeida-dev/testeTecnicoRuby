require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @activity = activities(:melhoria_ativa)
  end

  test "should get index" do
    get activities_url
    assert_response :success
  end

  # ===== TESTES DE FILTROS =====
  
  test "should filter activities by kind" do
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
      ],
      group_operator: 'AND'
    }
    
    get activities_url, params: { filters: filter_params.to_json }
    assert_response :success
    
    # Verificar se apenas atividades Bug são retornadas
    assert_select 'table tbody tr', Activity.where(kind: 2).count
  end

  test "should filter activities by status" do
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
    
    get activities_url, params: { filters: filter_params.to_json }
    assert_response :success
    
    # Verificar se apenas atividades ativas são retornadas
    assert_select 'table tbody tr', Activity.where(status: true).count
  end

  test "should filter activities by user" do
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
      ],
      group_operator: 'AND'
    }
    
    get activities_url, params: { filters: filter_params.to_json }
    assert_response :success
    
    # Verificar se apenas atividades do Alexandre são retornadas
    assert_select 'table tbody tr', Activity.where(user: alexandre).count
  end

  test "should filter activities by title contains" do
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
    
    get activities_url, params: { filters: filter_params.to_json }
    assert_response :success
    
    # Verificar se a resposta contém apenas atividades com "Corrigir" no título
    expected_count = Activity.where("title LIKE ?", "%Corrigir%").count
    assert_select 'table tbody tr', expected_count
  end

  test "should filter activities by title icontains (case insensitive)" do
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
      ],
      group_operator: 'AND'
    }
    
    get activities_url, params: { filters: filter_params.to_json }
    assert_response :success
    
    # Verificar se a resposta contém atividades com "teste" (case insensitive)
    # SQLite não suporta ILIKE, usar LOWER() para case insensitive
    if ActiveRecord::Base.connection.adapter_name.downcase.include?('sqlite')
      expected_count = Activity.where("LOWER(title) LIKE LOWER(?)", "%teste%").count
    else
      expected_count = Activity.where("title ILIKE ?", "%teste%").count
    end
    assert_select 'table tbody tr', expected_count
  end

  test "should filter activities by multiple conditions" do
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
      ],
      group_operator: 'AND'
    }
    
    get activities_url, params: { filters: filter_params.to_json }
    assert_response :success
    
    # Verificar se apenas atividades Bug E ativas são retornadas
    expected_count = Activity.where(kind: 2, status: true).count
    assert_select 'table tbody tr', expected_count
  end

  test "should filter activities by multiple groups with OR" do
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
    
    get activities_url, params: { filters: filter_params.to_json }
    assert_response :success
    
    # Verificar se atividades Melhoria OU Bug são retornadas
    expected_count = Activity.where(kind: [1, 2]).count
    assert_select 'table tbody tr', expected_count
  end

  test "should handle empty filter gracefully" do
    get activities_url, params: { filters: '' }
    assert_response :success
    
    # Deve retornar todas as atividades
    assert_select 'table tbody tr', Activity.count
  end

  test "should handle invalid JSON filter gracefully" do
    get activities_url, params: { filters: 'invalid json' }
    assert_response :success
    
    # Deve retornar todas as atividades
    assert_select 'table tbody tr', Activity.count
  end

  test "should handle missing filter groups gracefully" do
    filter_params = { group_operator: 'AND' }  # Sem groups
    
    get activities_url, params: { filters: filter_params.to_json }
    assert_response :success
    
    # Deve retornar todas as atividades
    assert_select 'table tbody tr', Activity.count
  end

  test "should enable clear filters button when filters are applied" do
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
    
    get activities_url, params: { filters: filter_params.to_json }
    assert_response :success
    
    # Verificar se o botão "Limpar filtros" está presente e habilitado
    assert_select 'button#clearFiltersBtn', 1
    assert_select 'button#clearFiltersBtn[disabled]', 0
    
    # Verificar se o botão "Filtrar" está presente
    assert_select 'button:contains("Filtrar")', 1
  end

  test "should disable clear filters button when no filters" do
    get activities_url
    assert_response :success
    
    # Verificar se o botão "Limpar filtros" está presente mas desabilitado
    assert_select 'button#clearFiltersBtn', 1
    assert_select 'button#clearFiltersBtn[disabled]', 1
    
    # Verificar se o botão "Filtrar" está presente
    assert_select 'button:contains("Filtrar")', 1
  end

  test "should toggle clear filters button state based on filters" do
    # Sem filtros - botão deve estar desabilitado
    get activities_url
    assert_response :success
    assert_select 'button#clearFiltersBtn[disabled]', 1
    
    # Com filtros - botão deve estar habilitado
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
    
    get activities_url, params: { filters: filter_params.to_json }
    assert_response :success
    assert_select 'button#clearFiltersBtn', 1
    assert_select 'button#clearFiltersBtn[disabled]', 0
  end

  test "should get new" do
    get new_activity_url
    assert_response :success
  end

  test "should create activity" do
    assert_difference("Activity.count") do
      post activities_url, params: { activity: { completed_percent: @activity.completed_percent, description: @activity.description, end_date: @activity.end_date, points: @activity.points, priority: @activity.priority, start_date: @activity.start_date, status: @activity.status, title: @activity.title, kind: @activity.kind, urgency: @activity.urgency } }
    end

    assert_redirected_to activity_url(Activity.last)
  end

  test "should show activity" do
    get activity_url(@activity)
    assert_response :success
  end

  test "should get edit" do
    get edit_activity_url(@activity)
    assert_response :success
  end

  test "should update activity" do
    patch activity_url(@activity), params: { activity: { completed_percent: @activity.completed_percent, description: @activity.description, end_date: @activity.end_date, points: @activity.points, priority: @activity.priority, start_date: @activity.start_date, status: @activity.status, title: @activity.title, kind: @activity.kind, urgency: @activity.urgency } }
    assert_redirected_to activity_url(@activity)
  end

  test "should destroy activity" do
    assert_difference("Activity.count", -1) do
      delete activity_url(@activity)
    end

    assert_redirected_to activities_url
  end
end
