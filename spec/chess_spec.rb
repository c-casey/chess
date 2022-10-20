# chess_spec.rb
# frozen_string_literal: true

require_relative "../lib/chess"

describe Board do
  subject(:board) { described_class.new }
  let(:move_list) { double("MoveList") }
  let(:piece) { Piece.new([0, 0], :white, move_list) }

  describe "#move_piece" do
    before do
      board.place_piece(piece, [0, 0])
      board.move_piece([0, 0], [4, 6])
    end

    it "moves a piece" do
      result = board.lookup_square([4, 6])
      expect(result).to be_an_instance_of(Piece)
    end

    it "updates the piece's location variable" do
      location = board.lookup_square([4, 6]).location
      expect(location).to eql([4, 6])
    end
  end
end

describe BoardSetup do
  let(:board) { Board.new }
  let(:move_list) { MoveList.new(board) }
  subject(:setup) { described_class.new(board, move_list) }

  describe "#place_pawns" do
    it "places white pawns" do
      setup.place_pawns(:white)
      results = (0..7).map { |n| board.lookup_square([n, 1]) }
      expect(results).to all(be_an_instance_of(Pawn))
    end

    it "places black pawns" do
      setup.place_pawns(:black)
      results = (0..7).map { |n| board.lookup_square([n, 6]) }
      expect(results).to all(be_an_instance_of(Pawn))
    end
  end

  describe "#place_pieces" do
    let(:piece_order) { [Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook] }

    it "places white pieces" do
      setup.place_pieces(:white)
      results = (0..7).map { |n| board.lookup_square([n, 0]).class }
      expect(results).to eql(piece_order)
    end

    it "places black pieces" do
      setup.place_pieces(:black)
      results = (0..7).map { |n| board.lookup_square([n, 7]).class }
      expect(results).to eql(piece_order)
    end
  end
end

describe King do
  let(:piece) { instance_double("Piece") }
  let(:board) { Board.new }
  let(:move_list) { MoveList.new(board) }
  subject(:king) { described_class.new([4, 4], :white, move_list) }

  describe "#valid_moves" do
    before do
      board.place_piece(piece, [3, 4])
      board.place_piece(piece, [4, 5])
      board.place_piece(piece, [5, 3])
    end

    it "returns all legal movements for a given position" do
      legal_moves = [[3, 3], [3, 5], [4, 3], [5, 4], [5, 5]]
      result = king.valid_moves
      expect(result).to eql(legal_moves)
    end
  end
end

describe Queen do
  let(:piece) { instance_double("Piece") }
  let(:board) { Board.new }
  let(:move_list) { MoveList.new(board) }
  subject(:queen) { described_class.new([4, 4], :white, move_list) }

  describe "#valid_moves" do
    before do
      board.place_piece(piece, [2, 4])
      board.place_piece(piece, [4, 5])
      board.place_piece(piece, [5, 3])
      board.place_piece(piece, [1, 1])
    end

    it "returns all legal movements for a given position" do
      legal_moves = [[1, 7], [2, 2], [2, 6], [3, 3], [3, 4], [3, 5], [4, 0], [4, 1],
                     [4, 2], [4, 3], [5, 4], [5, 5], [6, 4], [6, 6], [7, 4], [7, 7]]
      result = queen.valid_moves
      expect(result).to eql(legal_moves)
    end
  end
end

describe Rook do
  let(:piece) { instance_double("Piece") }
  let(:board) { Board.new }
  let(:move_list) { MoveList.new(board) }
  subject(:rook) { described_class.new([4, 4], :white, move_list) }

  describe "#valid_moves" do
    before do
      board.place_piece(piece, [6, 4])
      board.place_piece(piece, [4, 2])
    end

    it "returns all legal movements for a given position" do
      legal_moves = [[0, 4], [1, 4], [2, 4], [3, 4], [4, 3], [4, 5], [4, 6], [4, 7], [5, 4]]
      result = rook.valid_moves
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
      board.place_piece(piece, [2, 2])
      board.place_piece(piece, [7, 1])
    end

    it "returns all legal movements for a given position" do
      legal_moves = [[1, 7], [2, 6], [3, 3], [3, 5], [5, 3], [5, 5], [6, 2], [6, 6], [7, 7]]
      result = bishop.valid_moves
      expect(result).to eql(legal_moves)
    end
  end
end

describe Knight do
  let(:piece) { instance_double("Piece") }
  let(:board) { Board.new }
  let(:move_list) { MoveList.new(board) }
  subject(:knight) { described_class.new([4, 4], :white, move_list) }

  describe "#valid_moves" do
    before do
      board.place_piece(piece, [3, 6])
      board.place_piece(piece, [2, 3])
    end

    it "returns all legal movements for a given position" do
      legal_moves = [[2, 5], [3, 2], [5, 2], [5, 6], [6, 3], [6, 5]]
      result = knight.valid_moves
      expect(result).to eql(legal_moves)
    end
  end
end

describe Pawn do
  let(:piece) { instance_double("Piece") }
  let(:board) { Board.new }
  let(:move_list) { MoveList.new(board) }

  describe "#valid_moves" do
    context "when white Pawn hasn't moved yet" do
      subject(:pawn) { described_class.new([0, 1], :white, move_list) }

      context "when free to move" do
        it "returns two legal moves" do
          legal_moves = [[0, 2], [0, 3]]
          result = pawn.valid_moves
          expect(result).to eql(legal_moves)
        end
      end

      context "when blocked by a piece 2 squares away" do
        before do
          board.place_piece(piece, [0, 3])
        end

        it "returns one legal move" do
          legal_moves = [[0, 2]]
          result = pawn.valid_moves
          expect(result).to eql(legal_moves)
        end
      end

      context "when blocked by a piece 1 square away" do
        before do
          board.place_piece(piece, [0, 2])
        end

        it "returns no legal moves" do
          legal_moves = []
          result = pawn.valid_moves
          expect(result).to eql(legal_moves)
        end
      end
    end

    context "when black Pawn has already moved" do
      subject(:pawn) { described_class.new([0, 7], :black, move_list) }

      before do
        pawn.moved = true
      end

      context "when free to move" do
        it "returns one legal move" do
          legal_moves = [[0, 6]]
          result = pawn.valid_moves
          expect(result).to eql(legal_moves)
        end
      end

      context "when blocked by a piece" do
        before do
          board.place_piece(piece, [0, 6])
        end

        it "returns no legal moves" do
          legal_moves = []
          result = pawn.valid_moves
          expect(result).to eql(legal_moves)
        end
      end
    end
  end
end

describe MoveList do
  let(:board) { Board.new }
  subject(:move_list) { described_class.new(board) }

  describe "#move_search" do
    context "when searching upward" do
      let(:start_square) { [0, 0] }
      let(:search_lambda) { ->(a, b) { [a, b + 1] } }

      context "when there are no pieces above" do
        it "returns all the squares above" do
          file_full = [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7]]
          result = move_list.move_search(start_square, search_lambda)
          expect(result).to eql(file_full)
        end
      end

      context "when there is a piece above" do
        let(:piece) { Piece.new([0, 6], :white, move_list) }

        before do
          board.place_piece(piece, [0, 6])
        end

        it "returns the squares up to the piece" do
          file_upto = [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5]]
          result = move_list.move_search(start_square, search_lambda)
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
          result = move_list.move_search(start_square, search_lambda)
          expect(result).to eql(file_full)
        end
      end

      context "when there is a piece below" do
        let(:piece) { Piece.new([0, 1], :black, move_list) }

        before do
          board.place_piece(piece, [0, 1])
        end

        it "returns the squares up to the piece" do
          file_upto = [[0, 6], [0, 5], [0, 4], [0, 3], [0, 2]]
          result = move_list.move_search(start_square, search_lambda)
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
          result = move_list.move_search(start_square, search_lambda)
          expect(result).to eql(file_full)
        end
      end

      context "when there is a piece leftward" do
        let(:piece) { Piece.new([1, 0], :white, move_list) }

        before do
          board.place_piece(piece, [1, 0])
        end

        it "returns the squares up to the piece" do
          file_upto = [[6, 0], [5, 0], [4, 0], [3, 0], [2, 0]]
          result = move_list.move_search(start_square, search_lambda)
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
          result = move_list.move_search(start_square, search_lambda)
          expect(result).to eql(file_full)
        end
      end

      context "when there is a piece rightward" do
        let(:piece) { Piece.new([7, 0], :white, move_list) }

        before do
          board.place_piece(piece, [7, 0])
        end

        it "returns the squares up to the piece" do
          file_upto = [[1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0]]
          result = move_list.move_search(start_square, search_lambda)
          expect(result).to eql(file_upto)
        end
      end
    end
  end

  describe "#attack_search" do
    context "when searching upward" do
      let(:start_square) { [0, 0] }
      let(:colour) { :white }
      let(:search_lambda) { ->(a, b) { [a, b + 1] } }

      context "when there is no enemy" do
        it "returns empty array" do
          result = move_list.attack_search(start_square, colour, search_lambda)
          expect(result).to eql([])
        end
      end

      context "when there is an enemy" do
        let(:enemy) { Piece.new([0, 5], :black, move_list) }

        before do
          board.place_piece(enemy, [0, 5])
        end

        it "returns the coords of the enemy" do
          result = move_list.attack_search(start_square, colour, search_lambda)
          expect(result).to eql([[0, 5]])
        end
      end

      context "when there is an enemy behind an ally" do
        let(:enemy) { Piece.new([0, 5], :black, move_list) }
        let(:ally) { Piece.new([0, 4], :white, move_list) }

        before do
          board.place_piece(enemy, [0, 5])
          board.place_piece(ally, [0, 4])
        end

        it "returns empty array" do
          result = move_list.attack_search(start_square, colour, search_lambda)
          expect(result).to eql([])
        end
      end
    end
  end

  describe "#transformers" do
    context "when passed directions" do
      it "returns the corresponding transformers" do
        directions = %i[left up_right long_down_right]
        position = [4, 5]
        transformed_positions = [[3, 5], [5, 6], [5, 3]]

        transformers = move_list.transformers(directions)
        results = transformers.map { |transformer| transformer.call(*position) }

        expect(results).to eql(transformed_positions)
      end
    end
  end
end
