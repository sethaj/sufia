module Export
  class VersionsFromGraph
    attr_accessor :versions

    class Version
      attr_accessor :uri, :hasVersionLabel, :created

      def initialize(uri, label, created)
        @uri = uri
        @hasVersionLabel = label
        @created = created
      end
    end

    def self.parse(graph)
      parse_graph(graph)
    end

    private

      def self.parse_graph(graph)
        versions = []
        find_uris(graph).each do |uri|
          created = find_created(uri, graph)
          label = find_label(uri, graph)
          version = Version.new(uri, label, created)
          versions << version
        end
        versions
      end

      def self.find_uris(graph)
        uris = []
        graph.each do |triple|
          if triple.predicate.to_s == "http://fedora.info/definitions/v4/repository#hasVersion"
            uris << triple.object.to_s
          end
        end
        uris
      end

      def self.find_created(uri, graph)
        predicate = "http://fedora.info/definitions/v4/repository#created"
        find_triple(uri, predicate, graph)
      end

      def self.find_label(uri, graph)
        predicate = "http://fedora.info/definitions/v4/repository#hasVersionLabel"
        find_triple(uri, predicate, graph)
      end

      def self.find_triple(uri, predicate, graph)
        triple = graph.select {|t| t.subject == uri && t.predicate == predicate}.first
        triple.object.to_s
      end
  end
end
