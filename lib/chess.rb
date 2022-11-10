# lib/chess.rb
# frozen_string_literal: true

class String
  def bg_dark =       "\e[41m#{self}\e[0m"
  def bg_light =      "\e[45m#{self}\e[0m"
  def bg_dark_hl =    "\e[44m#{self}\e[0m"
  def bg_light_hl =   "\e[46m#{self}\e[0m"
  def bg_threatened = "\e[31m#{self}\e[0m"
  def bg_selected =   "\e[40m#{self}\e[0m"
end

class Chess
  attr_accessor :current_player, :winner
  attr_reader :board, :move_list, :display

  def initialize(board, move_list, display)
    @board = board
    @move_list = move_list
    @display = display
    @current_player = :white
    @winner = nil
  end

  def setup_board(preparer)
    preparer.new_game
  end

  def game_loop
    until winner
      display.print_board(board)
      take_turn
      check_end_condition
    end
    display.print_board(board)
    winner.eql?(:tie) ? declare_stalemate : declare_checkmate
  end

  private

  def take_turn
    turn_intro_text
    piece = request_origin
    display_moves(piece)
    destination = request_destination(piece)
    return if piece == board.lookup_square(destination)

    piece.move(destination, board)
    swap_players
  end

  def turn_intro_text
    print "Check! " if checked?
    print "Your turn, #{current_player}! "
  end

  def request_origin
    print "Select a piece: "
    piece = board.coords_to_piece(read_selection)
    return piece if valid_piece?(piece)

    print "Invalid selection! "
    request_origin
  end

  def display_moves(piece)
    display.print_board(board, piece.valid_moves_and_attacks(board))
  end

  def request_destination(piece)
    print "Select a destination, or select currently highlighted piece to choose a different one: "
    destination = board.coords_to_location(read_selection)
    return destination if valid_move?(piece, destination)
    return destination if piece.location.eql?(destination)

    print "Invalid move! "
    request_destination(piece)
  end

  def read_selection
    selection = $stdin.gets.chomp.downcase
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

  def valid_move?(piece, destination)
    piece.valid_moves_and_attacks(board).member?(destination)
  end

  def swap_players
    self.current_player = opponent
  end

  def opponent
    current_player.eql?(:white) ? :black : :white
  end

  def checked?
    board.player_pieces(opponent).any? { |piece| piece.check?(board) }
  end

  def check_end_condition
    return if board.valid_moves?(current_player)

    self.winner = checked? ? opponent : :tie
  end

  def declare_checkmate
    puts "Checkmate! #{winner.capitalize} wins!"
  end

  def declare_stalemate
    puts "Stalemate!"
  end
end

class Board
  private

  attr_accessor :state

  public

  def initialize(state: nil)
    @state = state || Array.new(8) { Array.new(8, :empty) }
  end

  def player_pieces(colour)
    all_pieces.find_all { |e| e.colour.eql?(colour) }
  end

  def lookup_square(coords)
    state.dig(*coords)
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
    row = piece.location[1]
    check_castle(piece, row, dest) if piece.is_a?(King)
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

  def age_pieces(colour)
    rank = colour.eql?(:white) ? 3 : 4
    0.upto(7) do |file|
      piece = lookup_square([file, rank])
      piece.moved = true if piece.is_a?(Pawn)
    end
  end

  def move_into_check?(origin, dest)
    mover = lookup_square(origin)
    board_copy = Board.new(state: copy_state)
    board_copy.move_piece(origin, dest)
    enemies = board_copy.player_pieces(mover.colour.eql?(:white) ? :black : :white)
    test = enemies.any? { |e| e.check?(board_copy) }
    # require 'pry-byebug'; binding.pry if test == false

  end

  def valid_moves?(colour)
    player_pieces(colour).any? do |piece|
      moves = piece.valid_moves_and_attacks(self)
      moves_minus_location = moves.reject { |move| move == piece.location }
      moves_minus_location.length.positive?
    end
  end

  private

  def copy_state
    state_copy = []
    0.upto(7) do |i|
      file_copy = state[i].map(&:clone)
      state_copy << file_copy
    end
    state_copy
  end

  def all_pieces
    all_squares.find_all { |e| e.is_a?(Piece) }
  end

  def all_squares
    result = []
    0.upto(7) do |y|
      result += state[y]
    end
    result
  end

  def check_castle(piece, row, dest)
    if castle_short?(piece, row, dest)
      castle_rook_short(row)
    elsif castle_long?(piece, row, dest)
      castle_rook_long(row)
    end
  end

  def castle_short?(piece, row, dest)
    rook_coords = [7, row]
    maybe_rook = lookup_square(rook_coords)

    dest == [6, row] &&
      piece.moved == false &&
      maybe_rook.is_a?(Rook) &&
      maybe_rook.moved == false &&
      (5..6).map { |i| lookup_square([i, row]) }.all? { |e| e.eql?(:empty) }
  end

  def castle_long?(piece, row, dest)
    rook_coords = [0, row]
    maybe_rook = lookup_square(rook_coords)

    dest == [2, row] &&
      piece.moved == false &&
      maybe_rook.is_a?(Rook) &&
      maybe_rook.moved == false &&
      (1..3).map { |i| lookup_square([i, row]) }.all? { |e| e.eql?(:empty) }
  end

  def castle_rook_short(row)
    rook_coords = [7, row]
    move_piece(rook_coords, [5, row])
    clear_square(rook_coords)
  end

  def castle_rook_long(row)
    rook_coords = [0, row]
    move_piece(rook_coords, [3, row])
    clear_square(rook_coords)
  end
end

class Display
  def print_board(board, highlights = [])
    clear_window
    puts "\n\n\t  A B C D E F G H"
    7.downto(0) do |y|
      print_row(y, board, highlights)
    end
    puts "\t  A B C D E F G H\n\n"
  end

  private

  def clear_window
    puts "\e[H\e[2J"
  end

  def print_row(y, board, highlights)
    print "\t#{y + 1} "
    0.upto(7) do |x|
      square_contents = board.lookup_square([x, y])
      symbol = square_contents.eql?(:empty) ? "  " : "#{square_contents.symbol} "
      colour_lambda = colour_picker(x, y, board, highlights)
      colour_print = colour_lambda.call(x, symbol)
      print colour_print
    end
    puts " #{y + 1}"
  end

  def colour_picker(x_value, y_value, board, highlights)
    if highlights.member?([x_value, y_value]) && board.lookup_square([x_value, y_value]).is_a?(Piece)
      ->(_x, str) { str.bg_threatened }
    elsif y_value.odd?
      odd_colour_picker(x_value, y_value, highlights)
    else
      even_colour_picker(x_value, y_value, highlights)
    end
  end

  def odd_colour_picker(x_value, y_value, highlights)
    if highlights.member?([x_value, y_value])
      ->(x, str) { x.odd? ? str.bg_dark_hl : str.bg_light_hl }
    else
      ->(x, str) { x.odd? ? str.bg_dark : str.bg_light }
    end
  end

  def even_colour_picker(x_value, y_value, highlights)
    if highlights.member?([x_value, y_value])
      ->(x, str) { x.even? ? str.bg_dark_hl : str.bg_light_hl }
    else
      ->(x, str) { x.even? ? str.bg_dark : str.bg_light }
    end
  end

  def threatened_piece?(x_value, y_value, board, highlights)
    highlights.member?([x_value, y_value]) &&
      board.lookup_square([x_value, y_value]).is_a?(Piece)
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

  attr_reader :move_directions, :attack_directions

  public

  def initialize(location, colour, move_list)
    @location = location
    @colour = colour
    @move_list = move_list
  end

  def moves(board)
    transformers = move_list.transformers(move_directions)
    transformers.flat_map { |transformer| move_search(transformer, board) }.sort
  end

  def attacks(board)
    transformers = move_list.transformers(attack_directions)
    transformers.flat_map { |transformer| attack_search(transformer, board) }.sort
  end

  def move(destination, board)
    board.move_piece(location, destination)
    age_opponent_pieces(board)
  end

  def check?(board)
    attacks(board).any? { |coords| board.lookup_square(coords).is_a?(King) }
  end

  def valid_moves_and_attacks(board)
    moves_and_attacks = moves(board) + attacks(board)
    remove_self_checking_moves(moves_and_attacks, board)
  end

  private

  def remove_self_checking_moves(moves_and_attacks, board)
    moves_and_attacks.reject { |dest| board.move_into_check?(location, dest) }
  end

  def move_search(transformer, board)
    move_list.move_search(location, transformer, board)
  end

  def attack_search(transformer, board)
    move_list.attack_search(location, colour, transformer, board)
  end

  def age_opponent_pieces(board)
    opponent_colour = colour.eql?(:white) ? :black : :white
    board.age_pieces(opponent_colour)
  end
end

class King < Piece
  attr_accessor :moved

  def initialize(location, colour, move_list)
    super
    @symbol = colour.eql?(:white) ? "♔" : "♚"
    @move_directions = %i[up down left right up_left up_right down_left down_right]
    @attack_directions = move_directions
    @moved = false
  end

  def moves(board)
    transformers = move_list.transformers(move_directions)
    transformers += move_list.transformers([:castle_short]) if move_list.castle_short?(self, location[1], board)
    transformers += move_list.transformers([:castle_long]) if move_list.castle_long?(self, location[1], board)
    transformers.flat_map { |transformer| move_search(transformer, board) }.sort
  end

  private

  def move_search(transformer, board)
    move_list.move_search(location, transformer, board, stop_counter: 1)
  end

  def attack_search(transformer, board)
    move_list.attack_search(location, colour, transformer, board, stop_counter: 1)
  end
end

class Queen < Piece
  def initialize(location, colour, move_list)
    super
    @symbol = colour.eql?(:white) ? "♕" : "♛"
    @move_directions = %i[up down left right up_left up_right down_left down_right]
    @attack_directions = move_directions
  end

  # def attack_search(transformer, board)
  #   require 'pry-byebug'; binding.pry if board.lookup_square([7,4]).is_a?(Queen)
  #   super
  # end
end

class Rook < Piece
  attr_accessor :moved

  def initialize(location, colour, move_list)
    super
    @symbol = colour.eql?(:white) ? "♖" : "♜"
    @move_directions = %i[up down left right]
    @attack_directions = move_directions
    @moved = false
  end
end

class Bishop < Piece
  def initialize(location, colour, move_list)
    super
    @symbol = colour.eql?(:white) ? "♗" : "♝"
    @move_directions = %i[up_left up_right down_left down_right]
    @attack_directions = move_directions
  end
end

class Knight < Piece
  def initialize(location, colour, move_list)
    super
    @symbol = colour.eql?(:white) ? "♘" : "♞"
    @move_directions = %i[long_left_up long_up_left long_up_right long_right_up
                          long_right_down long_down_right long_down_left long_left_down]
    @attack_directions = move_directions
  end

  private

  def move_search(transformer, board)
    move_list.move_search(location, transformer, board, stop_counter: 1)
  end

  def attack_search(transformer, board)
    move_list.attack_search(location, colour, transformer, board, stop_counter: 1)
  end
end

class Pawn < Piece
  attr_accessor :moved

  def initialize(location, colour, move_list)
    super
    @symbol = colour.eql?(:white) ? "♙" : "♟"
    @move_directions = [colour.eql?(:white) ? :up : :down]
    @attack_directions = colour.eql?(:white) ? %i[up_left up_right] : %i[down_left down_right]
    @moved = false
  end

  def location=(location)
    self.moved = moved.eql?(false) ? :last : true
    @location = location
  end

  def attacks(board)
    transformers = move_list.transformers(attack_directions)
    transformers += move_list.transformers([:left]) if move_list.en_passant?(self, :left, board)
    transformers += move_list.transformers([:right]) if move_list.en_passant?(self, :right, board)
    transformers.flat_map { |transformer| attack_search(transformer, board) }.sort
  end

  def move(destination, board)
    board.clear_square(destination)
    destination = adjust_move_y(destination) if en_passant?(destination)
    super
  end

  private

  def adjust_move_y(dest)
    transformer = move_list.transforms[*move_directions]
    transformer.call(*dest)
  end

  def en_passant?(dest)
    leftward = move_list.transforms[:left]
    rightward = move_list.transforms[:right]
    (leftward.call(*location) == dest || rightward.call(*location) == dest) &&
      (location[1] == 3 || location[1] == 4)
  end

  def move_search(transformer, board)
    move_count = moved ? 1 : 2
    move_list.move_search(location, transformer, board, stop_counter: move_count)
  end

  def attack_search(transformer, board)
    move_list.attack_search(location, colour, transformer, board, stop_counter: 1)
  end
end

class MoveList
  attr_reader :transforms

  def initialize
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
      long_left_down: ->(a, b) { [a - 2, b - 1] },
      castle_short: ->(a, b) { [a + 2, b] },
      castle_long: ->(a, b) { [a - 2, b] }
    }
  end

  def inspect
    "MoveList"
  end

  def transformers(directions)
    directions.flat_map { |direction| transforms[direction] }
  end

  def move_search(coords, search_lambda, board, results = [], stop_counter: nil)
    return results if stop_counter&.zero?

    dest_coords = search_lambda.call(coords[0], coords[1])
    return results if dest_coords.any?(&:negative?)

    if traversible_space?(dest_coords, board)
      results << dest_coords
      move_search(dest_coords, search_lambda, board, results, stop_counter: stop_counter&.pred)
    else
      results
    end
  end

  def attack_search(coords, colour, search_lambda, board, results = [], stop_counter: nil)
    return results if stop_counter&.zero?

    dest_coords = search_lambda.call(coords[0], coords[1])
    return results if dest_coords.any?(&:negative?)

    if enemy_piece?(dest_coords, colour, board)
      results << dest_coords
    elsif traversible_space?(dest_coords, board)
      attack_search(dest_coords, colour, search_lambda, board, results, stop_counter: stop_counter&.pred)
    else
      results
    end
  end

  def castle_short?(piece, row, board)
    rook_coords = [7, row]
    maybe_rook = board.lookup_square(rook_coords)

    piece.moved == false &&
      maybe_rook.is_a?(Rook) &&
      maybe_rook.moved == false &&
      (5..6).map { |i| board.lookup_square([i, row]) }.all? { |e| e.eql?(:empty) }
  end

  def castle_long?(piece, row, board)
    rook_coords = [0, row]
    maybe_rook = board.lookup_square(rook_coords)

    piece.moved == false &&
      maybe_rook.is_a?(Rook) &&
      maybe_rook.moved == false &&
      (1..3).map { |i| board.lookup_square([i, row]) }.all? { |e| e.eql?(:empty) }
  end

  def en_passant?(piece, direction, board)
    transform = transforms[direction]
    side_square = transform.call(*piece.location)
    contents = board.lookup_square(side_square)
    contents.is_a?(Pawn) && contents.moved.eql?(:last) &&
      (side_square[1] == 3 || side_square[1] == 4)
  end

  private

  def traversible_space?(dest_coords, board)
    destination = board.lookup_square(dest_coords)
    destination.eql?(:empty) && dest_coords.none?(&:negative?)
  end

  def enemy_piece?(dest_coords, attacker_colour, board)
    destination = board.lookup_square(dest_coords)
    destination.is_a?(Piece) && !destination.colour.eql?(attacker_colour)
  end
end

board = Board.new
move_list = MoveList.new
display = Display.new
setup = BoardSetup.new(board, move_list)
chess = Chess.new(board, move_list, display)

chess.setup_board(setup)
chess.game_loop
