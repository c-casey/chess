# chess_spec.rb
# frozen_string_literal: true

require_relative "../lib/chess"

describe Chess do
  let(:board) { Board.new }
  let(:move_list) { MoveList.new }
  let(:display) { instance_double("Display") }
  subject(:chess) { described_class.new(board, move_list, display) }

  describe "#check_end_condition" do
    context "when legal moves remain and player is checked" do
      let(:rook) { Rook.new([7, 0], :white, move_list) }
      let(:king) { King.new([7, 7], :black, move_list) }

      before do
        board.place_piece(rook, rook.location)
        board.place_piece(king, king.location)
        chess.current_player = :black
      end

      it "returns nil" do
        result = chess.check_end_condition
        expect(result).to be_nil
      end
    end

    context "when no legal moves remain and player is checked" do
      let(:rook1) { Rook.new([7, 0], :white, move_list) }
      let(:rook2) { Rook.new([6, 0], :white, move_list) }
      let(:king) { King.new([7, 7], :black, move_list) }

      before do
        board.place_piece(rook1, rook1.location)
        board.place_piece(rook2, rook2.location)
        board.place_piece(king, king.location)
        chess.current_player = :black
      end

      it "returns opponent" do
        result = chess.check_end_condition
        expect(result).to eql(:white)
      end
    end

    context "when no legal moves remain and player is not checked" do
      let(:rook1) { Rook.new([4, 3], :white, move_list) }
      let(:rook2) { Rook.new([7, 0], :white, move_list) }
      let(:queen) { Queen.new([5, 0], :white, move_list) }
      let(:king) { King.new([6, 2], :black, move_list) }

      before do
        board.place_piece(rook1, rook1.location)
        board.place_piece(rook2, rook2.location)
        board.place_piece(queen, queen.location)
        board.place_piece(king, king.location)
        chess.current_player = :black
      end

      it "returns tie" do
        result = chess.check_end_condition
        expect(result).to eql(:tie)
      end
    end
  end

  describe "#promote_pawn?" do
    context "when pawn is ready to be promoted" do
      let(:pawn) { Pawn.new([1, 7], :white, move_list) }

      it "returns true" do
        result = chess.send :promotable_pawn?, pawn
        expect(result).to be_truthy
      end
    end

    context "when pawn is not ready to be promoted" do
      let(:pawn) { Pawn.new([4, 1], :black, move_list) }

      it "returns false" do
        result = chess.send :promotable_pawn?, pawn
        expect(result).to be_falsey
      end
    end

    context "when piece other than pawn is on opposite back rank" do
      let(:knight) { Knight.new([5, 7], :white, move_list) }

      it "returns false" do
        result = chess.send :promotable_pawn?, knight
        expect(result).to be_falsey
      end
    end
  end
end

describe Board do
  subject(:board) { described_class.new }
  let(:move_list) { double("MoveList") }
  let(:piece) { Piece.new([0, 0], :white, move_list) }

  describe "#move_piece" do
    it "moves a piece" do
      board.place_piece(piece, piece.location)
      board.move_piece([0, 0], [4, 6])
      result = board.lookup_square([4, 6])
      expect(result).to be_an_instance_of(Piece)
    end

    it "updates the piece's location variable" do
      board.place_piece(piece, piece.location)
      board.move_piece([0, 0], [4, 6])
      location = board.lookup_square([4, 6]).location
      expect(location).to eql([4, 6])
    end

    context "when white castles" do
      let(:rook_queenside) { Rook.new([0, 0], :white, move_list) }
      let(:rook_kingside) { Rook.new([7, 0], :white, move_list) }
      let(:king) { King.new([4, 0], :white, move_list) }

      before do
        board.place_piece(rook_queenside, [0, 0])
        board.place_piece(rook_kingside, [7, 0])
        board.place_piece(king, [4, 0])
      end

      context "when castling queenside" do
        it "moves the rook appropriately" do
          board.move_piece([4, 0], [2, 0])
          result = board.lookup_square([3, 0])
          expect(result).to be_an_instance_of(Rook)
        end

        it "doesn't move the other rook" do
          board.move_piece([4, 0], [2, 0])
          result = board.lookup_square([7, 0])
          expect(result).to be_an_instance_of(Rook)
        end
      end

      context "when castling kingside" do
        it "moves the rook appropriately" do
          board.move_piece([4, 0], [6, 0])
          result = board.lookup_square([5, 0])
          expect(result).to be_an_instance_of(Rook)
        end

        it "doesn't move the other rook" do
          board.move_piece([4, 0], [6, 0])
          result = board.lookup_square([0, 0])
          expect(result).to be_an_instance_of(Rook)
        end
      end
    end

    context "when black castles" do
      let(:rook_queenside) { Rook.new([0, 7], :black, move_list) }
      let(:rook_kingside) { Rook.new([7, 7], :black, move_list) }
      let(:king) { King.new([4, 7], :black, move_list) }

      before do
        board.place_piece(rook_queenside, [0, 7])
        board.place_piece(rook_kingside, [7, 7])
        board.place_piece(king, [4, 7])
      end

      context "when black castles queenside" do
        it "moves the rook appropriately" do
          board.move_piece([4, 7], [2, 7])
          result = board.lookup_square([3, 7])
          expect(result).to be_an_instance_of(Rook)
        end

        it "doesn't move the other rook" do
          board.move_piece([4, 7], [2, 7])
          result = board.lookup_square([7, 7])
          expect(result).to be_an_instance_of(Rook)
        end
      end

      context "when black castles kingside" do
        it "moves the rook appropriately" do
          board.move_piece([4, 7], [6, 7])
          result = board.lookup_square([5, 7])
          expect(result).to be_an_instance_of(Rook)
        end

        it "doesn't move the other rook" do
          board.move_piece([4, 7], [6, 7])
          result = board.lookup_square([0, 7])
          expect(result).to be_an_instance_of(Rook)
        end
      end
    end
  end

  describe "#move_into_check?" do
    let(:bishop) { Bishop.new([1, 3], :black, move_list) }
    let(:king) { King.new([4, 0], :white, move_list) }
    let(:pawn_defender) { Pawn.new([3, 1], :white, move_list) }
    let(:piece) { instance_double("Piece") }
    let(:move_list) { MoveList.new }

    before do
      board.place_piece(king, king.location)
      board.place_piece(bishop, bishop.location)
      board.place_piece(pawn_defender, pawn_defender.location)
    end

    it "does not change origin square" do
      board.move_into_check?([3, 1], [3, 2])
      expect(pawn_defender).to eql(board.lookup_square([3, 1]))
    end

    it "does not change destination square" do
      dest_dup = board.lookup_square([3, 2]).dup
      board.move_into_check?([3, 1], [3, 2])
      expect(dest_dup).to eql(board.lookup_square([3, 2]))
    end

    context "when move would result in being checked" do
      it "returns true" do
        result = board.move_into_check?([3, 1], [3, 2])
        expect(result).to be_truthy
      end
    end

    context "when move would not result in being checked" do
      let(:pawn_useless) { Pawn.new([4, 1], :white, move_list) }

      before do
        board.place_piece(pawn_useless, pawn_useless.location)
      end

      it "returns false" do
        result = board.move_into_check?([4, 1], [4, 2])
        expect(result).to be_falsey
      end
    end
  end
end

describe BoardSetup do
  let(:board) { Board.new }
  let(:move_list) { MoveList.new }
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
  let(:move_list) { MoveList.new }
  let(:board) { Board.new }

  describe "#valid_moves_and_attacks" do
    context "when in check" do
      subject(:king) { described_class.new([4, 7], :black, move_list) }
      let(:rook) { Rook.new([4, 3], :white, move_list) }

      before do
        board.place_piece(king, king.location)
        board.place_piece(rook, rook.location)
      end

      it "doesn't allow castling" do
        legal_moves = [[3, 6], [3, 7], [5, 6], [5, 7]]
        result = king.valid_moves_and_attacks(board)
        expect(result).to eql(legal_moves)
      end
    end
  end

  describe "#moves" do
    let(:piece) { instance_double("Piece") }
    subject(:king) { described_class.new([4, 4], :white, move_list) }

    before do
      board.place_piece(king, king.location)
      board.place_piece(piece, [3, 4])
      board.place_piece(piece, [4, 5])
      board.place_piece(piece, [5, 3])
    end

    it "returns all legal movements for a given position" do
      legal_moves = [[3, 3], [3, 5], [4, 3], [5, 4], [5, 5]]
      result = king.moves(board)
      expect(result).to eql(legal_moves)
    end
  end
end

describe Queen do
  let(:piece) { instance_double("Piece") }
  let(:board) { Board.new }
  let(:move_list) { MoveList.new }
  subject(:queen) { described_class.new([4, 4], :white, move_list) }

  describe "#valid_moves" do
    before do
      board.place_piece(queen, queen.location)
      board.place_piece(piece, [2, 4])
      board.place_piece(piece, [4, 5])
      board.place_piece(piece, [5, 3])
      board.place_piece(piece, [1, 1])
    end

    it "returns all legal movements for a given position" do
      legal_moves = [[1, 7], [2, 2], [2, 6], [3, 3], [3, 4], [3, 5], [4, 0], [4, 1],
                     [4, 2], [4, 3], [5, 4], [5, 5], [6, 4], [6, 6], [7, 4], [7, 7]]
      result = queen.moves(board)
      expect(result).to eql(legal_moves)
    end
  end
end

describe Rook do
  let(:piece) { instance_double("Piece") }
  let(:board) { Board.new }
  let(:move_list) { MoveList.new }
  subject(:rook) { described_class.new([4, 4], :white, move_list) }

  describe "#valid_moves" do
    before do
      board.place_piece(rook, rook.location)
      board.place_piece(piece, [6, 4])
      board.place_piece(piece, [4, 2])
    end

    it "returns all legal movements for a given position" do
      legal_moves = [[0, 4], [1, 4], [2, 4], [3, 4], [4, 3], [4, 5], [4, 6], [4, 7], [5, 4]]
      result = rook.moves(board)
      expect(result).to eql(legal_moves)
    end
  end
end

describe Bishop do
  let(:piece) { instance_double("Piece") }
  let(:board) { Board.new }
  let(:move_list) { MoveList.new }
  subject(:bishop) { described_class.new([4, 4], :white, move_list) }

  describe "#valid_moves" do
    before do
      board.place_piece(bishop, bishop.location)
      board.place_piece(piece, [2, 2])
      board.place_piece(piece, [7, 1])
    end

    it "returns all legal movements for a given position" do
      legal_moves = [[1, 7], [2, 6], [3, 3], [3, 5], [5, 3], [5, 5], [6, 2], [6, 6], [7, 7]]
      result = bishop.moves(board)
      expect(result).to eql(legal_moves)
    end
  end
end

describe Knight do
  let(:piece) { instance_double("Piece") }
  let(:board) { Board.new }
  let(:move_list) { MoveList.new }
  subject(:knight) { described_class.new([4, 4], :white, move_list) }

  describe "#valid_moves" do
    before do
      board.place_piece(knight, knight.location)
      board.place_piece(piece, [3, 6])
      board.place_piece(piece, [2, 3])
    end

    it "returns all legal movements for a given position" do
      legal_moves = [[2, 5], [3, 2], [5, 2], [5, 6], [6, 3], [6, 5]]
      result = knight.moves(board)
      expect(result).to eql(legal_moves)
    end
  end
end

describe Pawn do
  let(:piece) { instance_double("Piece") }
  let(:board) { Board.new }
  let(:move_list) { MoveList.new }

  describe "#valid_moves" do
    context "when white Pawn hasn't moved yet" do
      subject(:pawn) { described_class.new([0, 1], :white, move_list) }

      context "when free to move" do
        before do
          board.place_piece(pawn, pawn.location)
        end

        it "returns two legal moves" do
          legal_moves = [[0, 2], [0, 3]]
          result = pawn.moves(board)
          expect(result).to eql(legal_moves)
        end
      end

      context "when blocked by a piece 2 squares away" do
        before do
          board.place_piece(pawn, pawn.location)
          board.place_piece(piece, [0, 3])
        end

        it "returns one legal move" do
          legal_moves = [[0, 2]]
          result = pawn.moves(board)
          expect(result).to eql(legal_moves)
        end
      end

      context "when blocked by a piece 1 square away" do
        before do
          board.place_piece(pawn, pawn.location)
          board.place_piece(piece, [0, 2])
        end

        it "returns no legal moves" do
          legal_moves = []
          result = pawn.moves(board)
          expect(result).to eql(legal_moves)
        end
      end
    end

    context "when black Pawn has already moved" do
      subject(:pawn) { described_class.new([0, 7], :black, move_list) }

      before do
        board.place_piece(pawn, pawn.location)
        pawn.moved = true
      end

      context "when free to move" do
        it "returns one legal move" do
          legal_moves = [[0, 6]]
          result = pawn.moves(board)
          expect(result).to eql(legal_moves)
        end
      end

      context "when blocked by a piece" do
        before do
          board.place_piece(piece, [0, 6])
        end

        it "returns no legal moves" do
          legal_moves = []
          result = pawn.moves(board)
          expect(result).to eql(legal_moves)
        end
      end
    end
  end

  describe "#valid_attacks" do
    subject(:pawn_move) { Pawn.new([5, 6], :black, move_list) }
    let(:pawn_capture) { Pawn.new([4, 4], :white, move_list) }

    context "when a pawn uses its double move to pass enemy pawn's attack zone" do
      before do
        board.place_piece(pawn_move, [5, 6])
        board.place_piece(pawn_capture, [4, 4])
      end

      it "can be captured en passant" do
        pawn_move.move([5, 4], board)
        results = pawn_capture.attacks(board)
        expect(results).to eql([[5, 4]])
      end
    end

    context "when a pawn uses two single moves to pass enemy pawn's attack zone" do
      before do
        board.place_piece(pawn_move, [5, 6])
        board.place_piece(pawn_capture, [4, 4])
      end

      it "cannot be captured en passant" do
        pawn_move.move([5, 5], board)
        pawn_capture.move([5, 4], board)
        results = pawn_capture.attacks(board)
        expect(results).to eql([])
      end
    end

    context "when a pawn uses one single move to pass enemy pawn's attack zone" do
      before do
        board.place_piece(pawn_move, [5, 6])
        board.place_piece(pawn_capture, [4, 4])
      end

      it "cannot be captured en passant" do
        pawn_move.move([5, 5], board)
        pawn_capture.move([4, 5], board)
        results = pawn_capture.attacks(board)
        expect(results).to eql([])
      end
    end

    context "when a pawn uses its double move and enemy pawn moves beside it" do
      let(:pawn_capture) { Pawn.new([4, 3], :white, move_list) }

      before do
        board.place_piece(pawn_move, [5, 6])
        board.place_piece(pawn_capture, [4, 3])
      end

      it "cannot be captured en passant" do
        pawn_move.move([5, 4], board)
        pawn_capture.move([4, 4], board)
        results = pawn_capture.attacks(board)
        expect(results).to eql([])
      end
    end
  end
end

describe MoveList do
  let(:board) { Board.new }
  subject(:move_list) { described_class.new }

  describe "#move_search" do
    context "when searching upward" do
      let(:start_square) { [0, 0] }
      let(:search_lambda) { ->(a, b) { [a, b + 1] } }

      context "when there are no pieces above" do
        it "returns all the squares above" do
          file_full = [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7]]
          result = move_list.move_search(start_square, search_lambda, board)
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
          result = move_list.move_search(start_square, search_lambda, board)
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
          result = move_list.move_search(start_square, search_lambda, board)
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
          result = move_list.move_search(start_square, search_lambda, board)
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
          result = move_list.move_search(start_square, search_lambda, board)
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
          result = move_list.move_search(start_square, search_lambda, board)
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
          result = move_list.move_search(start_square, search_lambda, board)
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
          result = move_list.move_search(start_square, search_lambda, board)
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
          result = move_list.attack_search(start_square, colour, search_lambda, board)
          expect(result).to eql([])
        end
      end

      context "when there is an enemy" do
        let(:enemy) { Piece.new([0, 5], :black, move_list) }

        before do
          board.place_piece(enemy, [0, 5])
        end

        it "returns the coords of the enemy" do
          result = move_list.attack_search(start_square, colour, search_lambda, board)
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
          result = move_list.attack_search(start_square, colour, search_lambda, board)
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
