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
  attr_reader :move_list, :colour

  def initialize(start_square, colour, move_list)
    @location = start_square
    @colour = colour
    @move_list = move_list
  end
end

class King < Piece
  def valid_moves
    directions = [up, down, left, right,
                  up_left, up_right, down_left, down_right]
    directions.flat_map { |d| search(d) }.sort
  end

  def up
    ->(a, b) { [a, b + 1] }
  end

  def down
    ->(a, b) { [a, b - 1] }
  end

  def left
    ->(a, b) { [a - 1, b] }
  end

  def right
    ->(a, b) { [a + 1, b] }
  end

  def up_left
    ->(a, b) { [a - 1, b + 1] }
  end

  def up_right
    ->(a, b) { [a + 1, b + 1] }
  end

  def down_left
    ->(a, b) { [a - 1, b - 1] }
  end

  def down_right
    ->(a, b) { [a + 1, b - 1] }
  end

  def search(transformer)
    move_list.search(location, transformer, stop_counter: 1)
  end
end

class Queen < Piece
  def valid_moves
    directions = [up, down, left, right,
                  up_left, up_right, down_left, down_right]
    directions.flat_map { |d| search(d) }.sort
  end

  private

  def up
    ->(a, b) { [a, b + 1] }
  end

  def down
    ->(a, b) { [a, b - 1] }
  end

  def left
    ->(a, b) { [a - 1, b] }
  end

  def right
    ->(a, b) { [a + 1, b] }
  end

  def up_left
    ->(a, b) { [a - 1, b + 1] }
  end

  def up_right
    ->(a, b) { [a + 1, b + 1] }
  end

  def down_left
    ->(a, b) { [a - 1, b - 1] }
  end

  def down_right
    ->(a, b) { [a + 1, b - 1] }
  end

  def search(transformer)
    move_list.search(location, transformer)
  end

end

class Rook < Piece
  def valid_moves
    directions = [up, down, left, right]
    directions.flat_map { |d| search(d) }.sort
  end

  private

  def up
    ->(a, b) { [a, b + 1] }
  end

  def down
    ->(a, b) { [a, b - 1] }
  end

  def left
    ->(a, b) { [a - 1, b] }
  end

  def right
    ->(a, b) { [a + 1, b] }
  end

  def search(transformer)
    move_list.search(location, transformer)
  end
end

class Bishop < Piece
  def valid_moves
    directions = [up_left, up_right, down_left, down_right]
    directions.flat_map { |d| search(d) }.sort
  end

  private

  def up_left
    ->(a, b) { [a - 1, b + 1] }
  end

  def up_right
    ->(a, b) { [a + 1, b + 1] }
  end

  def down_left
    ->(a, b) { [a - 1, b - 1] }
  end

  def down_right
    ->(a, b) { [a + 1, b - 1] }
  end

  def search(transformer)
    move_list.search(location, transformer)
  end
end

class Pawn < Piece
  attr_accessor :moved

  def initialize(location, colour, move_list)
    super
    @moved = false
  end

  def valid_moves
    search(advance_colour).sort
  end

  private

  def advance_colour
    case colour
    when :white
      advance_white
    when :black
      advance_black
    end
  end

  def advance_white
    ->(a, b) { [a, b + 1] }
  end

  def advance_black
    ->(a, b) { [a, b - 1] }
  end

  def search(transformer)
    move_count = moved ? 1 : 2
    move_list.search(location, transformer, stop_counter: move_count)
  end
end

class MoveList
  attr_reader :board

  def initialize(board)
    @board = board
  end

  def search(coords, search_lambda, results = [], stop_counter: nil)
    return results if stop_counter&.zero?

    dest_coords = search_lambda.call(coords[0], coords[1])
    if traversible_space?(dest_coords)
      results << dest_coords
      search(dest_coords, search_lambda, results, stop_counter: stop_counter&.pred)
    else
      results
    end
  end

  def attacks(coords, colour, search_lambda)
    dest_coords = search_lambda.call(coords[0], coords[1])
    if enemy_piece?(dest_coords, colour)
      dest_coords
    elsif traversible_space?(dest_coords)
      attacks(dest_coords, colour, search_lambda)
    end
  end

  private

  def traversible_space?(dest_coords)
    destination = board.state.dig(*dest_coords)
    destination.eql?(:empty) && dest_coords.none?(&:negative?)
  end

  def enemy_piece?(dest_coords, attacker_colour)
    destination = board.state.dig(*dest_coords)
    destination.is_a?(Piece) && !destination.colour.eql?(attacker_colour)
  end
end
