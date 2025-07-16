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

    def split(text, reconstructable: false)
      if reconstructable && !@chunk_overlap.zero?
        raise "Reconstructable mode requires chunk_overlap to be 0"
      end

      output = []
      good_splits = []

      separator = @separators.last
      @separators.each do |s|
        if text.include?(s)
          separator = s
          break
        end
      end
      splits = text.split(separator)

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

          other_info = split(s, reconstructable: reconstructable)
          output.concat(other_info)
        end
      end

      if good_splits.any?
        merged_text =
          merge_splits(good_splits, separator, reconstructable: reconstructable)
        output.concat(merged_text)
      end

      last = output.pop if output.last&.end_with?(separator)
      output << last.delete_suffix(separator) if last

      output
    end

    private

    # Given a set of splits that are individually shorter than the chunk size,
    # merge them into chunks that are at most chunk_size long.
    # If reconstructable is true, the separator will be included in the chunk.
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
              current_chunk_splits.join(separator)
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
          current_chunk_splits.join(separator)
        else
          current_chunk_splits.join(separator).strip
        end

      output << chunk if chunk && !chunk.empty?

      if reconstructable
        # last_chunk = output.last
        # output[0..-2].map do |unseparated_chunk|
        #   "#{unseparated_chunk}#{separator}"
        # end + [last_chunk]
        output.map { |unseparated_chunk| "#{unseparated_chunk}#{separator}" }
      else
        output
      end
    end
  end
end
