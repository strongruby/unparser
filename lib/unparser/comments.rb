module Unparser

  # Holds the comments that remain to be emitted
  #
  # @api private
  #
  class Comments

    # Initialize object
    #
    # @param [Array] comments
    #
    # @return [undefined]
    #
    def initialize(comments)
      @comments = comments.dup
    end

    # Consume part or all of the node
    #
    # @param [Parser::AST::Node] node
    # @param [Symbol] source_part
    #
    # @return [undefined]
    #
    def consume(node, source_part)
      return unless node.location
      @last_range_consumed = node.location.public_send(source_part)
    end

    # Take end-of-line comments
    #
    # @return [Array]
    #
    def take_eol_comments
      return [] if @last_range_consumed.nil?
      comments = take_up_to_line(@last_range_consumed.end.line)
      doc_comments, eol_comments = comments.partition(&:document?)
      doc_comments.reverse_each {|comment| @comments.unshift(comment) }
      eol_comments
    end

    # Take all remaining comments
    #
    # @return [Array]
    #
    def take_all
      take_while { true }
    end

    # Take comments that appeared in the source before the specified part of
    # the node
    #
    # @param [Parser::AST::Node] node
    # @param [Symbol] source_part
    #
    # @return [Array]
    #
    def take_before(node, source_part)
      loc = node.location
      range = loc.public_send(source_part) if loc.respond_to?(source_part)
      return [] if range.nil?
      take_while { |comment| comment.location.expression.end_pos <= range.begin_pos }
    end

  private

    # Take comments while the provided block returns true
    #
    # @yield [comment]
    #
    # @return [Array]
    #
    def take_while
      number_to_take = @comments.index {|comment| !yield(comment) } || @comments.size
      @comments.shift(number_to_take)
    end

    # Take comments up to the line number
    #
    # @param [Fixnum] line
    #
    def take_up_to_line(line)
      take_while { |comment| comment.location.expression.line <= line }
    end
  end
end