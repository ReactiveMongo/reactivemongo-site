<script src="//cdn.jsdelivr.net/algoliasearch/3/algoliasearch.min.js"></script>
<script src="//cdn.jsdelivr.net/autocomplete.js/0/autocomplete.min.js"></script>
<script>
  var c = algoliasearch("{{site.algolia.application_id}}", "{{site.algolia.search_only_api_key}}"), index = c.initIndex("reactivemongo");

  autocomplete('#search-input', {hint: false}, [
    {
      source: autocomplete.sources.hits(index, {
        hitsPerPage:5, facets:"major_version",
        filters: 'major_version={% include major-version.md %}'
      }),
      displayKey: 'title',
      templates: {
        suggestion: function(suggestion) {
          return suggestion._highlightResult.h2.value;
        }
      }
    }
  ]).on('autocomplete:selected', function(event, suggestion, dataset) {
    var url = suggestion.url, sel = suggestion.css_selector_parent;
    self.location.href = (sel) ? (url + sel) : url
  });
</script>
