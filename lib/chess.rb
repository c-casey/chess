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

  def initialize(start_square, colour)
    @location = start_square
    @colour = colour
  end
end

class Rook < Piece
  def valid_moves
    search_up +
      search_down +
      searh_left +
      search_right
  end

  def search_up(board, coords = location, results = [])
    dest_coords = [coords[0], coords[1] + 1]
    if traversible_space?(dest_coords, board)
      results << dest_coords
      search_up(board, dest_coords, results)
    else
      results
    end
  end

  def search_down(board, coords = location, results = [])
    dest_coords = [coords[0], coords[1] - 1]
    if traversible_space?(dest_coords, board)
      results << dest_coords
      search_down(board, dest_coords, results)
    else
      results
    end
  end

  def search_left(board, coords = location, results = [])
    dest_coords = [coords[0] - 1, coords[1]]
    if traversible_space?(dest_coords, board)
      results << dest_coords
      search_left(board, dest_coords, results)
    else
      results
    end
  end

  def search_right(board, coords = location, results = [])
    dest_coords = [coords[0] + 1, coords[1]]
    if traversible_space?(dest_coords, board)
      results << dest_coords
      search_right(board, dest_coords, results)
    else
      results
    end
  end

  def traversible_space?(dest_coords, board)
    destination = board.state.dig(*dest_coords)
    destination.eql?(:empty) && dest_coords.none?(&:negative?)
  end
end
