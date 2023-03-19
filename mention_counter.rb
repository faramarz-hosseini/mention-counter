# frozen_string_literal: true

require_relative 'sqlite_cli'

require 'sqlite3'
require 'discordrb'

# counts number of times members in a channel were mentioned
# and saves the counts to a sqlite3 db
class MentionCounter
  def initialize(db_name, bot_token)
    @discord_cli = Discordrb::Commands::CommandBot.new(token: bot_token, prefix: '/')
    @db_cli = SqliteCli.new(db_name)
    initialize_mentions_table
  end

  def run
    register_event_handlers
    register_command_handlers
    @discord_cli.run
  end

  private

  def register_event_handlers
    increment_mentions_handler
  end

  def register_command_handlers
    calculate_mentions_handler
  end

  def calculate_mentions_handler
    @discord_cli.command(
      :calculate,
      chain_usable: true,
      description: 'Takes input and multiplies number of mentions for each user by that input'
    ) do |_event, mention_value|
      return 'mention value has to be a number' unless mention_value.to_i

      rows = @db_cli.read('mentions', ['*'], nil)
      rows.map { |r| "#{r['user']}: #{r['count'].to_i * mention_value.to_i}" }.compact.join('
        ')
    end
  end

  def increment_mentions_handler
    @discord_cli.message do |event|
      mentions = event.message.mentions
      mentions.each do |m|
        increment_user_mentions(m.username)
      end

      unless mentions.empty?
        event.respond "Count successfully incremented for #{mentions.map(&:username).compact.join(', ')}"
      end
    end
  end

  def increment_user_mentions(username) # rubocop:disable Metrics/MethodLength
    rows = @db_cli.read(
      'mentions', ['*'], [{ signature: :eq, params: ['user', username] }]
    )
    if rows.empty?
      @db_cli.write('mentions', %w[user count], [username, 1])
    else
      current_count = rows[0]['count']
      @db_cli.update(
        'mentions',
        ['count'], [current_count + 1],
        [{ signature: :eq, params: ['user', username] }]
      )
    end
  end

  def initialize_mentions_table
    @db_cli.storage.execute <<-SQL
        create table mentions (
          id integer primary key autoincrement,
          user varchar(100) unique,
          count int
        );
    SQL
  rescue SQLite3::SQLException => e
    raise "unexpected sql error in mention counter setup: #{e}" unless e.message.end_with?('already exists')
  end
end
