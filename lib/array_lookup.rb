class Hiera
  module Backend
    class Array_lookup
      def lookup(key, scope, order_override, resolution_type)
        Backend.datasources(scope, order_override) do |source|
        end
      end
    end
  end
end
