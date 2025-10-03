require 'test_helper'
require 'benchmark'

class FilterPerformanceTest < ActiveSupport::TestCase
  def setup
    # Criar dados de teste para performance
    create_test_data if Activity.count < 100
  end

  test "should filter large dataset efficiently" do
    skip "Performance test - run manually" unless ENV['RUN_PERFORMANCE_TESTS']
    
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

    # Medir tempo de execução
    time = Benchmark.measure do
      result = ActivityFilters::ActivityFilterService.call(filter_params)
      result.to_a  # Forçar execução da query
    end

    # Deve executar em menos de 100ms
    assert time.real < 0.1, "Filter took too long: #{time.real}s"
  end

  test "should handle multiple complex filters efficiently" do
    skip "Performance test - run manually" unless ENV['RUN_PERFORMANCE_TESTS']
    
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
            },
            {
              field: 'priority',
              operator: 'less_than',
              value: 3,
              operator_with_previous: 'AND'
            },
            {
              field: 'title',
              operator: 'contains',
              value: 'test',
              operator_with_previous: 'AND'
            }
          ]
        }
      ]
    }

    time = Benchmark.measure do
      result = ActivityFilters::ActivityFilterService.call(filter_params)
      result.to_a
    end

    # Mesmo com múltiplos filtros, deve ser rápido
    assert time.real < 0.2, "Complex filter took too long: #{time.real}s"
  end

  test "should not cause N+1 queries" do
    filter_params = {
      groups: [
        {
          operator: 'AND',
          filters: [
            {
              field: 'kind',
              operator: 'equals',
              value: 1,
              operator_with_previous: 'AND'
            }
          ]
        }
      ]
    }

    # Contar queries executadas
    queries_count = 0
    callback = lambda { |*args| queries_count += 1 }
    
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      result = ActivityFilters::ActivityFilterService.call(filter_params)
      
      # Acessar usuários para verificar N+1
      result.each { |activity| activity.user.name }
    end

    # Deve executar poucas queries (1 para activities + 1 para users)
    assert queries_count <= 3, "Too many queries executed: #{queries_count}"
  end

  test "should generate efficient SQL" do
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
      ]
    }

    result = ActivityFilters::ActivityFilterService.call(filter_params)
    sql = result.to_sql

    # Verificar se o SQL gerado é eficiente
    assert_match /WHERE/, sql
    assert_match /kind.*=.*2/, sql
    assert_match /status.*=/, sql
    
    # Não deve ter subconsultas desnecessárias
    assert_no_match /SELECT.*FROM.*SELECT/, sql
  end

  private

  def create_test_data
    return if Activity.count >= 100

    puts "Creating test data for performance tests..."
    
    # Criar usuários de teste
    users = []
    4.times do |i|
      users << User.create!(name: "Test User #{i}")
    end

    # Criar 100 atividades de teste
    100.times do |i|
      Activity.create!(
        title: "Test Activity #{i}",
        description: "Description for activity #{i}",
        status: [true, false].sample,
        start_date: Date.current - rand(30).days,
        end_date: Date.current + rand(30).days,
        kind: rand(1..5),
        completed_percent: rand(0.0..100.0),
        priority: rand(1..3),
        urgency: rand(1..3),
        points: rand(1..21),
        user: users.sample
      )
    end
    
    puts "Created #{Activity.count} activities for testing"
  end
end 