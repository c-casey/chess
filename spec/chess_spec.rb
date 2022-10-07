# chess_spec.rb
# frozen_string_literal: true

require_relative "../lib/chess.rb"

describe Board do
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
end
