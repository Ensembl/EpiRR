function init_facetlize() {
  $.getJSON("http://localhost:3000/view/decorated/all", function(data) {
    var item_template =
      '<% var datatypes = ["dna_methylation","mrna_seq","chip_seq_input","h3k4me3","h3k4me1","h3k9me3","h3k27ac","h3k27me3","h3k36me3"] %>' +
      '<tr class="item">' +
      '<td class="accession"><%= obj.accession %></td>' +
      '<td><%= obj.project %></td>' +
      '<td><%= obj.md_species %></td>' +
      '<td><%= obj.auto_desc %> </td>' +
      '<td><%= obj.type %></td>' +
      '<% _.each(datatypes, function(dt) { %> <td class="assays"><% if (obj.urls[dt]) { %>' + 
      '<a href="<%= obj.urls[dt] %>">x</a>' +
      ' <% } %></td> <% }); %>' +

    '</tr>';
    settings = {
      items: data,
      facets: {
        'project': 'Project',
        'status': 'Status',
        'md_disease': 'Disease',
        'md_tissue_type': 'Tissue',
        'md_cell_type': 'Cell Type',
      },
      resultSelector: '#results',
      facetSelector: '#facets',
      resultTemplate: item_template,
      paginationCount: 50,
      orderByOptions: {
        'project': 'Project',
        'status': 'Status',
        'accession': 'Accession'
      }
    };

    // use them!
    $.facetelize(settings);
  });
}

$(document).ready(init_facetlize);