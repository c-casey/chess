# chess_spec.rb
# frozen_string_literal: true

require_relative "../lib/chess.rb"

describe Board do
end

describe Rook do
  let(:board) { Board.new }

  describe "#search_up" do
    subject(:rook) { described_class.new([0, 0], :white) }

    context "when there are no pieces above" do
      it "returns all the squares above" do
        file_full = [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7]]
        result = rook.search_up(board)
        expect(result).to eql(file_full)
      end
    end

    context "when there is a friendly piece above" do
      let(:friendly_piece) { described_class.new([0, 6], :white) }

      before do
        board.state[0][6] = friendly_piece
      end

      it "returns the file up to the friendly piece" do
        file_upto = [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5]]
        result = rook.search_up(board)
        expect(result).to eql(file_upto)
      end
    end
  end

  describe "#search_down" do
    subject(:rook) { described_class.new([0, 7], :white) }

    context "when there are no pieces below" do
      it "returns all the squares below" do
        file_full = [[0, 6], [0, 5], [0, 4], [0, 3], [0, 2], [0, 1], [0, 0]]
        result = rook.search_down(board)
        expect(result).to eql(file_full)
      end
    end

    context "when there is a friendly piece below" do
      let(:friendly_piece) { described_class.new([0, 1], :white) }

      before do
        board.state[0][1] = friendly_piece
      end

      it "returns the file up to the friendly piece" do
        file_upto = [[0, 6], [0, 5], [0, 4], [0, 3], [0, 2]]
        result = rook.search_down(board)
        expect(result).to eql(file_upto)
      end
    end
  end

  describe "#search_left" do
    subject(:rook) { described_class.new([7, 0], :white) }

    context "when there are no pieces leftward" do
      it "returns all the squares leftward" do
        file_full = [[6, 0], [5, 0], [4, 0], [3, 0], [2, 0], [1, 0], [0, 0]]
        result = rook.search_left(board)
        expect(result).to eql(file_full)
      end
    end

    context "when there is a friendly piece leftward" do
      let(:friendly_piece) { described_class.new([1, 0], :white) }

      before do
        board.state[1][0] = friendly_piece
      end

      it "returns the file up to the friendly piece" do
        file_upto = [[6, 0], [5, 0], [4, 0], [3, 0], [2, 0]]
        result = rook.search_left(board)
        expect(result).to eql(file_upto)
      end
    end
  end

  describe "#search_right" do
    subject(:rook) { described_class.new([0, 0], :white) }

    context "when there are no pieces rightward" do
      it "returns all the squares rightward" do
        file_full = [[1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0], [7, 0]]
        result = rook.search_right(board)
        expect(result).to eql(file_full)
      end
    end

    context "when there is a friendly piece rightward" do
      let(:friendly_piece) { described_class.new([7, 0], :white) }

      before do
        board.state[7][0] = friendly_piece
      end

      it "returns the file up to the friendly piece" do
        file_upto = [[1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0]]
        result = rook.search_right(board)
        expect(result).to eql(file_upto)
      end
    end
  end
end
