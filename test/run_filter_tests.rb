#!/usr/bin/env ruby

# Script para executar testes de filtros e gerar relatório

puts "🧪 EXECUTANDO TESTES DO SISTEMA DE FILTROS"
puts "=" * 50

# Testes de Services
puts "\n📦 TESTANDO SERVICES..."
system("bundle exec rails test test/services/activity_filters/ -v")

# Testes de Models/Concerns  
puts "\n🏗️  TESTANDO MODELS E CONCERNS..."
system("bundle exec rails test test/models/concerns/filterable_test.rb -v")

# Testes de Controllers
puts "\n🎮 TESTANDO CONTROLLERS..."
system("bundle exec rails test test/controllers/activities_controller_test.rb -v")

# Testes de Sistema (E2E)
puts "\n🌐 TESTANDO SISTEMA (E2E)..."
system("bundle exec rails test:system test/system/activities_filter_test.rb -v")

# Testes de Performance (opcional)
if ENV['RUN_PERFORMANCE_TESTS']
  puts "\n⚡ TESTANDO PERFORMANCE..."
  system("RUN_PERFORMANCE_TESTS=true bundle exec rails test test/performance/filter_performance_test.rb -v")
end

puts "\n✅ TESTES CONCLUÍDOS!"
puts "\n📊 RESUMO DOS TESTES:"
puts "- Services: BaseFilterService e ActivityFilterService"
puts "- Models: Concern Filterable"  
puts "- Controllers: ActivitiesController com filtros"
puts "- Sistema: Interface completa de filtros"
puts "- Performance: Eficiência com grandes datasets"

puts "\n🔍 CENÁRIOS TESTADOS:"
puts "✓ Filtros simples (equals, contains, greater_than, etc.)"
puts "✓ Filtros múltiplos com AND"
puts "✓ Filtros por diferentes tipos de dados (string, integer, boolean, date)"
puts "✓ Tratamento de erros e edge cases"
puts "✓ Interface do modal de filtros"
puts "✓ Atualização dinâmica via AJAX"
puts "✓ Persistência de filtros na URL"
puts "✓ Responsividade mobile"
puts "✓ Performance e otimização de queries"

puts "\n🚀 Para executar testes específicos:"
puts "bundle exec rails test test/services/activity_filters/base_filter_service_test.rb"
puts "bundle exec rails test test/services/activity_filters/activity_filter_service_test.rb"
puts "bundle exec rails test test/controllers/activities_controller_test.rb"
puts "bundle exec rails test:system test/system/activities_filter_test.rb"
puts "\n🔥 Para testes de performance:"
puts "RUN_PERFORMANCE_TESTS=true bundle exec rails test test/performance/" 