# lib/start.rb
# frozen_string_literal: true

require_relative "chess"

chess = Chess.new(Board.new, MoveList.new, Display.new)

chess.setup_board(BoardSetup)
chess.game_loop
