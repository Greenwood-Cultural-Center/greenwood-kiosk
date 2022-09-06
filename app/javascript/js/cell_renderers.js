window.GridDataSource = {
  getRows: (options) => {
    const params = {
      from: options.startRow,
      to: options.endRow,
      sort: options.sortModel
    }
    $.getJSON(document.location.toString(), params, (json) => {
      const lastRow = json.length < 100 ? options.startRow + json.length : null
      options.successCallback(json, lastRow)
    })
  }
}

const ActionCellRenderer = function() {}

// gets called once before the renderer is used
ActionCellRenderer.prototype.init = function(params) {
  // create the cell
  this.eGui = document.createElement('div')
  if (params.value) {
    const link = document.location.toString().split('?')[0] + '/' + params.value
    this.eGui.innerHTML = '<a href="' + link + '">View</a>'
  }
}

// gets called once when grid ready to insert the element
ActionCellRenderer.prototype.getGui = function() {
  return this.eGui
}

// gets called whenever the user gets the cell to refresh
ActionCellRenderer.prototype.refresh = function(params) {
  // set value into cell again
  // this.eValue.innerHTML = params.valueFormatted ? params.valueFormatted : params.value;
  // return true to tell the grid we refreshed successfully
  return true
}

const CensusLinkCellRenderer = function() {}

// gets called once before the renderer is used
CensusLinkCellRenderer.prototype.init = function(params) {
  // create the cell
  const value = params.value || params.getValue()
  this.eGui = document.createElement('div')
  if (value && value.id) {
    const link = `/census/${value.year}/${value.id}`
    this.eGui.innerHTML = '<a href="' + link + '" target="_blank">View</a>'
  }
}

// gets called once when grid ready to insert the element
CensusLinkCellRenderer.prototype.getGui = function() {
  return this.eGui
}

// gets called whenever the user gets the cell to refresh
CensusLinkCellRenderer.prototype.refresh = function(params) {
  // set value into cell again
  // this.eValue.innerHTML = params.valueFormatted ? params.valueFormatted : params.value;
  // return true to tell the grid we refreshed successfully
  return true
}

// gets called when the cell is removed from the grid
CensusLinkCellRenderer.prototype.destroy = function() {}

const NameCellRenderer = function() {}

// gets called once before the renderer is used
NameCellRenderer.prototype.init = function(params) {
  // create the cell
  const value = params.value || params.getValue()
  this.eGui = document.createElement('div')
  if (value && value.name) {
    this.eGui.innerHTML = value.name
    if (!value.reviewed) {
      this.eGui.innerHTML += '<span class="badge badge-success">NEW</span>'
    }
  } else {
    this.eGui.innerHTML = 'Loading more records.'
  }
}

// gets called once when grid ready to insert the element
NameCellRenderer.prototype.getGui = function() {
  return this.eGui
}

// gets called whenever the user gets the cell to refresh
NameCellRenderer.prototype.refresh = function(params) {
  // set value into cell again
  // this.eValue.innerHTML = params.valueFormatted ? params.valueFormatted : params.value;
  // return true to tell the grid we refreshed successfully
  return true
}

// gets called when the cell is removed from the grid
NameCellRenderer.prototype.destroy = function() {}

const HTMLCellRenderer = function() {}

// gets called once before the renderer is used
HTMLCellRenderer.prototype.init = function(params) {
  const value = params.value || params.getValue()
  this.eGui = document.createElement('div')
  if (value) {
    this.eGui.innerHTML = value
  }
}

// gets called once when grid ready to insert the element
HTMLCellRenderer.prototype.getGui = function() {
  return this.eGui
}

// gets called whenever the user gets the cell to refresh
HTMLCellRenderer.prototype.refresh = function(params) {
  // set value into cell again
  // this.eValue.innerHTML = params.valueFormatted ? params.valueFormatted : params.value;
  // return true to tell the grid we refreshed successfully
  return true
}

// gets called when the cell is removed from the grid
HTMLCellRenderer.prototype.destroy = function() {}

window.ActionCellRenderer = ActionCellRenderer
window.NameCellRenderer = NameCellRenderer
window.CensusLinkCellRenderer = CensusLinkCellRenderer
window.HTMLCellRenderer = HTMLCellRenderer
