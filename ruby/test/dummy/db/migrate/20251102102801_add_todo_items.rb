class AddTodoItems < ActiveRecord::Migration[8.0]
  def change
    create_table :todo_items do |t|
      t.string :text, null: false
      t.references :todo_list
      t.timestamps
    end
  end
end
