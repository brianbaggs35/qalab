class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations, id: :uuid do |t|
      t.string :name, null: false
      t.text :settings

      t.timestamps
    end

    add_index :organizations, :name
  end
end
