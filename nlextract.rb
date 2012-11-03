require "treetop"




### PARSER
## Load parser for the Stanford parser's output from 'tree.treetop'

Treetop.load "tree"
@parser = SentenceTreeParser.new




### MATCHERS
## find interesting sub-trees of a sentence

# finds nouns with all associated adjectives and whatnot
# ex: "good book", "my book"
class DescriptivePhraseMatcher
  def match node
    matches = []

    if node.type == "NP"
      descriptors = node.children_of_type("JJ")
      descriptors += node.children_of_type("PRP$")
      descriptors += node.children_of_type("ADJP").inject([]) { |ds, adjp| ds + adjp.children_of_type("JJ") }
      descriptors.each do |descriptor|
        matches << "#{descriptor.headword} #{node.headword}"
      end

      if descriptors.length == 0
        matches << "#{node.headword}"
      end
    end

    matches
  end
end

# SentenceMatcher helper that, given a verb node, tries to find direct objects
class VerbPhraseDependentsMatcher
  def match verb_node
    matches = []

    direct_objects = verb_node.children_of_type("NP")
    direct_objects.each do |direct_object|
      matches << direct_object.headword
    end

    # the only reason this is here is because of the phrase "broke up"
    # it might not actually be a good idea
    prts = verb_node.children_of_type("PRT")
    prts.each do |prt|
      matches << prt.headword
    end

    matches
  end
end

# looks for sentences with a subject and a verb
class SentenceMatcher
  def match node
    subjects = node.children_of_type("NP")
    verbs = node.children_of_type("VP")
    if node.type == "S"
      matches = []
      subjects.each do |subject|
        verbs.each do |verb|
          deps = VerbPhraseDependentsMatcher.new.match(verb)
          if deps.length > 0
            deps.each do |dep|
              matches << "#{subject.headword} #{verb.headword} #{dep}"
            end
          else
            matches << "#{subject.headword} #{verb.headword}"
          end
        end
      end
      matches
    else
      []
    end
  end
end




### SENTENCE TREES
## Nodes and Leafs represent the nodes in the given Stanford parser tree

class Node
  attr_reader :type
  attr_reader :word
  attr_reader :headword
  attr_reader :children

  def initialize type, headword, headtype, children
    @type = type
    @headword = @word = headword
    @headtype = headtype
    @children = children
  end

  def to_s
    "#{@type}[#{@headword}/#{@headtype}]"
  end

  def inspect level=0
    ("  " * level) + to_s + ("\n" if @children.length > 0).to_s + (@children.map { |c| c.inspect(level + 1) }.join("\n"))
  end

  def children_of_type type
    @children.select { |c| c.type == type }
  end

  def find matcher
    matches = matcher.match(self)
    children.inject(matches) do |matches, child|
      matches + child.find(matcher)
    end
  end
end

class Leaf < Node
  def initialize type, word
    super type, word, type, []
  end
end




### MAIN
## Reads the Stanford parser output from stdin
## Outputs some interesting information about each sentence

def parse input
  if b = @parser.parse(input)
    b.node.find(SentenceMatcher.new).uniq.each { |s| puts "sentence: #{s}" }
    b.node.find(DescriptivePhraseMatcher.new).uniq.each { |ph| puts "phrase: #{ph}" }
  else
    $stderr.puts "failure: #{@parser.failure_reason}"
  end
end

$stdin.read.split("\n\n").each do |input|
  parse input
  puts
end
