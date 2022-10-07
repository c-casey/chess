# chess_spec.rb
# frozen_string_literal: true

require_relative "../lib/chess.rb"

describe Board do
end

describe Rook do
  let(:piece) { instance_double("Piece") }
  let(:board) { Board.new }
  let(:move_list) { MoveList.new(board) }
  subject(:rook) { described_class.new([4, 4], :white, move_list) }

  describe "#valid_moves" do
    before do
      board.state[6][4] = piece
      board.state[4][2] = piece
    end

    it "returns all legal movements for a given position" do
      legal_moves = [[4, 5], [4, 6], [4, 7], [0, 4], [1, 4], [2, 4], [3, 4], [5, 4], [4, 3]].sort
      result = rook.valid_moves.sort
      expect(result).to eql(legal_moves)
    end
  end
end

describe Bishop do
  let(:piece) { instance_double("Piece") }
  let(:board) { Board.new }
  let(:move_list) { MoveList.new(board) }
  subject(:bishop) { described_class.new([4, 4], :white, move_list) }

  describe "#valid_moves" do
    before do
      board.state[2][2] = piece
      board.state[7][1] = piece
    end

    it "returns all legal movements for a given position" do
      legal_moves = [[3, 3], [3, 5], [2, 6], [1, 7], [5, 5], [6, 6], [7, 7], [5, 3], [6, 2]].sort
      result = bishop.valid_moves.sort
      expect(result).to eql(legal_moves)
    end
  end
end

describe MoveList do
  let(:board) { Board.new }
  subject(:move_list) { described_class.new(board) }

  describe "#search" do
    context "when searching upward" do
      let(:start_square) { [0, 0] }
      let(:search_lambda) { ->(a, b) { [a, b + 1] } }

      context "when there are no pieces above" do
        it "returns all the squares above" do
          file_full = [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7]]
          result = move_list.search(start_square, search_lambda)
          expect(result).to eql(file_full)
        end
      end

      context "when there is a piece above" do
        let(:piece) { Piece.new([0, 6], :white, move_list) }

        before do
          board.state[0][6] = piece
        end

        it "returns the squares up to the piece" do
          file_upto = [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5]]
          result = move_list.search(start_square, search_lambda)
          expect(result).to eql(file_upto)
        end
      end
    end

    context "when searching downward" do
      let(:start_square) { [0, 7] }
      let(:search_lambda) { ->(a, b) { [a, b - 1] } }

      context "when there are no pieces below" do
        it "returns all the squares below" do
          file_full = [[0, 6], [0, 5], [0, 4], [0, 3], [0, 2], [0, 1], [0, 0]]
          result = move_list.search(start_square, search_lambda)
          expect(result).to eql(file_full)
        end
      end

      context "when there is a piece below" do
        let(:piece) { Piece.new([0, 1], :black, move_list) }

        before do
          board.state[0][1] = piece
        end

        it "returns the squares up to the piece" do
          file_upto = [[0, 6], [0, 5], [0, 4], [0, 3], [0, 2]]
          result = move_list.search(start_square, search_lambda)
          expect(result).to eql(file_upto)
        end
      end
    end

    context "when searching leftward" do
      let(:start_square) { [7, 0] }
      let(:search_lambda) { ->(a, b) { [a - 1, b] } }

      context "when there are no pieces leftward" do
        it "returns all the squares leftward" do
          file_full = [[6, 0], [5, 0], [4, 0], [3, 0], [2, 0], [1, 0], [0, 0]]
          result = move_list.search(start_square, search_lambda)
          expect(result).to eql(file_full)
        end
      end

      context "when there is a piece leftward" do
        let(:piece) { Piece.new([1, 0], :white, move_list) }

        before do
          board.state[1][0] = piece
        end

        it "returns the squares up to the piece" do
          file_upto = [[6, 0], [5, 0], [4, 0], [3, 0], [2, 0]]
          result = move_list.search(start_square, search_lambda)
          expect(result).to eql(file_upto)
        end
      end
    end

    context "when searching rightward" do
      let(:start_square) { [0, 0] }
      let(:search_lambda) { ->(a, b) { [a + 1, b] } }

      context "when there are no pieces rightward" do
        it "returns all the squares rightward" do
          file_full = [[1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0], [7, 0]]
          result = move_list.search(start_square, search_lambda)
          expect(result).to eql(file_full)
        end
      end

      context "when there is a piece rightward" do
        let(:piece) { Piece.new([7, 0], :white, move_list) }

        before do
          board.state[7][0] = piece
        end

        it "returns the squares up to the piece" do
          file_upto = [[1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0]]
          result = move_list.search(start_square, search_lambda)
          expect(result).to eql(file_upto)
        end
      end
    end
  end

  describe "#attacks" do
    context "when searching upward" do
      let(:start_square) { [0, 0] }
      let(:colour) { :white }
      let(:search_lambda) { ->(a, b) { [a, b + 1] } }

      context "when there is no enemy" do
        it "returns nil" do
          result = move_list.attacks(start_square, colour, search_lambda)
          expect(result).to eql(nil)
        end
      end

      context "when there is an enemy" do
        let(:enemy) { Piece.new([0, 5], :black, move_list) }

        before do
          board.state[0][5] = enemy
        end

        it "returns the coords of the enemy" do
          result = move_list.attacks(start_square, colour, search_lambda)
          expect(result).to eql([0, 5])
        end
      end

      context "when there is an enemy behind an ally" do
        let(:enemy) { Piece.new([0, 5], :black, move_list) }
        let(:ally) { Piece.new([0, 4], :white, move_list) }

        before do
          board.state[0][5] = enemy
          board.state[0][4] = ally
        end

        it "returns nil" do
          result = move_list.attacks(start_square, colour, search_lambda)
          expect(result).to eql(nil)
        end
      end
    end
  end
end
