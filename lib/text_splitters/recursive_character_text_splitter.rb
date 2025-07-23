module TextSplitters
  # Ruby port of https://github.com/hwchase17/langchain/blob/763f87953686a69897d1f4d2260388b88eb8d670/langchain/text_splitter.py#L221
  class RecursiveCharacterTextSplitter
    def initialize(
      chunk_size:,
      chunk_overlap:,
      separators: ["\n\n", "\n", " ", ""]
    )
      @chunk_size = chunk_size
      @chunk_overlap = chunk_overlap
      @separators = separators
    end

    def split(text, reconstructable: false, iteration_separators: @separators)
      if reconstructable && !@chunk_overlap.zero?
        raise "Reconstructable mode requires chunk_overlap to be 0"
      end

      output = []
      good_splits = []

      separator = iteration_separators.last
      iteration_separators.each do |s|
        if text.include?(s)
          separator = s
          break
        end
      end
      splits = split_string(text, separator, reconstructable: reconstructable)

      splits.each do |s|
        if s.length < @chunk_size
          good_splits << s
        else
          if good_splits.any?
            merged_text =
              merge_splits(
                good_splits,
                separator,
                reconstructable: reconstructable
              )
            output.concat(merged_text)
            good_splits = []
          end

          other_info = split(
            s,
            reconstructable: reconstructable,
            iteration_separators: iteration_separators - [separator]
          )
          output.concat(other_info)
        end
      end

      if good_splits.any?
        merged_text =
          merge_splits(good_splits, separator, reconstructable: reconstructable)
        output.concat(merged_text)
      end

      # Fix join that ends with separator when the text didn't
      if reconstructable && output.last&.end_with?(separator) && !text.end_with?(separator)
        last = output.pop
        output << last.delete_suffix(separator)
      end

      output
    end

    private

    # Given a set of splits that are individually shorter than the chunk size,
    # merge them into chunks that are at most chunk_size long.
    # If reconstructable is true, the separator will NOT be used to join the chunks
    # because we assume the chunks include the separator.
    def merge_splits(splits, separator, reconstructable: false)
      output = []
      current_chunk_splits = [] # the set of splits that will be merged into a single chunk
      total = 0

      splits.each do |split|
        if total + split.length >= @chunk_size && current_chunk_splits.any?
          # build the chunk before we overflow the chunk size

          # reconstructible means retain even whitespace
          chunk =
            if reconstructable
              current_chunk_splits.join
            else
              current_chunk_splits.join(separator).strip
            end

          output << chunk if chunk && !chunk.empty?

          # remove all the chunks that won't be in the next chunk
          # due to overlap
          while total > @chunk_overlap ||
                (total > 0 && (total + split.length > @chunk_size))
            total -= current_chunk_splits.first.length
            current_chunk_splits.shift
          end
        end
        current_chunk_splits << split
        total += split.length
      end
      chunk =
        if reconstructable
          current_chunk_splits.join
        else
          current_chunk_splits.join(separator).strip
        end

      output << chunk if chunk && !chunk.empty?

      output
    end

    def split_string(text, separator, reconstructable:)
      return text.split(separator) unless reconstructable
      return text.split(separator) if separator.empty?

      splits = []
      current_split = ""
      copy = text.dup
      until copy.empty?
        if copy.start_with?(separator)
          splits << current_split unless current_split.empty?
          splits << separator
          current_split = ""
          copy = copy.delete_prefix(separator)
        else
          current_split << copy[0]
          copy = copy[1..]
        end
      end
      splits << current_split unless current_split.empty?
      splits
    end
  end
end
