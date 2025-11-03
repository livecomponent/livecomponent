# frozen_string_literal: true

class TodoList < ActiveRecord::Base
  has_many :todo_items
end
