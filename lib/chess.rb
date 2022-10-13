# lib/chess.rb
# frozen_string_literal: true

class Board
  attr_accessor :state

  def initialize
    @state = Array.new(8) { Array.new(8, :empty) }
  end

  def move_piece(origin, dest)
    origin_x, origin_y = origin
    dest_x, dest_y = dest
    piece = state[origin_x][origin_y]
    piece.location = dest
    state[dest_x][dest_y] = piece
    state[origin_x][origin_y] = :empty
  end
end
end

class BoardSetup
  attr_accessor :board
  attr_reader :move_list

  def initialize(board, move_list)
    @board = board
    @move_list = move_list
  end

  def new_game
    place_pawns(:white)
    place_pieces(:white)
    place_pawns(:black)
    place_pieces(:black)
  end

  def place_pawns(colour)
    starting_rank = colour.eql?(:white) ? 1 : 6
    0.upto(7) do |file|
      pawn = Pawn.new([file, starting_rank], colour, move_list)
      board.state[file][starting_rank] = pawn
    end
  end

  def place_pieces(colour)
    starting_rank = colour.eql?(:white) ? 0 : 7
    0.upto(7) do |file|
      piece = file_to_piece(file).new([file, starting_rank], colour, move_list)
      board.state[file][starting_rank] = piece
    end
  end

  def file_to_piece(file)
    case file
    when 0, 7
      Rook
    when 1, 6
      Knight
    when 2, 5
      Bishop
    when 4
      King
    when 3
      Queen
    end
  end
end

class Piece
  attr_accessor :location
  attr_reader :move_list, :colour, :symbol

  def initialize(location, colour, move_list)
    @location = location
    @colour = colour
    @move_list = move_list
  end
end

class King < Piece
  def initialize(location, colour, move_list)
    @symbol = colour.eql?(:white) ? "♔" : "♚"
    super
  end

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
  def initialize(location, colour, move_list)
    @symbol = colour.eql?(:white) ? "♕" : "♛"
    super
  end

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
  def initialize(location, colour, move_list)
    @symbol = colour.eql?(:white) ? "♖" : "♜"
    super
  end

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
  def initialize(location, colour, move_list)
    @symbol = colour.eql?(:white) ? "♗" : "♝"
    super
  end

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

class Knight < Piece
  def initialize(location, colour, move_list)
    @symbol = colour.eql?(:white) ? "♘" : "♞"
    super
  end

  def valid_moves
    directions = [long_left_up, long_up_left, long_up_right, long_right_up,
                  long_right_down, long_down_right, long_down_left, long_left_down]
    directions.flat_map { |d| search(d) }.sort
  end

  private

  def long_left_up
    ->(a, b) { [a - 2, b + 1] }
  end

  def long_up_left
    ->(a, b) { [a - 1, b + 2] }
  end

  def long_up_right
    ->(a, b) { [a + 1, b + 2] }
  end

  def long_right_up
    ->(a, b) { [a + 2, b + 1] }
  end

  def long_right_down
    ->(a, b) { [a + 2, b - 1] }
  end

  def long_down_right
    ->(a, b) { [a + 1, b - 2] }
  end

  def long_down_left
    ->(a, b) { [a - 1, b - 2] }
  end

  def long_left_down
    ->(a, b) { [a - 2, b - 1] }
  end

  def search(transformer)
    move_list.search(location, transformer, stop_counter: 1)
  end
end

class Pawn < Piece
  attr_accessor :moved

  def initialize(location, colour, move_list)
    @symbol = colour.eql?(:white) ? "♙" : "♟"
    @moved = false
    super
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
