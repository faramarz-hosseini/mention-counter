<b> <h1>Mention Counter </h1></b>
A simple bot I wrote to learn Ruby. You can use it if you want to keep track of how many times you mentioned a user in a discord channel using its command.

<b><h2>How does it work?</h2></b>
Once the bot is up and running in your server, type !help to see an overview of commands.<br>
The bot uses an SQLite Database to store the number of times users were mentioned.<br>
Mentions are not global. This means that if you mention the same user in different channels, the bot will store mention counters for each channel separately. <br>

<b><h2> Setup </h2></b>
Create a new bot in the Discord developer portal and add it to your server. <br>
Install Ruby. <br>
Clone the repository and run the following in the cloned directory:
<br>
```ruby
bundle install
```
Set the following environment variables:<br>
```ruby
export BOT_TOKEN="YOUR BOT TOKEN"
export SQLITE_DB_PATH="PATH/TO/WHERE/YOU/WANT"
```
Now you're ready to run the bot: <br>
```ruby
bundle exec ruby main.rb
```
OR
```ruby
ruby main.rb
```
P.S. Alternatively, the bot can be run in a container with the docker run command.

<br><br>

<b><h2>To Do</h2></b>
List of things I want to do/change if I ever get the chance. PRs are welcome. :)
<br><br><b>Reimplement the increment command</b><br>
As it stands right now, to increment the mention counter for any given user, you must call the !increment command. Instead, it'd be more ideal if the bot kept listening to the channels it is present in (register a on_message event) and when users are mentioned, automatically incremented the count for mentioned users. This will however overload the database in servers that users get mentioned a lot. So on top of the on_message event handler, the bot should be configurable on what channels to listen to.

<br><b>Improve the decrement command</b><br>
The decrement command gives false feedback. When the count for a user is already zero and the command is invoked for the user, while nothing happens in the database and the invokation is simply ignored, the bot responds: 
> Count decremented for User1.<br>

This should change.




