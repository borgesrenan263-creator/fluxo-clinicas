require "sequel"
require "dotenv/load"

database_url = ENV["DATABASE_URL"]

if database_url && !database_url.strip.empty?
  DB = Sequel.connect(database_url)
else
  require "sqlite3"
  DB = Sequel.sqlite("db/fluxo_clinicas.sqlite3")
end
