function gen_table(div_id, csv_url) { Papa.parse(csv_url, {
  download: true,
  // results.data is a two dimensional array
  complete: function(results) {
    data = results.data.slice(0,-1) // last line is empty, remove
    data = data.map(row => row.slice(0,-1)) // last element of each is empty, remove
    indexcol = data[0].map(function(ele) {
      m = ele.match(/[0-9]+\.[^\.]+/)
      return m ? m[0] : ""
    })
    indexcol[0]="Date"; indexcol[1]="Commit"; indexcol[2]="Note"; indexcol[3]="result/";
    data = [indexcol].concat(data)

    headerValues = data.map(row => row[0])
    cellsValues = data.map(row => row.slice(1))
    cellsValues = cellsValues.map(row => row.map(ele => ele.replace("/nix/store/", "")))

    // https://www.geeksforgeeks.org/how-to-create-hash-from-string-in-javascript/
    function hash(str) {
      return str.split('').reduce((hash, char) =>
        {return char.charCodeAt(0) + (hash << 6) + (hash << 16) - hash;}, 0)
          - 1;} // make the empty string color white (return -1 (255))
    function color(i) { return `rgb(${i&0xff},${(i>>8)&0xff},${(i>>16)&0xff})` }
    cellsColors = cellsValues.map(row => row.map(ele => color(hash(ele))))
    cellsColors[0] = Array(cellsColors.length).fill("white")
    function fontcolor(i) {
      // luminance algorithm is provided claude.ai
      luminance = (0.299*(i&0xff) + 0.587*((i>>8)&0xff) + 0.114*((i>>16)&0xff)) / 0xff
      return luminance>0.5 ? "black" : "white"
    }
    cellsFontColors = cellsValues.map(row => row.map(ele => fontcolor(hash(ele))))
    cellsFontColors[0] = Array(cellsFontColors.length).fill("black")

    plotDiv = document.getElementById(div_id);
    rowHeight = 20
    plotDiv.style.width = `${100 * headerValues.length}px`
    plotDiv.style.height = `${rowHeight * data[0].length}px`
    // https://plotly.com/javascript/reference/table/
    Plotly.newPlot(plotDiv, /*data*/[{
      type: "table",
      header: {
        values: headerValues,
        align: "left",
        font: {family: "mono"},
        height: rowHeight,
      },
      cells: {
        values: cellsValues,
        align: "left",
        font: {family: "mono", color: cellsFontColors},
        fill: {color: cellsColors},
        height: rowHeight,
      },
    }], /*layout*/ {
      margin: {b:0, l:0, r:0, t:0},
    })
  }
})}
