class RenameUsersToFictionalNames < ActiveRecord::Migration[8.0]
  def up
    # Renomear usuários "User X" para nomes fictícios
    user_mappings = {
      "User 1" => "Carlos Silva",
      "User 2" => "Ana Santos", 
      "User 3" => "Bruno Costa",
      "User 4" => "Fernanda Lima",
      "User 5" => "Ricardo Oliveira",
      "User 6" => "Juliana Pereira",
      "User 7" => "Marcos Rodrigues",
      "User 8" => "Patrícia Alves",
      "User 9" => "Leonardo Martins",
      "User 10" => "Camila Ferreira"
    }

    user_mappings.each do |old_name, new_name|
      User.where(name: old_name).update_all(name: new_name)
    end

    # Remover usuários duplicados do seeds se existirem
    duplicate_names = ["Alexandre Augusto Berns Simao", "Maria Silva", "João Santos", "Ana Costa"]
    duplicate_names.each do |name|
      # Manter apenas o primeiro usuário com esse nome
      users_with_name = User.where(name: name)
      if users_with_name.count > 1
        users_with_name.offset(1).destroy_all
      end
    end
  end

  def down
    # Reverter para nomes originais
    user_mappings = {
      "Carlos Silva" => "User 1",
      "Ana Santos" => "User 2",
      "Bruno Costa" => "User 3", 
      "Fernanda Lima" => "User 4",
      "Ricardo Oliveira" => "User 5",
      "Juliana Pereira" => "User 6",
      "Marcos Rodrigues" => "User 7",
      "Patrícia Alves" => "User 8",
      "Leonardo Martins" => "User 9",
      "Camila Ferreira" => "User 10"
    }

    user_mappings.each do |new_name, old_name|
      User.where(name: new_name).update_all(name: old_name)
    end
  end
end
