function init_facetlize() {
  $.getJSON("./view/decorated/all", function(data) {
    var item_template =
      '<% var datatypes = ["bisulfite_seq","dnase_hypersensitivity","rna_seq","chip_seq_input","h3k4me3","h3k4me1","h3k9me3","h3k27ac","h3k27me3","h3k36me3"] %>' +
      '<tr class="item">' +
      '<td class="accession"><%= obj.full_accession %></td>' +
      '<td><%= obj.project %></td>' +
      '<td><%= obj.md_species %></td>' +
      '<td><%= obj.auto_desc %> </td>' +
      '<td><%= obj.type %></td>' +
      '<% _.each(datatypes, function(dt) { %> <td class="assays"><% if (obj.urls[dt]) { %>' + 
      '<a href="<%= obj.urls[dt] %>">&#x25cf;</a>' +
      ' <% } %></td> <% }); %>' +
    '</tr>';
    settings = {
      items: data,
      facets: {
        'project': 'Project',
        'status': 'Status',
        'md_species': 'Species',
        'md_disease': 'Disease',
        'md_donor_health_status': 'Health Status',
        'md_tissue_type': 'Tissue',
        'md_cell_type': 'Cell Type',
      },
      resultSelector: '#results',
      facetSelector: '#facets',
      resultTemplate: item_template,
      paginationCount: 50,
      orderByOptions: {
        'accession': 'Accession',
        'project': 'Project',
        'species': 'Species',
        'auto_desc': 'Description'
      }
    };

    // use them!
    $.facetelize(settings);
  });
}

$(document).ready(init_facetlize);
