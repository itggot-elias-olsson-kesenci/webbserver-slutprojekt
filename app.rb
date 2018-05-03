class App < Sinatra::Base
	enable:sessions  

	get '/' do
		slim :index
	end

	get '/home' do
		if session[:user_id]  
			slim :index
		else
			slim :register
		end
	end

	get '/register' do
		slim (:register)
	end

	post '/register' do
		db = SQLite3::Database.open("db/todo-app.sqlite")
		username = params[:Username]
		password = params[:Password]
		hashed_password = BCrypt::Password.create(password)
		db.execute("INSERT INTO login (username, password) VALUES(?,?)", [username, hashed_password])
		id = db.execute("SELECT id FROM login WHERE username =?", [username])
		session[:user_id] = id
		redirect("/")
	end

	post '/' do
		login_username = params[:login_username]
		login_password = params[:login_password]
		
		db = SQLite3::Database.open("db/todo-app.sqlite")
		hashed_password= db.execute("SELECT password FROM login WHERE username =?", login_username )[0][0]
		hashed_password = BCrypt::Password.new(hashed_password)

		if hashed_password == login_password 
			id = db.execute("SELECT id FROM login WHERE username =?", [login_username])[0][0]
			session[:login] = id
			redirect("/user")
		else
			redirect("/")
		end
	end 
	
	get '/logout' do
		session.clear
		redirect('/')
	end  

	get '/user' do
		login_id = session[:login]
		db = SQLite3::Database.open("db/todo-app.sqlite")
		login_username = db.execute("SELECT username FROM login WHERE id =?", [login_id])[0][0]
		session[:username] = login_username
		slim(:user, locals:{username:login_username})
	end
	
	get '/lists' do
		login_id = session[:login]
		login_username = session[:username]
		db = SQLite3::Database.open("db/todo-app.sqlite")
		lists_array = db.execute("SELECT ID, listname FROM lists WHERE userID =?", [login_id])
		slim(:lists, locals:{username:login_username, lists_array:lists_array})
	end

	get '/lists/:id' do
		id = params[:id]
		db = SQLite3::Database.open("db/todo-app.sqlite")
		container = db.execute("SELECT groceryID FROM relation WHERE listID=?", [id])
		n = 0
		groceries = []
			while n < container.length
				id = container[n][0]
				grocery = db.execute("SELECT name FROM groceries WHERE id=?", [id])
				groceries.push(grocery)
				n += 1
			end
		slim(:containing, locals:{groceries:groceries})
	end	

	post '/lists' do
		listname = params[:listname]
		login_id = session[:login]
		db = SQLite3::Database.open("db/todo-app.sqlite")
		db.execute("INSERT INTO lists (listname, userID) VALUES(?, ?)", [listname, login_id])
		redirect('/lists')
	end

	get '/groceries' do
		db = SQLite3::Database.open("db/todo-app.sqlite")
		groceries_array = db.execute("SELECT * FROM groceries")
		slim(:groceries, locals:{groceries_array: groceries_array})
	end

	get '/groceries/:id' do
		login_id = session[:login]
		session[:groceryID] = params[:id]
		groceryID = session[:groceryID]
		db = SQLite3::Database.open("db/todo-app.sqlite")
		grocery = db.execute("SELECT name FROM groceries WHERE id =?", [groceryID])[0][0]			
		lists_array = db.execute("SELECT * FROM lists WHERE userID =?", [login_id])
		slim(:grocery, locals:{lists_array:lists_array, grocery:grocery})
	end
	
	get '/add/:id' do
		listID = params[:id]
		groceryID = session[:groceryID]	
		db = SQLite3::Database.open("db/todo-app.sqlite")		
		db.execute("INSERT INTO relation (listID, groceryID) VALUES(?, ?)", [listID, groceryID])
		redirect('/groceries')
	end
end