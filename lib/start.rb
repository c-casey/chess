# lib/start.rb
# frozen_string_literal: true

require_relative "chess"

chess = Chess.new(Board.new, MoveList.new, Display.new)
setup = BoardSetup.new(chess.board, chess.move_list)

chess.setup_board(setup)
chess.game_loop
