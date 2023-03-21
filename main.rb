# frozen_string_literal: true

require_relative 'mention_counter'

mention_counter = MentionCounter.new('mentions.db', ENV['BOT_TOKEN'])
mention_counter.run
