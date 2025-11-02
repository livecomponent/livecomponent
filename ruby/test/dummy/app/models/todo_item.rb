# frozen_string_literal: true

class TodoItem < ApplicationRecord
  belongs_to :todo_list
end
