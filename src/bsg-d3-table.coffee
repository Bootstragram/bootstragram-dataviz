import D3Common from './bsg-d3-common'

# This class represent a sortable table.
class Table extends D3Common

  constructor: (@csvURL, opts) ->
    super(opts)

    @verbose = true

    @columns = opts.columns
    @sortable = opts.sortable ? true
    @classFunc = opts.classFunc ? null
    @dataTablesDefaultOrder = opts.dataTablesDefaultOrder ? null

    this

  draw: (callback = null) ->
    self = this

    d3.csv(@csvURL).then (dataset) ->
      tableId = self.parentId + "__table"
      table = $('<table></table>').addClass("bsg-d3__table table")
      table.attr('id', tableId)

      tableHead = $('<tr></tr>')
      for column in self.columns
        label = self._localizedString(column.label, lang) or column # Column is an object or a string
        tableHead.append("<th>" + label + "</th>")
      table.append($('<thead></thead>').append(tableHead))

      tableBody = $('<tbody></tbody>')
      for dataItem in dataset
        if self.classFunc?
          tableRow = $("<tr class=\"" + self.classFunc(dataItem) + "\"></tr>")
        else
          tableRow = $("<tr></tr>")
        for column in self.columns
          value = (column.value? && column.value(dataItem)) or dataItem[column] # Column is an object or a string
          dataSort = (column.dataSort? && column.dataSort(dataItem)) or null
          if dataSort?
            tableRow.append("<td data-sort=\"" + dataSort + "\">" + value + "</td>")
          else
            tableRow.append("<td>" + value + "</td>")
        tableBody.append(tableRow)
      table.append(tableBody)
      $(self.parentSel).append(table)

      if self.sortable
        dataTableOpts =
          paging: false
          searching: false
          bInfo: false

        dataTableOpts.order = self.dataTablesDefaultOrder if self.dataTablesDefaultOrder?

        $("#" + tableId).DataTable(dataTableOpts)
    .catch (error) ->
      console.log error

    this

export default Table
