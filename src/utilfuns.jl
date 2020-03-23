import Weave
using DataFrames
using JSON
using RCall
import PlotlyJS

function jhtml(source::String)
    Weave.weave(source,doctype="pandoc",cache=:user)
    ofile = split(basename(source),".")[1] * ".md"
    htmlfile = split(basename(source),".")[1] * ".html"
    pdir = dirname(@__FILE__)
    vtemplate = joinpath(pdir, "../templates/vuetify.html")
    vcss = read(joinpath(pdir, "../templates/vuetify.css"),String)
    prismjs = read(joinpath(pdir, "../templates/prism.js"),String)
    pandoc_result = run(`pandoc -f markdown -t html $ofile -o $htmlfile --katex --section-divs --template $vtemplate --toc --css $vcss --no-highlight -V prismjs=$prismjs` );
    return nothing;
end


function htmltable(df;title="",cnames = names(df))
  function df2json(df::DataFrame)
    [Dict([string(index) => (df[!, index][i]) for index in names(df)]) for i = 1:nrow(df)] |> JSON.json
  end
  trows = df2json(df)
  thead = JSON.json([Dict("value"=>names(df)[i],"text"=>cnames[i]) for i in 1:length(names(df))] )
  temp_string = ""
  for i in names(df)
    temp_string *= """<template v-slot:item.$i="{ item }"><span v-html="item.$i"></span></template>
    """
  end
  return """
  ```{=html}
  <vue-data-table>
  <template slot="title"><span style="color:#4e6b95; font-weight:normal">$title</span></template>
  <template slot-scope="{search, cfilter}">
  <v-data-table dense
      :headers=\'$thead\'
      :items=\'$trows\'
      :search = "search"
      :custom-filter = "cfilter"
      multi-sort
      class="elevation-1"
    >
    $temp_string
    </v-data-table>
  </template>
  </vue-data-table>
  ```"""
end
function jggplot(rplot,df,fname::String;type::String = "markdown", width = 8, height =5)
    jggplot(rplot,df; width = width, height = height)
    R"""
    if (!dir.exists("figures")) {dir.create("figures")}
    ggsave(filename = paste0("figures/",$fname), width = $width, height = $height,type = "cairo", dpi = 300)
    """
    if type == "markdown"
      return "![](figures/$fname)"
    else
      return "<img src=figures/$fname>"
    end
end

function jggplot(rplot,df;width = 8, height =5)
  @rput(df)
  R"library(hrbrthemes)"
  R"library(ggplot2)"
  p = reval(rplot)
end


function plotlygraph(a,pid)
  pdata = json(a.plot)
  println("""```{=html}
    <plotly-vue pid=$pid pdata = '$pdata'></plotly-vue>
  ```""")
end
