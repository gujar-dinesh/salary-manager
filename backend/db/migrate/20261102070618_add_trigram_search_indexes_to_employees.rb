class AddTrigramSearchIndexesToEmployees < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pg_trgm"

    add_index :employees, :full_name, name: "index_employees_on_full_name_trgm", using: :gin, opclass: :gin_trgm_ops
    add_index :employees, :email, name: "index_employees_on_email_trgm", using: :gin, opclass: :gin_trgm_ops
  end
end
