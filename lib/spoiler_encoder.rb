require 'rot13'

# TODO: merge enc_standard and enc_modern into one method

class SpoilerEncoder
  def self.enc_standard(text, offset=13, regex)
    # We don't want any asterisks in the text, because that'd mess with the formatting
    text.gsub!("*", "")
    return text.gsub(regex) {|spoiler_with_tags| "**" + Rot13.rotate(spoiler_with_tags.match(regex)[1], offset) + "**"} 
  end

  def self.enc_modern(text, offset=13)
    modern_regex = /\[(?<spoiler_description>.+?)\]:\[(?<spoiler_text>.+?)\]/
    # We don't want any asterisks in the text, because that'd mess with the formatting
    text.gsub!("*", "")
    return text.gsub(modern_regex) {|spoiler| "*#{spoiler.match(modern_regex)["spoiler_description"]}:* **#{Rot13.rotate(spoiler.match(modern_regex)["spoiler_text"], offset)}**"}
  end

  def self.decode(text, offset=-13)
    regex = /\*\*(.+?)\*\*/
    return text.gsub(regex) {|spoiler_with_tags| Rot13.rotate(spoiler_with_tags, offset)}
  end
end