require "sinatra"
require "tilt/erubis"
require "sinatra/content_for"

require_relative "database_persistence"

configure do
  set :erb, :escape_html => true
  enable :sessions
  set :session_secret, 'secret'
end

configure(:development) do 
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
end

helpers do
  def list_complete?(list)
    todos_remaining_count(list) == 0 && todos_count(list) > 0
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_count(list)
    list[:todos].size
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }

    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
      complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

      incomplete_todos.each(&block)
      complete_todos.each(&block)
  end
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = @storage.all_list
  erb :lists, layout: :layout
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

def error_for_list_name(name)
  if @storage.all_list.any? { |list| list[:name] == name}
    "List name must be unique"
  elsif !(1..100).cover? name.size
    "List name must be between 1 and 100 characters"
  end
end

def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo name must be between 1 and 100 characters"
  end
end

def load_list(id)
  list = @storage.find_list(id)
  return list if list

  session[:error] = "The specified list was not found"
  redirect "/lists"
end


post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @storage.create_new_list(list_name)
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  erb :list, layout: :layout
end

get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = load_list(id)
  erb :edit_list, layout: :layout
end

post "/lists/:id" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  id = params[:id].to_i
  @list = load_list(id)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @storage.update_list_name(id, list_name)
    session[:success] = "The list name has been changed."
    redirect "/lists/#{id}"
  end
end

post "/lists/:id/destroy" do
  id = params[:id].to_i

  @storage.delete_list(id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list has been deleted"
    redirect "/lists"
  end
end

# Adding a new todo to the list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @storage.create_new_todo(@list_id, text)
    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end
end

post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:id].to_i
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    @storage.delete_todo_from_list(@list_id, todo_id)
    session[:success] = "The todo has been deleted"
    redirect "/lists/#{@list_id}"
  end
end

# update status of a todo
post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @storage.update_todo_status(@list_id, todo_id, is_completed)

  session[:success] = "The todo has been updated"
  redirect "/lists/#{@list_id}"
end

# update all todos to complete
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i

  @storage.mark_all_todos_as_completed(@list_id)
  session[:success] = "All todos have been completed"
  redirect "/lists/#{@list_id}"
end
