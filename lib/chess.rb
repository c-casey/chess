# lib/chess.rb
# frozen_string_literal: true

class String
  def bg_dark;        "\e[41m#{self}\e[0m" end
  def bg_light;       "\e[45m#{self}\e[0m" end
  def bg_dark_hl;     "\e[44m#{self}\e[0m" end
  def bg_light_hl;    "\e[46m#{self}\e[0m" end
end

class Chess
  attr_accessor :current_player
  attr_reader :board, :move_list, :display, :winner

  def initialize
    @board = Board.new
    @move_list = MoveList.new(@board)
    @display = Display.new
    @current_player = :white
    @winner = nil
    setup_board
    game_loop
  end

  private

  def setup_board
    setup = BoardSetup.new(board, move_list)
    setup.new_game
  end

  def game_loop
    until winner
      display.print_board(board)
      take_turn
    end
  end

  def take_turn
    print "Your turn, #{current_player}! Select a piece: "
    piece = request_origin
    display.print_board(board, piece.valid_moves)
    print "Select a destination, or select currently highlighted piece to choose a different one: "
    destination = request_destination(piece)
    return if piece == board.lookup_square(destination)

    board.move_piece(piece.location, destination)
    swap_players
  end

  def request_origin
    piece = board.coords_to_piece(read_selection)
    return piece if valid_piece?(piece)

    print "Invalid selection! Select a piece: "
    request_origin
  end

  def request_destination(piece)
    destination = board.coords_to_location(read_selection)
    return destination if piece.valid_moves.member?(destination)
    return destination if piece.location.eql?(destination)

    print "You can't move there! Select a destination: "
    request_destination(piece)
  end

  def read_selection
    selection = gets.chomp.downcase
    return selection if valid_input?(selection)

    print "Invalid selection! Try again: "
    read_selection
  end

  def valid_input?(selection)
    selection.length == 2 &&
      selection[0] >= "a" &&
      selection[0] <= "h" &&
      selection[1] >= "1" &&
      selection[1] <= "8"
  end

  def valid_piece?(piece)
    piece.is_a?(Piece) && piece.colour == current_player
  end

  def swap_players
    self.current_player =
      current_player == :white ? :black : :white
  end
end

class Board
  private

  attr_accessor :state

  public

  def initialize
    @state = Array.new(8) { Array.new(8, :empty) }
  end

  def lookup_square(coords)
    x, y = coords
    state.dig(x, y)
  end

  def place_piece(piece, coords)
    x, y = coords
    state[x][y] = piece
  end

  def clear_square(coords)
    place_piece(:empty, coords)
  end

  def move_piece(origin, dest)
    piece = lookup_square(origin)
    clear_square(origin)
    place_piece(piece, dest)
    piece.location = dest
  end

  def coords_to_piece(coords)
    location = coords_to_location(coords)
    lookup_square(location)
  end

  def coords_to_location(coords)
    x = coords[0].ord - 97
    y = coords[1].to_i - 1
    [x, y]
  end
end

class Display
  def print_board(board, highlights = [])
    puts "\n\n\t  A B C D E F G H"
    7.downto(0) do |y|
      print_row(y, board, highlights)
    end
    puts "\t  A B C D E F G H\n\n"
  end

  private

  def print_row(y, board, highlights)
    print "\t#{y + 1} "
    0.upto(7) do |x|
      square_contents = board.lookup_square([x, y])
      symbol = square_contents.eql?(:empty) ? "  " : "#{square_contents.symbol} "
      colour_lambda = colour_picker(x, y, highlights)
      colour_print = colour_lambda.call(x, symbol)
      print colour_print
    end
    puts " #{y + 1}"
  end

  def colour_picker(x_value, y_value, highlights)
    if y_value.odd?
      if highlights.member?([x_value, y_value])
        ->(x, str) { x.odd? ? str.bg_dark_hl : str.bg_light_hl }
      else
        ->(x, str) { x.odd? ? str.bg_dark : str.bg_light }
      end
    else
      if highlights.member?([x_value, y_value])
        ->(x, str) { x.even? ? str.bg_dark_hl : str.bg_light_hl }
      else
        ->(x, str) { x.even? ? str.bg_dark : str.bg_light }
      end
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
      board.place_piece(pawn, [file, starting_rank])
    end
  end

  def place_pieces(colour)
    starting_rank = colour.eql?(:white) ? 0 : 7
    0.upto(7) do |file|
      piece = file_to_piece(file).new([file, starting_rank], colour, move_list)
      board.place_piece(piece, [file, starting_rank])
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

  private

  attr_reader :move_directions

  public

  def initialize(location, colour, move_list)
    @location = location
    @colour = colour
    @move_list = move_list
  end

  def valid_moves
    transformers = move_list.transformers(move_directions)
    transformers.flat_map { |transformer| search(transformer) }.sort
  end

  private

  def search(transformer)
    move_list.search(location, transformer)
  end
end

class King < Piece
  def initialize(location, colour, move_list)
    super
    @symbol = colour.eql?(:white) ? "♔" : "♚"
    @move_directions = %i[up down left right up_left up_right down_left down_right]
  end

  private

  def search(transformer)
    move_list.search(location, transformer, stop_counter: 1)
  end
end

class Queen < Piece
  def initialize(location, colour, move_list)
    super
    @symbol = colour.eql?(:white) ? "♕" : "♛"
    @move_directions = %i[up down left right up_left up_right down_left down_right]
  end
end

class Rook < Piece
  def initialize(location, colour, move_list)
    super
    @symbol = colour.eql?(:white) ? "♖" : "♜"
    @move_directions = %i[up down left right]
  end
end

class Bishop < Piece
  def initialize(location, colour, move_list)
    super
    @symbol = colour.eql?(:white) ? "♗" : "♝"
    @move_directions = %i[up_left up_right down_left down_right]
  end
end

class Knight < Piece
  def initialize(location, colour, move_list)
    super
    @symbol = colour.eql?(:white) ? "♘" : "♞"
    @move_directions = %i[long_left_up long_up_left long_up_right long_right_up
                     long_right_down long_down_right long_down_left long_left_down]
  end

  private

  def search(transformer)
    move_list.search(location, transformer, stop_counter: 1)
  end
end

class Pawn < Piece
  attr_accessor :moved

  def initialize(location, colour, move_list)
    super
    @symbol = colour.eql?(:white) ? "♙" : "♟"
    @move_directions = [colour.eql?(:white) ? :up : :down]
    @moved = false
  end

  private

  def search(transformer)
    move_count = moved ? 1 : 2
    move_list.search(location, transformer, stop_counter: move_count)
  end
end

class MoveList
  attr_reader :board, :transforms

  def initialize(board)
    @board = board
    @transforms = {
      up: ->(a, b) { [a, b + 1] },
      down: ->(a, b) { [a, b - 1] },
      left: ->(a, b) { [a - 1, b] },
      right: ->(a, b) { [a + 1, b] },
      up_left: ->(a, b) { [a - 1, b + 1] },
      up_right: ->(a, b) { [a + 1, b + 1] },
      down_left: ->(a, b) { [a - 1, b - 1] },
      down_right: ->(a, b) { [a + 1, b - 1] },
      long_left_up: ->(a, b) { [a - 2, b + 1] },
      long_up_left: ->(a, b) { [a - 1, b + 2] },
      long_up_right: ->(a, b) { [a + 1, b + 2] },
      long_right_up: ->(a, b) { [a + 2, b + 1] },
      long_right_down: ->(a, b) { [a + 2, b - 1] },
      long_down_right: ->(a, b) { [a + 1, b - 2] },
      long_down_left: ->(a, b) { [a - 1, b - 2] },
      long_left_down: ->(a, b) { [a - 2, b - 1] }
    }
  end

  def transformers(directions)
    directions.map { |direction| transforms[direction] }
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
    destination = board.lookup_square(dest_coords)
    destination.eql?(:empty) && dest_coords.none?(&:negative?)
  end

  def enemy_piece?(dest_coords, attacker_colour)
    destination = board.lookup_square(dest_coords)
    destination.is_a?(Piece) && !destination.colour.eql?(attacker_colour)
  end
end

# Chess.new
