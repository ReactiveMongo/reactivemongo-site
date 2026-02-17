<script src="https://cdn.jsdelivr.net/npm/algoliasearch@4/dist/algoliasearch-lite.umd.js"></script>
<script>
  (function() {
    var searchClient = algoliasearch("{{site.algolia.application_id}}", "{{site.algolia.search_only_api_key}}");
    var mv = '{% include major-version.md %}';
    var av = (mv == '0.1x') ? mv : parseFloat(mv);
    var input = document.getElementById('search-input');
    var resultsContainer = document.createElement('div');
    resultsContainer.id = 'search-results';
    resultsContainer.className = 'algolia-autocomplete aa-dropdown-menu';
    resultsContainer.style.display = 'none';
    input.parentNode.appendChild(resultsContainer);
    
    var timeoutId;
    input.addEventListener('input', function(e) {
      clearTimeout(timeoutId);
      var query = e.target.value;
      
      if (query.length < 2) {
        resultsContainer.style.display = 'none';
        return;
      }
      
      timeoutId = setTimeout(function() {
        searchClient.search([{
          indexName: 'reactivemongo',
          query: query,
          params: {
            hitsPerPage: 5,
            facetFilters: ['major_version:' + av]
          }
        }]).then(function(results) {
          var hits = results.results[0].hits;
          if (hits.length === 0) {
            resultsContainer.style.display = 'none';
            return;
          }
          
          resultsContainer.innerHTML = hits.map(function(hit) {
            return '<div class="aa-suggestion" data-url="' + hit.url + '" data-sel="' + (hit.css_selector_parent || '') + '">' +
              hit._highlightResult.title.value +
              '</div>';
          }).join('');
          resultsContainer.style.display = 'block';
        }).catch(function(err) {
          console.error('Algolia search error:', err);
        });
      }, 300);
    });
    
    resultsContainer.addEventListener('click', function(e) {
      var suggestion = e.target.closest('.aa-suggestion');
      if (suggestion) {
        var url = suggestion.getAttribute('data-url');
        var sel = suggestion.getAttribute('data-sel');
        window.location.href = sel ? (url + sel) : url;
      }
    });
    
    document.addEventListener('click', function(e) {
      if (!input.contains(e.target) && !resultsContainer.contains(e.target)) {
        resultsContainer.style.display = 'none';
      }
    });
  })();
</script>
