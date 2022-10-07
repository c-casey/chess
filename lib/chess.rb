# lib/chess.rb
# frozen_string_literal: true

class Board
  attr_accessor :state

  def initialize
    @state = Array.new(8) { Array.new(8, :empty) }
  end
end

class Piece
  attr_accessor :location
  attr_reader :move_list

  def initialize(start_square, colour, move_list)
    @location = start_square
    @colour = colour
    @move_list = move_list
  end
end

class Rook < Piece
  def valid_moves
    search_up +
      search_down +
      search_left +
      search_right
  end

  private

  def search_up
    search_lambda = ->(a, b) { [a, b + 1] }
    move_list.search(location, search_lambda)
  end

  def search_down
    search_lambda = ->(a, b) { [a, b - 1] }
    move_list.search(location, search_lambda)
  end

  def search_left
    search_lambda = ->(a, b) { [a - 1, b] }
    move_list.search(location, search_lambda)
  end

  def search_right
    search_lambda = ->(a, b) { [a + 1, b] }
    move_list.search(location, search_lambda)
  end
end

class MoveList
  attr_reader :board

  def initialize(board)
    @board = board
  end

  def search(coords, search_lambda, results = [])
    dest_coords = search_lambda.call(coords[0], coords[1])
    if traversible_space?(dest_coords, board)
      results << dest_coords
      search(dest_coords, search_lambda, results)
    else
      results
    end
  end

  private

  def traversible_space?(dest_coords, board)
    destination = board.state.dig(*dest_coords)
    destination.eql?(:empty) && dest_coords.none?(&:negative?)
  end
end
