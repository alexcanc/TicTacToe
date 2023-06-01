require 'gosu'

class TicTacToeWindow < Gosu::Window
  def initialize
    super(900, 900)
    self.caption = 'Tic-Tac-Toe'
    @grid = Array.new(3) { Array.new(3) { ' ' } }
    @current_player = 'X'
    @winner = nil
    @cell_size = height / 3
    @font = Gosu::Font.new(75)
  end

  def update
    if @current_player == 'O' && !game_over?
      place_bot_move
    end
  end

  def draw
    draw_grid
    draw_symbols
    draw_message if @game_over
  end

  def button_down(id)
    if id == Gosu::MS_LEFT
      if !game_over?
        play_turn('X')
      end
    elsif id == Gosu::KB_SPACE
      if game_over?
        reset_game
      end
    end
  end

  private

  def draw_grid
    draw_line(@cell_size, 0, Gosu::Color::WHITE, @cell_size, height, Gosu::Color::WHITE)
    draw_line(@cell_size * 2, 0, Gosu::Color::WHITE, @cell_size * 2, height, Gosu::Color::WHITE)
    draw_line(0, @cell_size, Gosu::Color::WHITE, width, @cell_size, Gosu::Color::WHITE)
    draw_line(0, @cell_size * 2, Gosu::Color::WHITE, width, @cell_size * 2, Gosu::Color::WHITE)
  end

  def draw_symbols
    @grid.each_with_index do |row, row_index|
      row.each_with_index do |cell, cell_index|
        x = cell_index * @cell_size + @cell_size / 2
        y = row_index * @cell_size + @cell_size / 2
        case cell
        when 'X'
          draw_x(x, y)
        when 'O'
          draw_o(x, y)
        end
      end
    end
  end

  def draw_x(x, y)
    draw_line(x - @cell_size * 0.3, y - @cell_size * 0.3, Gosu::Color::WHITE,
              x + @cell_size * 0.3, y + @cell_size * 0.3, Gosu::Color::WHITE)
    draw_line(x + @cell_size * 0.3, y - @cell_size * 0.3, Gosu::Color::WHITE,
              x - @cell_size * 0.3, y + @cell_size * 0.3, Gosu::Color::WHITE)
  end

  def draw_o(x, y)
    radius = @cell_size * 0.3
    color = Gosu::Color::WHITE
    x_center = x
    y_center = y

    0.step(360, 10) do |angle|
      x1 = x_center + radius * Math.cos(angle * Math::PI / 180)
      y1 = y_center + radius * Math.sin(angle * Math::PI / 180)
      x2 = x_center + radius * Math.cos((angle + 10) * Math::PI / 180)
      y2 = y_center + radius * Math.sin((angle + 10) * Math::PI / 180)
      draw_quad(x1, y1, color, x1, y2, color, x2, y2, color, x2, y1, color)
    end
  end

  def draw_message
    return if @winner.nil? && !draw?

    main_text = ''
    sub_text = 'Press space to restart.'
    case @winner
    when 'X'
      main_text = 'You win!'
    when 'O'
      main_text = 'You lose!'
    else
      main_text = 'It\'s a draw!'
    end
    main_x = (width - @font.text_width(main_text)) / 2
    main_y = (height - @font.height) / 2
    sub_x = (width - @font.text_width(sub_text)) / 2
    sub_y = main_y + @font.height

    @font.draw_text(main_text, main_x, main_y, 1, 1, 1, Gosu::Color::WHITE)
    @font.draw_text(sub_text, sub_x, sub_y, 1, 1, 1, Gosu::Color::WHITE)
  end

  def draw?
    @grid.flatten.none? { |cell| cell == ' ' }
  end

  def game_over?
    @game_over = @winner || draw?
  end

  def place_bot_move
    return if game_over?

    best_score = -Float::INFINITY
    best_move = nil
    @grid.each_with_index do |row, row_index|
      row.each_with_index do |cell, cell_index|
        if cell == ' '
          @grid[row_index][cell_index] = 'O'
          score = minimax(@grid, 0, false)
          @grid[row_index][cell_index] = ' '
          if score > best_score
            best_score = score
            best_move = [row_index, cell_index]
          end
        end
      end
    end

    @grid[best_move[0]][best_move[1]] = 'O'
    @current_player = 'X'
    @winner = calculate_winner
  end

  def minimax(board, depth, is_maximizing)
    winner = calculate_winner
    return 1 if winner == 'O'
    return -1 if winner == 'X'
    return 0 if draw?

    if is_maximizing
      best_score = -Float::INFINITY
      board.each_with_index do |row, row_index|
        row.each_with_index do |cell, cell_index|
          if cell == ' '
            board[row_index][cell_index] = 'O'
            score = minimax(board, depth + 1, false)
            board[row_index][cell_index] = ' '
            best_score = [score, best_score].max
          end
        end
      end
      best_score
    else
      best_score = Float::INFINITY
      board.each_with_index do |row, row_index|
        row.each_with_index do |cell, cell_index|
          if cell == ' '
            board[row_index][cell_index] = 'X'
            score = minimax(board, depth + 1, true)
            board[row_index][cell_index] = ' '
            best_score = [score, best_score].min
          end
        end
      end
      best_score
    end
  end

  def calculate_winner
    winning_rows.each do |row|
      next if row[0] == ' ' # Skip rows with empty cells
      if row.all? { |cell| cell == 'X' }
        return 'X'
      elsif row.all? { |cell| cell == 'O' }
        return 'O'
      end
    end
    nil
  end

  def winning_rows
    rows = []
    rows << @grid[0]
    rows << @grid[1]
    rows << @grid[2]
    rows << [@grid[0][0], @grid[1][0], @grid[2][0]]
    rows << [@grid[0][1], @grid[1][1], @grid[2][1]]
    rows << [@grid[0][2], @grid[1][2], @grid[2][2]]
    rows << [@grid[0][0], @grid[1][1], @grid[2][2]]
    rows << [@grid[0][2], @grid[1][1], @grid[2][0]]
    rows
  end

  def play_turn(symbol)
    x = mouse_x / @cell_size
    y = mouse_y / @cell_size
    if @grid[y][x] == ' ' && !game_over?
      @grid[y][x] = symbol
      @current_player = (symbol == 'X') ? 'O' : 'X'
      @winner = calculate_winner
    end
  end

  def reset_game
    @grid = Array.new(3) { Array.new(3) { ' ' } }
    @current_player = 'X'
    @winner = nil
    @message = nil
  end
end

window = TicTacToeWindow.new
window.show
