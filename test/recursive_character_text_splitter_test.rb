require "test_helper"

class RecursiveCharacterTextSplitterTest < Minitest::Test
  def test_basic_case
    text = <<~STR
      Hi.\n\nI'm Harrison.\n\nHow? Are? You?\nOkay then f f f f.
      This is a weird text to write, but gotta test the splittingggg some how.

      Bye!\n\n-H.
    STR
    splitter =
      ::TextSplitters::RecursiveCharacterTextSplitter.new(
        chunk_size: 10,
        chunk_overlap: 1
      )

    output = splitter.split(text)

    expected = [
      "Hi.",
      "I'm",
      "Harrison.",
      "How? Are?",
      "You?",
      "Okay then f",
      "f f f f.",
      "This is a",
      "a weird",
      "text to",
      "write, but",
      "gotta test",
      "the",
      "splitting",
      "gggg",
      "some how.",
      "Bye!\n\n-H."
    ]
    assert_equal expected, output
  end

  def test_state_of_the_union
    text =
      "Madam Speaker, Madam Vice President, our First Lady and Second Gentleman. Members of Congress and the Cabinet. Justices of the Supreme Court. My fellow Americans."
    splitter =
      ::TextSplitters::RecursiveCharacterTextSplitter.new(
        chunk_size: 100,
        chunk_overlap: 20
      )

    output = splitter.split(text)

    assert_equal 2, output.length
    assert_equal "Madam Speaker, Madam Vice President, our First Lady and Second Gentleman. Members of Congress and the Cabinet.",
                 output.first
    assert_equal "and the Cabinet. Justices of the Supreme Court. My fellow Americans.",
                 output.last
  end

  def test_reconstructable_option
    # Test text with various separators to ensure reconstruction works
    original_text =
      "Paragraph one.\n\nParagraph two.\n\nThis is a longer paragraph that will be split into multiple chunks because it exceeds the chunk size limit."

    # Test with reconstructable = true
    splitter =
      ::TextSplitters::RecursiveCharacterTextSplitter.new(
        chunk_size: 30,
        chunk_overlap: 0
      )
    chunks = splitter.split(original_text, reconstructable: true)

    # Verify that reconstructable chunks can be joined to reproduce original text
    reconstructed_text = chunks.join
    assert_equal original_text, reconstructed_text
  end

  def test_reconstructable_with_custom_separators
    # Test with custom separators
    original_text = "Section A---Section B---Section C"
    custom_separators = ["---", " ", ""]

    splitter =
      ::TextSplitters::RecursiveCharacterTextSplitter.new(
        chunk_size: 20,
        chunk_overlap: 0,
        separators: custom_separators
      )

    chunks = splitter.split(original_text, reconstructable: true)
    reconstructed_text = chunks.join

    assert_equal original_text, reconstructed_text
    assert_predicate chunks, :any?
  end

  def test_reconstructable_edge_cases
    # Test with text that has no natural separators
    original_text = "ThisIsOneLongWordWithoutSpaces"

    splitter =
      ::TextSplitters::RecursiveCharacterTextSplitter.new(
        chunk_size: 10,
        chunk_overlap: 0
      )

    chunks = splitter.split(original_text, reconstructable: true)
    reconstructed_text = chunks.join

    assert_equal original_text, reconstructed_text
    assert_predicate chunks, :any?

    # Test with empty text
    empty_text = ""
    chunks_empty = splitter.split(empty_text)
    reconstructed_empty = chunks_empty.join

    assert_equal empty_text, reconstructed_empty
  end

  def test_reconstructable_ending_with_separator
    original_text = "Paragraph one.\n\nParagraph two.\n\n"

    splitter =
      ::TextSplitters::RecursiveCharacterTextSplitter.new(
        chunk_size: 10,
        chunk_overlap: 0
      )

    chunks = splitter.split(original_text, reconstructable: true)
    reconstructed_text = chunks.join

    assert_equal original_text, reconstructed_text
  end
end
