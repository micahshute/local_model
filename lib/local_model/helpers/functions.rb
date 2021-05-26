class LocalModel::Functions

  def self.snake_to_camel(snakecase)
    snakecase.to_s.split("_").map.with_index do |word, i|
      i == 0 ? word : word.capitalize
    end.join('')
  end

  def self.camel_to_snake(camel)
    camel.to_s.split(/(?=[A-Z])/).map(&:downcase).join("_")
  end

  def self.singularize(word)
    word = word.to_s
    return PluralizedWords::IRREGULAR_SINGULARIZED_WORDS[word] if PluralizedWords::IRREGULAR_PLURALIZED_WORDS[word]
    if word[-1] == "i"
      "#{word[0...-1]}us"
    elsif word[-1] == "a"
      "#{word[0..-1]}on"
    elsif word =~ /ies$/
      "#{word[0...-3]}y"
    elsif word =~ /es$/
      if word[-3] == "v"
        word[-3] = "f"
        word[0...-2]
      elsif word[0...-2] =~ /s$|ss$|sh$|ch$|x$|z$|o$/
        word[0...-2]
      else
        "#{word[0...-1]}"
      end
    else
      "#{word[0...-1]}"
    end
  end

  def self.pluralize(word)
    word = word.to_s
    return PluralizedWords::IRREGULAR_PLURALIZED_WORDS[word] if PluralizedWords::IRREGULAR_PLURALIZED_WORDS[word]
    if word[-2..-1] == "us"
      "#{word[0...-2]}i"
    elsif word[-2..-1] == "on"
      "#{word[0...-2]}a"
    elsif word =~ /s$|ss$|sh$|ch$|x$|z$|o$/
      "#{word}es"
    elsif word =~ /f$|fe$/
      word[-1] == "f" ? word[-1] = "v" : word[-2] = "v"
      word[-1] == "e" ? "#{word}s" : "#{word}es"
    elsif word =~ /[^aeiou]y$/
      "#{word[0...-1]}ies"
    elsif word[-2..-1] == "is"
      "#{word[0...-2]}es"
    else
      "#{word}s"
    end
  end


end