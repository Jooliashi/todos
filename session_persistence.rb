require "pg"

class DatabasePersistence
  def initialize
    @db = PG.connection(dbname: "todos")
  end

  def all_list
    sql = "SELECT * FROM lists"
    result = @db.exec(sql)
		result.map do |tuple|
			{id: tuple["id"], name: tuple["name"], todos: []}
		end
  end
  
  def find_list(id)
    @session[:lists].find{ |list| list[:id] == id }
  end
  
  def create_new_list(list_name)
    id = next_element_id(@session[:lists])
    @session[:lists] << {id: id, name: list_name, todos: [] }
  end

  def delete_list(id)
    @session[:lists].reject! { |list| list[:id] == id }
  end
 
  def update_list_name(id, new_name)
    list = find_list(id)
    list[:name] = list_name
  end

  def create_new_todo(list_id, todo_name)
    id = next_element_id(@list[:todos])
    @list[:todos] << {id: id, name: text, completed: false}
  end

  def delete_todo_from_list(list_id, todo_id)
    list = find_list(list_id)
    list[:todos].reject! { |todo| todo[:id] == todo_id }
  end

  def update_todo_status(list_id, todo_id, new_status)
    list = find_list(list_id)
    todo = list[:todo].find { |todo| todo[:id] == todo_id }
    todo[:completed] = new_status
  end

  def mark_all_todos_as_completed(list_id)
    list = find_list(list_id)
    list[:todos].each do |todo|
      todo[:completed] = true
    end
  end
end
