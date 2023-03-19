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
    reset_mentions_for_chan_handler
    decrement_user_mentions_handler
  end

  def calculate_mentions_handler # rubocop:disable Metrics/MethodLength
    @discord_cli.command(
      :calculate,
      chain_usable: true,
      description: 'Takes input and multiplies number of mentions for each user by that input'
    ) do |event, mention_value|
      return 'mention value has to be a number and bigger than zero' unless mention_value.to_i != 0

      rows = @db_cli.read(
        'mentions',
        ['*'],
        [{ signature: :eq, params: ['channel_id', event.channel.id] }]
      )
      rows.map { |r| "#{r['user']}: #{r['count'].to_i * mention_value.to_i}" }.compact.join('
')
    end
  end

  def reset_mentions_for_chan_handler
    @discord_cli.command(
      :reset_counts,
      chain_usable: true,
      description: 'Resets (deletes) mention counts for the channel command was called in',
    ) do |event|
      @db_cli.delete(
        'mentions', [{ signature: :eq, params: ['channel_id', event.channel.id] }]
      )
      'Mention counts successfully reset'
    end
  end

  def decrement_user_mentions_handler # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    @discord_cli.command(
      :decrement,
      chain_usable: true,
      description: 'Decrements mention counts for users in input'
    ) do |event|
      mentions = event.message.mentions
      return 'Decrement command must be followed by at least one mention' if mentions.empty?

      mentions.each do |m|
        row = @db_cli.read('mentions', ['*'], [
                             { signature: :eq, params: ['user', m.username] },
                             { signature: :eq, params: ['channel_id', event.channel.id] }
                           ])
        unless row[0].nil?
          @db_cli.update('mentions', ['count'], [row[0]['count'] - 1],
                         [{ signature: :eq, params: ['channel_id', event.channel.id] }])
        end
      end
      "Counter decremented for: #{mentions.map(&:username).compact.join(', ')}"
    end
  end

  def increment_mentions_handler # rubocop:disable Metrics/MethodLength
    @discord_cli.message do |event|
      return nil if event.message.content.start_with?('/decrement')

      mentions = event.message.mentions
      channel_id = event.channel.id
      mentions.each do |m|
        increment_user_mentions(m.username, channel_id)
      end

      unless mentions.empty?
        event.respond "Count successfully incremented for #{mentions.map(&:username).compact.join(', ')}"
      end
    end
  end

  def increment_user_mentions(username, channel_id) # rubocop:disable Metrics/MethodLength
    rows = @db_cli.read(
      'mentions', ['*'], [
        { signature: :eq, params: ['user', username] },
        { signature: :eq, params: ['channel_id', channel_id] }
      ]
    )
    if rows.empty?
      @db_cli.insert('mentions', %w[user count channel_id], [username, 1, channel_id])
    else
      current_count = rows[0]['count']
      @db_cli.update(
        'mentions',
        ['count'], [current_count + 1],
        [
          { signature: :eq, params: ['user', username] },
          { signature: :eq, params: ['channel_id', channel_id] }
        ]
      )
    end
  end

  def initialize_mentions_table # rubocop:disable Metrics/MethodLength
    @db_cli.storage.execute <<-SQL
        create table mentions (
          id integer primary key autoincrement,
          user varchar(100),
          count int,
          channel_id int,
          UNIQUE(user, channel_id)
        );
    SQL
  rescue SQLite3::SQLException => e
    raise "unexpected sql error in mention counter setup: #{e}" unless e.message.end_with?('already exists')
  end
end
