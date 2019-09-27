require 'rubygems'
require 'bundler/setup'
require 'date'

Bundler.require(:default)

class ListNotFoundError < StandardError; end

BOARD_ID = '2TiLpk0t'.freeze
BACKLOGGED_LABEL_NAME = 'Backlogged'.freeze

WEEKDAY_MAPPING = {
  'Monday' => 'Montag',
  'Tuesday' => 'Dienstag',
  'Wednesday' => 'Mittwoch',
  'Thursday' => 'Donnerstag',
  'Friday' => 'Freitag',
  'Saturday' => 'Samstag',
  'Sunday' => 'Sonntag'
}.freeze

Trello.configure do |config|
  config.developer_public_key = ENV['TRELLO_DEVELOPER_PUBLIC_KEY']
  config.member_token = ENV['TRELLO_MEMBER_TOKEN']
end

def main
  move_previous_cards_to_today
end

def board
  @board ||= Trello::Board.find(BOARD_ID)
end

def move_previous_cards_to_today
  previous_days.each do |day_name|
    list_on(day_name).cards.each do |card|
      card.move_to_list(list_on(today_name))
      card.add_label(backlogged_label) unless
        card.labels.map(&:name).include? BACKLOGGED_LABEL_NAME
    end
  end
end

def previous_days
  if weekday_index(today_name).zero?
    return WEEKDAY_MAPPING.keys - [today_name]
  end

  WEEKDAY_MAPPING.keys[0..(weekday_index(today_name) - 1)]
end

def list_on(day_name)
  list_name = WEEKDAY_MAPPING[day_name]
  board.lists.find { |x| x.name == list_name } or raise ListNotFoundError
end

def weekday_index(day_name)
  WEEKDAY_MAPPING.keys.index(day_name)
end

def today_name
  Date.today.strftime('%A')
end

def backlogged_label
  @backlogged_label = board.labels.find { |x| x.name == BACKLOGGED_LABEL_NAME }
end
main
