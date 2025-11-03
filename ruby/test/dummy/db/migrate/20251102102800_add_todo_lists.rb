class AddTodoLists < ActiveRecord::Migration[8.0]
  def change
    create_table :todo_lists do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
