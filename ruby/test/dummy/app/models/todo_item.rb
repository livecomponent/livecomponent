# frozen_string_literal: true

class TodoItem < ActiveRecord::Base
  belongs_to :todo_list

  def lowercase_text
    text.downcase
  end
end
