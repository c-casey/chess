# lib/chess.rb
# frozen_string_literal: true

require "msgpack"
MessagePack::DefaultFactory.register_type(0x00, Symbol)

class String
  def bg_dark;        "\e[41m#{self}\e[0m" end
  def bg_light;       "\e[45m#{self}\e[0m" end
  def bg_dark_hl;     "\e[44m#{self}\e[0m" end
  def bg_light_hl;    "\e[46m#{self}\e[0m" end
  def bg_threatened;  "\e[31m#{self}\e[0m" end
  def bg_selected;     "\e[7m#{self}\e[0m" end
end

class Chess
  attr_accessor :current_player, :winner, :board
  attr_reader :move_list, :display

  def initialize
    @board = BoardSetup.new.new_game
    @move_list = MoveList.new
    @display = Display.new
    @current_player = :white
    @winner = nil
  end

  def game_loop
    until winner
      display.print_board(board)
      take_turn
      check_end_condition
    end
    display.print_board(board)
    determine_end_state(winner)
  end

  def take_turn
    turn_intro_text
    return if player_choice.eql?(:restart)

    swap_players
  end

  def player_choice
    choice = request_choice
    choice.is_a?(Piece) ? piece_action(choice) : game_action(choice)
  end

  def piece_action(piece)
    display_moves(piece)
    destination = request_destination(piece)
    return :restart if piece == board.lookup_square(destination)

    piece.move(destination, board)
    promote(piece) if promotable_pawn?(piece)
  end

  def game_action(choice)
    send(choice)
    :restart
  end

  def check_end_condition
    return if board.valid_moves?(current_player)

    self.winner = board.checked?(current_player) ? opponent : :tie
  end

  private

  def turn_intro_text
    print "Check! " if board.checked?(current_player)
    print "Your turn, #{current_player}! "
  end

  def request_choice
    print "Select a piece, or 'resign'/'draw'/'save'/'load'/'quit': "
    handle_choice(read_choice)
  end

  def read_choice
    selection = $stdin.gets.chomp.downcase
    return selection if valid_option?(selection)

    print "Invalid selection! Try again: "
    read_choice
  end

  def handle_choice(selection)
    if %w[draw resign save load quit].member?(selection)
      selection.to_sym
    else
      find_piece(selection)
    end
  end

  def find_piece(selection)
    piece = board.coords_to_piece(selection)
    return piece if valid_piece?(piece)

    print "Invalid selection! "
    request_choice
  end

  def draw
    print "#{opponent.capitalize}, agree to draw? [y/n]: "
    confirm_flag_set(:draw)
  end

  def resign
    print "#{current_player.capitalize}, are you sure you wish to resign? [y/n]: "
    confirm_flag_set(:resign)
  end

  def save
    SaveData.new.save(board)
  end

  def load
    result = SaveData.new.load
    return result if result == :restart

    self.board = result
  end

  def quit
    print "Really quit? Unsaved progress will be lost! [y to confirm]: "
    abort("Thanks for playing!") if $stdin.gets.chomp.downcase == "y"
  end

  def confirm_flag_set(flag)
    choice = $stdin.gets.chomp.downcase
    case choice
    when "y"
      self.winner = flag
    when "n"
      :restart
    else
      print "Invalid input! "
      resign
    end
  end

  def promote(pawn)
    piece_class = request_promotion_piece
    piece = piece_class.new(pawn.location, current_player, move_list)
    board.place_piece(piece, piece.location)
  end

  def promotable_pawn?(piece)
    piece.is_a?(Pawn) && crossed_board?(piece)
  end

  def crossed_board?(piece)
    finish_rank = current_player.eql?(:white) ? 7 : 0
    piece.location[1].eql?(finish_rank)
  end

  def request_promotion_piece
    print "Select a piece to trade for [Q, R, B, N]: "
    response = read_promotion_piece
    lookup_promotion_piece(response)
  end

  def read_promotion_piece
    piece = $stdin.gets.chomp.downcase
    return piece if valid_promotion_piece?(piece)

    print "Invalid selection! "
    read_promotion_piece
  end

  def lookup_promotion_piece(string)
    case string
    when "q"
      Queen
    when "r"
      Rook
    when "b"
      Bishop
    when "n"
      Knight
    end
  end

  def valid_promotion_piece?(piece)
    %w[q r b n].member?(piece)
  end

  def display_moves(piece)
    display.print_board(board, piece.valid_moves_and_attacks(board), piece.location)
  end

  def request_destination(piece)
    print "Select a destination, or select currently highlighted piece to choose a different one: "
    destination = board.coords_to_location(read_destination)
    return destination if valid_move?(piece, destination) ||
                          piece.location.eql?(destination)

    print "Invalid move! "
    request_destination(piece)
  end

  def read_destination
    selection = $stdin.gets.chomp.downcase
    return selection if coord_input?(selection)

    print "Invalid selection! Try again: "
    read_destination
  end

  def valid_option?(selection)
    coord_input?(selection) ||
      selection == "resign" ||
      selection == "draw"   ||
      selection == "save"   ||
      selection == "load"   ||
      selection == "quit"
  end

  def coord_input?(selection)
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

  def determine_end_state(winner)
    case winner
    when :tie
      declare_stalemate
    when :draw
      declare_draw
    when :resign
      declare_resignation
    else
      declare_checkmate
    end
  end

  def declare_checkmate
    puts "Checkmate! #{winner.capitalize} wins!"
  end

  def declare_stalemate
    puts "Stalemate!"
  end

  def declare_draw
    puts "Draw!"
  end

  def declare_resignation
    puts "#{opponent.capitalize} wins by resignation!"
  end
end

class SaveData
  def save_path
    File.join(File.dirname(__FILE__), "/save_data/")
  end

  def save(board)
    board_packed = board.copy_state.map do |file|
      file.map(&:to_msgpack)
    end.to_msgpack
    write_save(request_save_name, board_packed)
  end

  def write_save(name, data)
    Dir.mkdir(save_path) unless Dir.exist?(save_path)
    Dir.chdir(save_path) do
      File.binwrite("#{name}.dat", data)
    end
  end

  def request_save_name
    print "Save name [alphanumeric]: "
    name = $stdin.gets.chomp
    return name if name =~ /^\p{Alnum}+$/

    puts "Special chars not allowed! "
    request_save_name
  end

  def load
    saves = save_files
    list_files(saves)
    name = select_save_file(saves)
    return :restart unless name

    file_path = File.join(save_path, "#{name}.dat")
    selected_save = File.binread(file_path)
    unpacked_save = unpack_save(selected_save)
    BoardSetup.new.generate_board_from(unpacked_save)
  end

  def save_files
    files = Dir.children(save_path)
    files.select { |e| e.split(".").last == "dat" }
  end

  def list_files(files)
    1.upto(files.length) { |i| puts "[#{i}] #{files[i - 1]}" }
  end

  def select_save_file(saves)
    print "Enter a number to load, or 'back' to return: "
    number = gets.chomp.downcase
    return false if number == "back"
    return saves[number.to_i.pred].split(".").first if valid_save_number?(number, saves)

    print "Invalid selection! "
    select_save_file(saves)
  end

  def valid_save_number?(number, save_array)
    number =~ /^\d+$/ && number.to_i <= save_array.length && number.to_i.positive?
  end

  def unpack_save(save)
    semi_unpacked = MessagePack.unpack(save)
    semi_unpacked.map { |file| file.map { |square| MessagePack.unpack(square) } }
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
    rank = piece.location[1]
    check_castle(piece, rank, dest) if piece.is_a?(King)
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
    enemies.any? { |e| e.check?(board_copy) }
  end

  def valid_moves?(colour)
    player_pieces(colour).any? do |piece|
      moves = piece.valid_moves_and_attacks(self)
      moves_minus_location = moves.reject { |move| move == piece.location }
      moves_minus_location.length.positive?
    end
  end

  def checked?(current_player)
    opponent = current_player.eql?(:white) ? :black : :white
    player_pieces(opponent).any? { |piece| piece.check?(self) }
  end

  def castle_short?(king, rank)
    maybe_rook = lookup_square([7, rank])
    range_empty?(5, 6, rank) && castleable?(king, maybe_rook)
  end

  def castle_long?(king, rank)
    maybe_rook = lookup_square([0, rank])
    range_empty?(1, 3, rank) && castleable?(king, maybe_rook)
  end

  def copy_state
    state_copy = []
    0.upto(7) do |i|
      file_copy = state[i].map(&:clone)
      state_copy << file_copy
    end
    state_copy
  end

  def to_msgpack(_arg)
    array = []
    0.upto(7) do |i|
      file_copy = state[i].to_msgpack
      array << file_copy
    end
    array
  end

  private

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

  def check_castle(king, rank, dest)
    if castle_short?(king, rank) && dest == [6, rank]
      castle_rook(rank, 7, 5)
    elsif castle_long?(king, rank) && dest == [2, rank]
      castle_rook(rank, 0, 3)
    end
  end

  def castleable?(king, maybe_rook)
    maybe_rook.is_a?(Rook) &&
      !king.moved &&
      !checked?(king.colour) &&
      !maybe_rook.moved
  end

  def range_empty?(lower, upper, rank)
    (lower..upper).map { |i| lookup_square([i, rank]) }.all? { |e| e.eql?(:empty) }
  end

  def castle_rook(rank, origin_file, dest_file)
    rook_coords = [origin_file, rank]
    move_piece(rook_coords, [dest_file, rank])
  end
end

class Display
  def print_board(board, highlights = [], selected = [])
    clear_window
    puts "\n\n\t  A B C D E F G H"
    7.downto(0) do |y|
      print_rank(y, board, highlights, selected)
    end
    puts "\t  A B C D E F G H\n\n"
  end

  private

  def clear_window
    puts "\e[H\e[2J"
  end

  def print_rank(y, board, highlights, selected)
    print "\t#{y + 1} "
    0.upto(7) do |x|
      square_contents = board.lookup_square([x, y])
      symbol = square_contents.eql?(:empty) ? "  " : "#{square_contents.symbol} "
      colour_lambda = colour_picker(x, y, board, highlights, selected)
      colour_print = colour_lambda.call(x, symbol)
      print colour_print
    end
    puts " #{y + 1}"
  end

  def colour_picker(x_value, y_value, board, highlights, selected)
    if selected.eql?([x_value, y_value])
      ->(_x, str) { str.bg_selected }
    elsif highlights.member?([x_value, y_value]) && board.lookup_square([x_value, y_value]).is_a?(Piece)
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
  attr_reader :move_list

  def initialize
    @move_list = MoveList.new
  end

  def new_game
    board = Board.new
    place_pawns(:white, board)
    place_pieces(:white, board)
    place_pawns(:black, board)
    place_pieces(:black, board)
    board
  end

  def place_pawns(colour, board)
    starting_rank = colour.eql?(:white) ? 1 : 6
    0.upto(7) do |file|
      pawn = Pawn.new([file, starting_rank], colour, move_list)
      board.place_piece(pawn, [file, starting_rank])
    end
  end

  def place_pieces(colour, board)
    starting_rank = colour.eql?(:white) ? 0 : 7
    0.upto(7) do |file|
      piece = file_to_piece(file).new([file, starting_rank], colour, move_list)
      board.place_piece(piece, [file, starting_rank])
    end
  end

  def generate_board_from(array)
    state = array.map do |file|
      file.map do |square|
        if square.is_a?(Hash)
          piece_type = square[:piece_type]
          class_name = MessagePack.unpack(piece_type)
          initialize_piece(class_name, square)
        else
          square
        end
      end
    end
    Board.new(state: state)
  end

  def initialize_piece(piece_type, obj)
    location = unpack(obj, :@location)
    colour = unpack(obj, :@colour)
    piece = Object.const_get(piece_type).new(location, colour, move_list)
    piece.moved = unpack(obj, :@moved) if piece.instance_variables.member?(:@moved)
    piece
  end

  def unpack(obj, variable)
    MessagePack.unpack(obj[variable])
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

  def to_msgpack
    piece = {}
    piece[:piece_type] = self.class.name.to_msgpack
    instance_variables.map do |var|
      piece[var] = instance_variable_get(var).to_msgpack
    end
    MessagePack.dump(piece)
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
    transformers += move_list.transformers([:castle_short]) if board.castle_short?(self, location[1])
    transformers += move_list.transformers([:castle_long]) if board.castle_long?(self, location[1])
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

  def to_msgpack
    MessagePack.dump(self.class.to_s)
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
