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

	post '/login' do
		login_username = params[:login_username]
		login_password = params[:login_password]
		
		db = SQLite3::Database.open("db/todo-app.sqlite")
		hashed_password= db.execute("SELECT password FROM login WHERE username =?", login_username )[0][0]
		hashed_password = BCrypt::Password.new(hashed_password)

		if hashed_password == login_password 
			id = db.execute("SELECT id FROM login WHERE username =?", [login_username])[0][0]
			#ANVÄND ID ISTÄLLET FÖR "TRUE" SÅ ATT DU KAN HÄMTA ID FÖR ATT SÄGA WELCOME "ID"	
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

	post '/user' do
		listname = params[:listname]
		ownerID = session[:login]
		db = SQLite3::Database.open("db/todo-app.sqlite")		
		db.execute("INSERT INTO lists (listname, ownerID) VALUES(?)", [listname, ownerID])
		redirect('/lists')
	end
	
	 get '/lists' do
		login_username = session[:username]
		slim(:list, locals:{username:login_username})
	end
end