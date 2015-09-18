require 'sinatra'
require 'data_mapper'
require 'sinatra/flash'


DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/todo_list.db")
set :public_foler, File.dirname(__FILE__) + 'public'
enable :sessions


class Book
  include DataMapper::Resource
  property :id, Serial
  property :name, Text, :required => true
  property :author, Text, :required => true
  property :category, Text, :required => true
  property :isdn_no, Text, :required => true
  property :year, Text, :required => true
  property :no_available, Text
  property :created, DateTime
end

class User
  include DataMapper::Resource
  property :id, Serial
  property :name, Text, :required => true
  property :email, Text, :required => true
  property :password, Text, :required => true
  property :role, Text, :required => true
  property :created, DateTime
end

DataMapper.finalize.auto_upgrade!


  def login
    if session[:username].nil?
    #  return false
    redirect '/home'
    else
      return true
    end
  end
  
  def username
    return session[:username]
  end
get "/logout" do
  session[:username] = nil
  redirect "/"
end

get '/search' do
  login
  name = params[:name]
  category=params[:category]
  @search_result = Book.all(:name.like => name.to_s ,:category => category.to_s,:no_available.not =>"0")
if (@search_result.length > 0)
   @message = ""
  erb :search
  else

  
   @message = "No Record Found Matching Your Search Criteria in the Database."
   erb :search
end

  
 # redirect '/search'
end
get '/top' do
@books = Book.all(:order => :created.desc)
#redirect '/new' if @books.empty? 
erb :top
end



get '/' do

erb :home
end



get '/signup' do

erb :signup
end



get '/login' do

erb :login
end


get '/dashboard' do
login()
@books = Book.all(:order => :created.desc)
redirect '/new' if @books.empty? 
erb :index
end
get '/student_welcome' do
login()
@books = Book.all(:order => :created.desc)
erb :student_welcome
end

get '/not_available' do
login()
@bookss = Book.all(:order => :created.desc,:no_available => 0)
erb :not_available
end
get '/admin_welcome' do
login()
@books = Book.all(:order => :created.desc)
redirect '/new' if @books.empty? 
erb :admin_welcome
end

get '/new' do
  login()
  @title = "Add A New Book"
  erb :new
end

post '/new' do
  login()
  check_exists=Book.count(:name => params[:name],:author =>params[:author],:category =>params[:category],:isdn_no =>params[:isdn_no],:year =>params[:year])
  if(check_exists == 0)
    #perform insert if book has not been previously added
  Book.create(:no_available => 1,:name => params[:name],:author =>params[:author],:category =>params[:category],:isdn_no =>params[:isdn_no],:year =>params[:year],:created => Time.now)
  redirect '/admin_welcome'
else
    book=Book.first(:name => params[:name],:author =>params[:author],:isdn_no =>params[:isdn_no],:year =>params[:year])
    available=book["no_available"]
    book.no_available=(Integer(available) + 1).to_s
    book.save
    redirect '/admin_welcome'
end

end



post "/signup" do
          check_exist_email=User.count(:email => params[:email]) 
          if (check_exist_email > 0)
          @create_status="Email ID Already Exists"
           erb :signup
          elsif(check_exist_email == 0)
            if (params[:role] == "Admin")

                  if (params[:key] == "andela")
                    User.create(:name => params[:name],:email => params[:email],:role =>params[:role],:password =>params[:password],:created => Time.now)
                      @create_status="user successfully created"
                      session[:username] = params[:email]
                      session[:name]=params[:name]
                      redirect '/admin_welcome'
                  else
                     @create_status="Invalid Authorization Code"
                    erb :signup
                  end

            elsif(params[:role] == "Student")
            User.create(:name => params[:name],:email => params[:email],:role =>params[:role],:password =>params[:password],:created => Time.now)
            @create_status="user successfully created"
             session[:username] = params[:email]
             session[:name]=params[:name]
            redirect '/student_welcome'
             
            end
            
          end



 
 
 
end



post "/login" do
 
   check_exists=User.count(:email => params[:email])
  if (check_exists > 0)
     get_user_details=User.first(:email => params[:email])
     name=get_user_details["name"]
     email=get_user_details["email"]
     password=get_user_details["password"]
     role=get_user_details["role"]
       @login_status=""
    if password == params[:password]
      session[:username] = params[:email]
      session[:name] = name.to_s
        @login_status=""

        if (role == "Student")
        redirect "/student_welcome"
        elsif(role == "Admin")
           redirect "/admin_welcome"
        end
     
    else
      @login_status="Invalid User Name or Password"
    end
  else
    @login_status="Invalid User Name or Password"
  end
@login_status="Invalid User Name or Password"
end




get '/update/:id' do
  login()
  @book =Book.first(:id => params[:id].to_i)
 # flash[:gab] = "Book #{params[:id]}"
  erb :borrow
end
get '/delete/:id' do
  login()
  @book =Book.first(:id => params[:id].to_i)
 # flash[:gab] = "Book #{params[:id]}"
  erb :delete
end
put '/update/:id' do
   login()
   book=Book.first(:id => params[:id].to_i)
    available=book["no_available"]
    book["no_available"]=(Integer(available) - 1).to_s
    book.save
    redirect '/student_welcome'
end
delete '/delete/:id' do
 book=Book.first(:id => params[:id].to_i)
    available=book["no_available"]
    book.destroy
    redirect '/admin_welcome'
end
#<% show_class = 'hide' if @is_show %>
#<%= "class='#{show_class}'" %>